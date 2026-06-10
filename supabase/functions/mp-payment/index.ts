import { Buffer } from "node:buffer";
import * as https from "node:https";
import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2";

const PRICE_PER_MONTH = 29.90;
const MAX_MONTHS = 12;
const EFI_PIX_BASE_URL = "https://pix.api.efipay.com.br";
const DEFAULT_PROFILES_TABLE = "users_profiles";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-webhook-secret",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};

type JsonMap = Record<string, unknown>;

type HttpResult = {
  status: number;
  text: string;
};

type PixEnv = {
  clientId: string;
  clientSecret: string;
  certBase64: string;
  certPassphrase?: string;
  pixKey: string;
};

class RequestError extends Error {
  constructor(
    public status: number,
    message: string,
  ) {
    super(message);
  }
}

let supabaseAdmin: SupabaseClient | null = null;

function env(name: string) {
  return Deno.env.get(name);
}

function jsonResponse(payload: JsonMap, status = 200) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

function getSupabaseAdmin() {
  if (supabaseAdmin) return supabaseAdmin;

  const url = env("SUPABASE_URL");
  const serviceRoleKey = env("SUPABASE_SERVICE_ROLE_KEY");

  if (!url || !serviceRoleKey) {
    throw new RequestError(
      500,
      "SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY precisam estar configurados.",
    );
  }

  supabaseAdmin = createClient(url, serviceRoleKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });

  return supabaseAdmin;
}

async function getAuthenticatedUser(req: Request) {
  const authHeader = req.headers.get("authorization");
  const match = authHeader?.match(/^Bearer\s+(.+)$/i);

  if (!match) {
    throw new RequestError(401, "Sessao obrigatoria para criar cobranca.");
  }

  const { data, error } = await getSupabaseAdmin().auth.getUser(match[1]);

  if (error || !data.user) {
    throw new RequestError(401, "Sessao invalida ou expirada.");
  }

  return data.user;
}

function requirePixEnv(): PixEnv {
  const config = {
    clientId: env("EFI_CLIENT_ID"),
    clientSecret: env("EFI_CLIENT_SECRET"),
    certBase64: env("EFI_CERT_BASE64"),
    certPassphrase: env("EFI_CERT_PASSPHRASE"),
    pixKey: env("EFI_PIX_KEY"),
  };

  const missing = Object.entries(config)
    .filter(([key, value]) => key !== "certPassphrase" && !value)
    .map(([key]) => key);

  if (missing.length > 0) {
    throw new RequestError(500, `Variaveis EFI ausentes: ${missing.join(", ")}`);
  }

  return config as PixEnv;
}

function createTlsAgent(certBase64: string, certPassphrase?: string) {
  return new https.Agent({
    pfx: Buffer.from(certBase64, "base64"),
    passphrase: certPassphrase || undefined,
    rejectUnauthorized: true,
  });
}

function httpsRequest(
  url: string,
  options: { method?: string; headers?: Record<string, string> },
  body: string | null,
  agent: https.Agent,
): Promise<HttpResult> {
  return new Promise((resolve, reject) => {
    const parsed = new URL(url);
    const request = https.request(
      {
        hostname: parsed.hostname,
        path: `${parsed.pathname}${parsed.search}`,
        port: parsed.port || 443,
        method: options.method ?? "GET",
        headers: options.headers ?? {},
        agent,
      },
      response => {
        let text = "";
        response.setEncoding("utf8");
        response.on("data", chunk => {
          text += chunk;
        });
        response.on("end", () => {
          resolve({ status: response.statusCode ?? 0, text });
        });
      },
    );

    request.setTimeout(30000, () => {
      request.destroy(new Error("Tempo limite excedido ao chamar a API Pix EFI."));
    });

    request.on("error", reject);
    if (body) request.write(body);
    request.end();
  });
}

function parseJson(text: string) {
  try {
    return JSON.parse(text) as JsonMap;
  } catch {
    return {};
  }
}

async function readJsonBody(req: Request) {
  const text = await req.text();
  if (!text.trim()) return {};

  try {
    return JSON.parse(text) as JsonMap;
  } catch {
    throw new RequestError(400, "JSON invalido.");
  }
}

async function getPixToken(config: PixEnv, agent: https.Agent) {
  const credentials = Buffer
    .from(`${config.clientId}:${config.clientSecret}`)
    .toString("base64");

  const result = await httpsRequest(
    `${EFI_PIX_BASE_URL}/oauth/token`,
    {
      method: "POST",
      headers: {
        Authorization: `Basic ${credentials}`,
        "Content-Type": "application/json",
      },
    },
    JSON.stringify({ grant_type: "client_credentials" }),
    agent,
  );

  if (result.status !== 200) {
    throw new RequestError(
      502,
      `EFI Pix auth falhou (${result.status}): ${result.text.slice(0, 300)}`,
    );
  }

  const data = parseJson(result.text);
  const accessToken = data.access_token;

  if (typeof accessToken !== "string") {
    throw new RequestError(502, "EFI Pix nao retornou access_token.");
  }

  return accessToken;
}

