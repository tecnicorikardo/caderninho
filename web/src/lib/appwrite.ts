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
export const orderByCreatedAt = (direction: 'asc' | 'desc' = 'desc') => 
  Query.orderDesc('createdAt');

export const orderByUpdatedAt = (direction: 'asc' | 'desc' = 'desc') => 
  Query.orderDesc('updatedAt');
