/**
 * Supabase client and small compatibility layer for the legacy database calls.
 */

import { createClient } from "@supabase/supabase-js";

const env = import.meta.env as Record<string, string | undefined>;

const SUPABASE_URL = env.VITE_SUPABASE_URL;
const SUPABASE_KEY = env.VITE_SUPABASE_PUBLISHABLE_KEY ?? env.VITE_SUPABASE_ANON_KEY;

if (!SUPABASE_URL || !SUPABASE_KEY) {
  throw new Error("Configure VITE_SUPABASE_URL e VITE_SUPABASE_PUBLISHABLE_KEY no ambiente.");
}

export const supabase = createClient(SUPABASE_URL, SUPABASE_KEY, {
  auth: {
    autoRefreshToken: true,
    detectSessionInUrl: true,
    persistSession: true,
  },
});

export const DATABASE_ID = "supabase";

export const COLLECTIONS = {
  PROFILES: env.VITE_SUPABASE_TABLE_PROFILES ?? "users_profiles",
  CUSTOMERS: env.VITE_SUPABASE_TABLE_CUSTOMERS ?? "customers",
  INVENTORY: env.VITE_SUPABASE_TABLE_INVENTORY ?? "inventory_items",
  SALES: env.VITE_SUPABASE_TABLE_SALES ?? "sales",
  RECEIVABLES: env.VITE_SUPABASE_TABLE_RECEIVABLES ?? "receivables",
  MOVEMENTS: env.VITE_SUPABASE_TABLE_MOVEMENTS ?? "inventory_movements",
} as const;

type QueryOperation =
  | "eq"
  | "gt"
  | "gte"
  | "lte"
  | "order"
  | "limit"
  | "offset";

type QueryClause = {
  operation: QueryOperation;
  field?: string;
  value?: unknown;
  ascending?: boolean;
};

const toColumn = (field: string) => field === "$id" ? "id" : field;

export const Query = {
  equal: (field: string, value: unknown): QueryClause => ({ operation: "eq", field, value }),
  greaterThan: (field: string, value: unknown): QueryClause => ({ operation: "gt", field, value }),
  greaterThanEqual: (field: string, value: unknown): QueryClause => ({ operation: "gte", field, value }),
  lessThanEqual: (field: string, value: unknown): QueryClause => ({ operation: "lte", field, value }),
  orderAsc: (field: string): QueryClause => ({ operation: "order", field, ascending: true }),
  orderDesc: (field: string): QueryClause => ({ operation: "order", field, ascending: false }),
  limit: (value: number): QueryClause => ({ operation: "limit", value }),
  offset: (value: number): QueryClause => ({ operation: "offset", value }),
};

export const ID = {
  unique: () => crypto.randomUUID(),
};

export const Role = {
  user: (userId: string) => `user:${userId}`,
};

export const Permission = {
  read: (role: string) => `read:${role}`,
  update: (role: string) => `update:${role}`,
  delete: (role: string) => `delete:${role}`,
};

export const OAuthProvider = {
  Google: "google",
} as const;

type SupabaseUserView = {
  $id: string;
  email: string;
  name?: string;
  emailVerification: boolean;
};

function toUserView(user: {
  id: string;
  email?: string;
  email_confirmed_at?: string | null;
  confirmed_at?: string | null;
  user_metadata?: Record<string, unknown>;
}): SupabaseUserView {
  const name = typeof user.user_metadata?.name === "string"
    ? user.user_metadata.name
    : undefined;

  return {
    $id: user.id,
    email: user.email ?? "",
    name,
    emailVerification: Boolean(user.email_confirmed_at ?? user.confirmed_at),
  };
}

function toDocument<T extends Record<string, unknown>>(row: T): T & { $id: string } {
  return {
    ...row,
    $id: String(row.id),
  };
}

function cleanPayload(data: Record<string, unknown>) {
  return Object.fromEntries(
    Object.entries(data).filter(([, value]) => value !== undefined)
  );
}

function normalizeError(error: { message?: string; code?: string; status?: number }) {
  const err = new Error(error.message || "Erro ao acessar o Supabase") as Error & {
    code?: number | string;
    status?: number;
  };
  err.code = error.code === "PGRST116" ? 404 : error.code;
  err.status = error.status;
  return err;
}