function requireString(body: JsonMap, key: string) {
  const value = body[key];
  return typeof value === "string" ? value.trim() : "";
}

function normalizeCpf(value: string) {
  return value.replace(/\D/g, "");
}

function parseMonths(value: unknown) {
  const months = Number.parseInt(String(value), 10);
  if (!Number.isFinite(months) || months < 1 || months > MAX_MONTHS) return null;
  return months;
}

async function createCharge(req: Request, body: JsonMap) {
  const authUser = await getAuthenticatedUser(req);
  const userId = requireString(body, "userId");
  const months = parseMonths(body.months);
  const customerName = requireString(body, "customerName");
  const customerCpf = normalizeCpf(requireString(body, "customerCpf"));

  if (!userId || userId !== authUser.id) {
    throw new RequestError(403, "Usuario nao autorizado para esta cobranca.");
  }

  if (!months) {
    throw new RequestError(400, "Quantidade de meses invalida.");
  }

  if (!customerName || customerCpf.length !== 11) {
    throw new RequestError(400, "Nome completo e CPF valido sao obrigatorios.");
  }

  const pixEnv = requirePixEnv();
  const agent = createTlsAgent(pixEnv.certBase64, pixEnv.certPassphrase);
  const token = await getPixToken(pixEnv, agent);
  const totalValue = (PRICE_PER_MONTH * months).toFixed(2);
  const label = months === 1
    ? "Bloquinho Digital - Plano Pro 1 mes"
    : `Bloquinho Digital - Plano Pro ${months} meses`;

  const cobPayload = {
    calendario: { expiracao: 1800 },
    devedor: {
      cpf: customerCpf,
      nome: customerName,
    },
    valor: { original: totalValue },
    chave: pixEnv.pixKey,
    solicitacaoPagador: label,
    infoAdicionais: [
      { nome: "userId", valor: userId },
      { nome: "meses", valor: String(months) },
    ],
  };

  const cobResult = await httpsRequest(
    `${EFI_PIX_BASE_URL}/v2/cob`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
    },
    JSON.stringify(cobPayload),
    agent,
  );

  const cobData = parseJson(cobResult.text);

  if (cobResult.status !== 201) {
    console.error("Pix cob error", cobData);
    throw new RequestError(502, "Erro ao criar cobranca Pix.");
  }

  const loc = cobData.loc as JsonMap | undefined;
  const locId = loc?.id;
  let qrData: JsonMap = {};

  if (typeof locId === "number" || typeof locId === "string") {
    const qrResult = await httpsRequest(
      `${EFI_PIX_BASE_URL}/v2/loc/${locId}/qrcode`,
      {
        method: "GET",
        headers: { Authorization: `Bearer ${token}` },
      },
      null,
      agent,
    );

    qrData = parseJson(qrResult.text);
  }

  const txid = cobData.txid;
  const pixCopiaECola = typeof qrData.qrcode === "string"
    ? qrData.qrcode
    : cobData.pixCopiaECola;

  if (typeof txid !== "string" || typeof pixCopiaECola !== "string") {
    throw new RequestError(502, "EFI Pix nao retornou os dados da cobranca.");
  }

  return jsonResponse({
    txid,
    pixCopiaECola,
    qrCodeImage: typeof qrData.imagemQrcode === "string" ? qrData.imagemQrcode : null,
    expiresIn: 1800,
  });
}

function ensureWebhookSecret(req: Request, url: URL) {
  const expected = env("PAYMENT_WEBHOOK_SECRET");
  if (!expected) return;

  const provided = req.headers.get("x-webhook-secret")
    ?? url.searchParams.get("secret")
    ?? url.searchParams.get("token");

  if (provided !== expected) {
    throw new RequestError(401, "Webhook nao autorizado.");
  }
}

function addMonths(date: Date, months: number) {
  const next = new Date(date);
  next.setMonth(next.getMonth() + months);
  return next;
}

function findInfo(infos: unknown, key: string) {
  if (!Array.isArray(infos)) return "";

  const item = infos.find(info => {
    if (!info || typeof info !== "object") return false;
    return (info as JsonMap).nome === key;
  });

  return item && typeof item === "object" && typeof (item as JsonMap).valor === "string"
    ? String((item as JsonMap).valor)
    : "";
}

