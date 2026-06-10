import type {
  Customer,
  InventoryItem,
  Receivable,
  Sale,
  UserProfile,
} from "./types";

type DBProvider = "supabase";

const DB_PROVIDER = (import.meta.env.VITE_DB_PROVIDER || "supabase") as DBProvider;

export interface IAuthService {
  signIn(email: string, password: string): Promise<{ userId: string }>;
  signUp(email: string, password: string): Promise<{ userId: string }>;
  signOut(): Promise<void>;
  resetPassword(email: string): Promise<void>;
  getCurrentUser(): Promise<{ userId: string; email: string } | null>;
  onAuthStateChanged(callback: (user: { userId: string; email: string } | null) => void): () => void;
}

export interface IDBService {
  getCustomers(userId: string): Promise<Customer[]>;
  getCustomer(userId: string, customerId: string): Promise<Customer | null>;
  createCustomer(userId: string, data: Omit<Customer, "id" | "createdAt" | "updatedAt">): Promise<string>;
  updateCustomer(userId: string, customerId: string, data: Partial<Customer>): Promise<void>;
  deleteCustomer(userId: string, customerId: string): Promise<void>;

  getInventoryItems(userId: string): Promise<InventoryItem[]>;
  getInventoryItem(userId: string, itemId: string): Promise<InventoryItem | null>;
  createInventoryItem(userId: string, data: Omit<InventoryItem, "id" | "createdAt" | "updatedAt">): Promise<string>;
  updateInventoryItem(userId: string, itemId: string, data: Partial<InventoryItem>): Promise<void>;
  deleteInventoryItem(userId: string, itemId: string): Promise<void>;

  getSales(userId: string, filters?: { startDate?: Date; endDate?: Date }): Promise<Sale[]>;
  getSale(userId: string, saleId: string): Promise<Sale | null>;
  createSale(userId: string, data: Omit<Sale, "id" | "createdAt" | "updatedAt">): Promise<string>;

  getReceivables(userId: string, filters?: { status?: string; customerId?: string }): Promise<Receivable[]>;
  getReceivable(userId: string, receivableId: string): Promise<Receivable | null>;
  createReceivable(userId: string, data: Omit<Receivable, "id" | "createdAt" | "updatedAt">): Promise<string>;
  updateReceivable(userId: string, receivableId: string, data: Partial<Receivable>): Promise<void>;

  getUserProfile(userId: string): Promise<UserProfile | null>;
  createUserProfile(userId: string, data: Partial<UserProfile>): Promise<void>;
  updateUserProfile(userId: string, data: Partial<UserProfile>): Promise<void>;
}

export async function getAuthService(): Promise<IAuthService> {
  const { SupabaseAuthService } = await import("./adapters/supabase-auth");
  return new SupabaseAuthService();
}

export async function getDBService(): Promise<IDBService> {
  const { SupabaseDBService } = await import("./adapters/supabase-db");
  return new SupabaseDBService();
}

let authServiceInstance: IAuthService | null = null;
let dbServiceInstance: IDBService | null = null;

export async function auth(): Promise<IAuthService> {
  if (!authServiceInstance) {
    authServiceInstance = await getAuthService();
  }
  return authServiceInstance;
}

export async function db(): Promise<IDBService> {
  if (!dbServiceInstance) {
    dbServiceInstance = await getDBService();
  }
  return dbServiceInstance;
}

export function getActiveProvider(): DBProvider {
  return DB_PROVIDER;
}
