/**
 * Appwrite Configuration
 * 
 * Configuração do cliente Appwrite para autenticação e banco de dados.
 */

import { Client, Account, Databases, Query } from 'appwrite';

// Configuração do cliente
const client = new Client()
  .setEndpoint(import.meta.env.VITE_APPWRITE_ENDPOINT as string)
  .setProject(import.meta.env.VITE_APPWRITE_PROJECT_ID as string);

// Serviços
export const account = new Account(client);
export const databases = new Databases(client);

// IDs das collections
export const DATABASE_ID = import.meta.env.VITE_APPWRITE_DATABASE_ID as string;

export const COLLECTIONS = {
  PROFILES: import.meta.env.VITE_APPWRITE_COLLECTION_PROFILES as string,
  CUSTOMERS: import.meta.env.VITE_APPWRITE_COLLECTION_CUSTOMERS as string,
  INVENTORY: import.meta.env.VITE_APPWRITE_COLLECTION_INVENTORY as string,
  SALES: import.meta.env.VITE_APPWRITE_COLLECTION_SALES as string,
  RECEIVABLES: import.meta.env.VITE_APPWRITE_COLLECTION_RECEIVABLES as string,
  MOVEMENTS: import.meta.env.VITE_APPWRITE_COLLECTION_MOVEMENTS as string,
} as const;

// Re-exportar Query para facilitar uso
export { Query };

// Helper para criar queries com userId
export const userQuery = (userId: string) => Query.equal('userId', userId);

// Helper para ordenação
export const orderByCreatedAt = (_direction: 'asc' | 'desc' = 'desc') =>
  Query.orderDesc('createdAt');

export const orderByUpdatedAt = (_direction: 'asc' | 'desc' = 'desc') =>
  Query.orderDesc('updatedAt');

/**
 * Executa uma chamada ao Appwrite com retry automático em caso de erro 429.
 * Usa backoff exponencial: 1s, 2s, 4s entre tentativas.
 */
export async function withRetry<T>(fn: () => Promise<T>, maxAttempts = 3): Promise<T> {
  let lastError: unknown;
  for (let attempt = 0; attempt < maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (err: unknown) {
      lastError = err;
      const code = (err as any)?.code ?? (err as any)?.status;
      if (code !== 429) throw err; // só faz retry em rate limit
      const delay = Math.pow(2, attempt) * 1000;
      await new Promise(r => setTimeout(r, delay));
    }
  }
  throw lastError;
}