async function activatePlanFromPix(req: Request, url: URL, body: JsonMap) {
  ensureWebhookSecret(req, url);

  const pixList = Array.isArray(body.pix) ? body.pix : [];
  if (pixList.length === 0) {
    return jsonResponse({ ok: true });
  }

  const pixEnv = requirePixEnv();
  const agent = createTlsAgent(pixEnv.certBase64, pixEnv.certPassphrase);
  const token = await getPixToken(pixEnv, agent);
  const supabase = getSupabaseAdmin();
  const profilesTable = env("SUPABASE_PROFILES_TABLE") ?? DEFAULT_PROFILES_TABLE;

  for (const pix of pixList) {
    if (!pix || typeof pix !== "object") continue;
    const txid = (pix as JsonMap).txid;
    if (typeof txid !== "string" || !txid) continue;

    const cobResult = await httpsRequest(
      `${EFI_PIX_BASE_URL}/v2/cob/${encodeURIComponent(txid)}`,
      {
        method: "GET",
        headers: { Authorization: `Bearer ${token}` },
      },
      null,
      agent,
    );

    const cobData = parseJson(cobResult.text);
    if (cobData.status !== "CONCLUIDA") continue;

    const userId = findInfo(cobData.infoAdicionais, "userId");
    const months = parseMonths(findInfo(cobData.infoAdicionais, "meses"));

    if (!userId || !months) {
      console.error(`Webhook Pix com userId/meses invalidos txid=${txid}`);
      continue;
    }

    const expiresAt = addMonths(new Date(), months);
    const { data: profiles, error: selectError } = await supabase
      .from(profilesTable)
      .select("id")
      .eq("userId", userId)
      .limit(1);

    if (selectError) throw selectError;
    if (!profiles || profiles.length === 0) {
      console.error(`Perfil nao encontrado para userId=${userId}`);
      continue;
    }

    const { error: updateError } = await supabase
      .from(profilesTable)
      .update({
        planStatus: "pro",
        planExpiresAt: expiresAt.toISOString(),
        updatedAt: new Date().toISOString(),
      })
      .eq("id", profiles[0].id);

    if (updateError) throw updateError;
    console.info(`Plano PRO ativado via Pix: userId=${userId} meses=${months}`);
  }

  return jsonResponse({ ok: true });
}

async function checkPlan(req: Request, url: URL) {
  const authUser = await getAuthenticatedUser(req);
  const userId = url.searchParams.get("userId") ?? "";

  if (!userId) {
    throw new RequestError(400, "userId obrigatorio.");
  }

  if (authUser.id !== userId) {
    throw new RequestError(403, "Usuario nao autorizado para este plano.");
  }

  const supabase = getSupabaseAdmin();
  const profilesTable = env("SUPABASE_PROFILES_TABLE") ?? DEFAULT_PROFILES_TABLE;
  const { data: profiles, error: selectError } = await supabase
    .from(profilesTable)
    .select("id, planStatus, planExpiresAt")
    .eq("userId", userId)
    .limit(1);

  if (selectError) throw selectError;
  if (!profiles || profiles.length === 0) {
    return jsonResponse({ planStatus: "free", planExpiresAt: null });
  }

  const profile = profiles[0] as JsonMap;
  const now = new Date();
  const planExpiresAt = profile.planExpiresAt;
  const expiresAt = typeof planExpiresAt === "string" ? new Date(planExpiresAt) : null;

  if (profile.planStatus === "pro" && expiresAt && expiresAt < now) {
    const { error: updateError } = await supabase
      .from(profilesTable)
      .update({
        planStatus: "free",
        updatedAt: now.toISOString(),
      })
      .eq("id", profile.id);

    if (updateError) throw updateError;
    return jsonResponse({ planStatus: "free", planExpiresAt: null });
  }

  return jsonResponse({
    planStatus: typeof profile.planStatus === "string" ? profile.planStatus : "free",
    planExpiresAt: typeof planExpiresAt === "string" ? planExpiresAt : null,
  });
}

Deno.serve(async req => {
  const url = new URL(req.url);

  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  try {
    if (req.method === "GET" && url.searchParams.get("action") === "check-plan") {
      return await checkPlan(req, url);
    }

    if (req.method !== "POST") {
      throw new RequestError(405, "Metodo nao permitido.");
    }

    const body = await readJsonBody(req);
    const action = requireString(body, "action") || (Array.isArray(body.pix) ? "webhook" : "");

    if (action === "create-charge") {
      return await createCharge(req, body);
    }

    if (action === "webhook") {
      return await activatePlanFromPix(req, url, body);
    }

    throw new RequestError(404, "Rota nao encontrada.");
  } catch (error) {
    console.error("mp-payment error", error);

    if (error instanceof RequestError) {
      return jsonResponse({ error: error.message }, error.status);
    }

    return jsonResponse({
      error: error instanceof Error ? error.message : "Erro interno.",
    }, 500);
  }
});