export const account = {
  async create(_userId: string, email: string, password: string, name?: string) {
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: { data: name ? { name } : undefined },
    });

    if (error) throw normalizeError(error);
    if (!data.user) throw new Error("Nao foi possivel criar a conta.");
    return toUserView(data.user);
  },

  async createEmailPasswordSession(email: string, password: string) {
    const { data, error } = await supabase.auth.signInWithPassword({ email, password });
    if (error) throw normalizeError(error);
    if (!data.user) throw new Error("Nao foi possivel iniciar sessao.");
    return { userId: data.user.id };
  },

  async createOAuth2Session(
    provider: (typeof OAuthProvider)[keyof typeof OAuthProvider],
    successUrl: string,
    _failureUrl?: string,
  ) {
    const { data, error } = await supabase.auth.signInWithOAuth({
      provider,
      options: { redirectTo: successUrl },
    });

    if (error) throw normalizeError(error);
    if (data.url) window.location.href = data.url;
  },

  async deleteSession(_sessionId: "current" | string = "current") {
    const { error } = await supabase.auth.signOut();
    if (error) throw normalizeError(error);
  },

  async get() {
    const { data, error } = await supabase.auth.getUser();
    if (error) throw normalizeError(error);
    if (!data.user) throw new Error("Sessao nao encontrada.");
    return toUserView(data.user);
  },

  async createRecovery(email: string, redirectUrl: string) {
    const { error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: redirectUrl,
    });
    if (error) throw normalizeError(error);
  },

  async createVerification(redirectUrl: string) {
    const { data } = await supabase.auth.getUser();
    const email = data.user?.email;
    if (!email) return;

    const { error } = await supabase.auth.resend({
      type: "signup",
      email,
      options: { emailRedirectTo: redirectUrl },
    });
    if (error) throw normalizeError(error);
  },

  async updatePassword(password: string, _oldPassword?: string) {
    const { error } = await supabase.auth.updateUser({ password });
    if (error) throw normalizeError(error);
  },

  onAuthStateChanged(callback: (user: SupabaseUserView | null) => void) {
    const { data } = supabase.auth.onAuthStateChange((_event, session) => {
      callback(session?.user ? toUserView(session.user) : null);
    });

    return () => data.subscription.unsubscribe();
  },
};

export const databases = {
  async listDocuments(
    _databaseId: string,
    tableName: string,
    queries: QueryClause[] = [],
  ): Promise<{ documents: any[]; total: number }> {
    let request = supabase.from(tableName).select("*", { count: "exact" });
    let limit: number | undefined;
    let offset = 0;

    for (const query of queries) {
      switch (query.operation) {
        case "eq": {
          const column = toColumn(query.field ?? "");
          if (Array.isArray(query.value)) {
            request = request.in(column, query.value);
          } else {
            request = request.eq(column, query.value);
          }
          break;
        }
        case "gt":
          request = request.gt(toColumn(query.field ?? ""), query.value);
          break;
        case "gte":
          request = request.gte(toColumn(query.field ?? ""), query.value);
          break;
        case "lte":
          request = request.lte(toColumn(query.field ?? ""), query.value);
          break;
        case "order":
          request = request.order(toColumn(query.field ?? ""), {
            ascending: query.ascending ?? true,
          });
          break;
        case "limit":
          limit = Number(query.value);
          break;
        case "offset":
          offset = Number(query.value);
          break;
      }
    }

    if (limit !== undefined) {
      request = request.range(offset, offset + limit - 1);
    }

    const { data, error, count } = await request;
    if (error) throw normalizeError(error);

    const rows = (data ?? []) as Record<string, unknown>[];
    return {
      documents: rows.map(toDocument),
      total: count ?? rows.length,
    };
  },

  async getDocument(_databaseId: string, tableName: string, documentId: string): Promise<any> {
    const { data, error } = await supabase
      .from(tableName)
      .select("*")
      .eq("id", documentId)
      .maybeSingle();

    if (error) throw normalizeError(error);
    if (!data) {
      const err = new Error("Documento nao encontrado") as Error & { code: number; status: number };
      err.code = 404;
      err.status = 404;
      throw err;
    }

    return toDocument(data as Record<string, unknown>);
  },

  async createDocument(
    _databaseId: string,
    tableName: string,
    documentId: string,
    data: Record<string, unknown>,
    _permissions?: string[],
  ): Promise<any> {
    const payload = cleanPayload({
      id: documentId,
      ...data,
    });

    const { data: row, error } = await supabase
      .from(tableName)
      .insert(payload)
      .select("*")
      .single();

    if (error) throw normalizeError(error);
    return toDocument(row as Record<string, unknown>);
  },

  async updateDocument(
    _databaseId: string,
    tableName: string,
    documentId: string,
    data: Record<string, unknown>,
  ): Promise<any> {
    const { data: row, error } = await supabase
      .from(tableName)
      .update(cleanPayload(data))
      .eq("id", documentId)
      .select("*")
      .single();

    if (error) throw normalizeError(error);
    return toDocument(row as Record<string, unknown>);
  },

  async deleteDocument(_databaseId: string, tableName: string, documentId: string) {
    const { error } = await supabase
      .from(tableName)
      .delete()
      .eq("id", documentId);

    if (error) throw normalizeError(error);
  },
};

export const userQuery = (userId: string) => Query.equal("userId", userId);

export const orderByCreatedAt = (_direction: "asc" | "desc" = "desc") =>
  Query.orderDesc("createdAt");

export const orderByUpdatedAt = (_direction: "asc" | "desc" = "desc") =>
  Query.orderDesc("updatedAt");

export async function withRetry<T>(fn: () => Promise<T>, maxAttempts = 3): Promise<T> {
  let lastError: unknown;
  for (let attempt = 0; attempt < maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (err: unknown) {
      lastError = err;
      const code = (err as any)?.code ?? (err as any)?.status;
      if (code !== 429) throw err;
      const delay = Math.pow(2, attempt) * 1000;
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }
  throw lastError;
}
