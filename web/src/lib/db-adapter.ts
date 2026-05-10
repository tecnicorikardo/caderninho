/**
 * Database Adapter
 * 
 * Camada de abstração que permite migração gradual de Firebase para Appwrite.
 * Use DB_PROVIDER='firebase' ou 'appwrite' no .env para alternar.
 */

import type { 
  Customer, 
  InventoryItem, 
  Sale, 
  Receivable, 
  UserProfile 
} from './types';

// Tipo do provider
type DBProvider = 'firebase' | 'appwrite';

const DB_PROVIDER = (import.meta.env.VITE_DB_PROVIDER || 'firebase') as DBProvider;

// ============================================================================
// INTERFACES
// ============================================================================

export interface IAuthService {
  signIn(email: string, password: string): Promise<{ userId: string }>;
  signUp(email: string, password: string): Promise<{ userId: string }>;
  signOut(): Promise<void>;
  resetPassword(email: string): Promise<void>;
  getCurrentUser(): Promise<{ userId: string; email: string } | null>;
  onAuthStateChanged(callback: (user: { userId: string; email: string } | null) => void): () => void;
}

export interface IDBService {
  // Customers
  getCustomers(userId: string): Promise<Customer[]>;
  getCustomer(userId: string, customerId: string): Promise<Customer | null>;
  createCustomer(userId: string, data: Omit<Customer, 'id' | 'createdAt' | 'updatedAt'>): Promise<string>;
  updateCustomer(userId: string, customerId: string, data: Partial<Customer>): Promise<void>;
  deleteCustomer(userId: string, customerId: string): Promise<void>;
  
  // Inventory
  getInventoryItems(userId: string): Promise<InventoryItem[]>;
  getInventoryItem(userId: string, itemId: string): Promise<InventoryItem | null>;
  createInventoryItem(userId: string, data: Omit<InventoryItem, 'id' | 'createdAt' | 'updatedAt'>): Promise<string>;
  updateInventoryItem(userId: string, itemId: string, data: Partial<InventoryItem>): Promise<void>;
  deleteInventoryItem(userId: string, itemId: string): Promise<void>;
  
  // Sales
  getSales(userId: string, filters?: { startDate?: Date; endDate?: Date }): Promise<Sale[]>;
  getSale(userId: string, saleId: string): Promise<Sale | null>;
  createSale(userId: string, data: Omit<Sale, 'id' | 'createdAt' | 'updatedAt'>): Promise<string>;
  
  // Receivables
  getReceivables(userId: string, filters?: { status?: string; customerId?: string }): Promise<Receivable[]>;
  getReceivable(userId: string, receivableId: string): Promise<Receivable | null>;
  createReceivable(userId: string, data: Omit<Receivable, 'id' | 'createdAt' | 'updatedAt'>): Promise<string>;
  updateReceivable(userId: string, receivableId: string, data: Partial<Receivable>): Promise<void>;
  
  // Profile
  getUserProfile(userId: string): Promise<UserProfile | null>;
  createUserProfile(userId: string, data: Partial<UserProfile>): Promise<void>;
  updateUserProfile(userId: string, data: Partial<UserProfile>): Promise<void>;
}

// ============================================================================
// FACTORY
// ============================================================================

export async function getAuthService(): Promise<IAuthService> {
  const { AppwriteAuthService } = await import('./adapters/appwrite-auth');
  return new AppwriteAuthService();
}

export async function getDBService(): Promise<IDBService> {
  const { AppwriteDBService } = await import('./adapters/appwrite-db');
  return new AppwriteDBService();
}

// ============================================================================
// SINGLETON INSTANCES (lazy loaded)
// ============================================================================

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

// Helper para saber qual provider está ativo
export function getActiveProvider(): DBProvider {
  return DB_PROVIDER;
}
