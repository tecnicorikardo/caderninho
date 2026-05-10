/**
 * Appwrite Database Adapter
 */

import { databases, DATABASE_ID, COLLECTIONS, Query, userQuery } from '../appwrite';
import type { IDBService } from '../db-adapter';
import type { 
  Customer, 
  InventoryItem, 
  Sale, 
  Receivable, 
  UserProfile 
} from '../types';
import { ID } from 'appwrite';

// Helper para converter Timestamp do Appwrite para formato compatível
function toTimestamp(date: string | Date) {
  if (typeof date === 'string') {
    return new Date(date);
  }
  return date;
}

export class AppwriteDBService implements IDBService {
  // ============================================================================
  // CUSTOMERS
  // ============================================================================

  async getCustomers(userId: string): Promise<Customer[]> {
    try {
      const response = await databases.listDocuments(
        DATABASE_ID,
        COLLECTIONS.CUSTOMERS,
        [
          userQuery(userId),
          Query.orderDesc('createdAt'),
          Query.limit(1000)
        ]
      );

      return response.documents.map(doc => ({
        id: doc.$id,
        name: doc.name,
        phone: doc.phone || '',
        phoneNormalized: doc.phoneNormalized || '',
        email: doc.email || null,
        address: doc.address || null,
        balanceCents: doc.balanceCents || 0,
        createdAt: toTimestamp(doc.createdAt) as any,
        updatedAt: toTimestamp(doc.updatedAt) as any,
      }));
    } catch (error: any) {
      console.error('Error getting customers:', error);
      throw new Error(error.message || 'Erro ao buscar clientes');
    }
  }

  async getCustomer(userId: string, customerId: string): Promise<Customer | null> {
    try {
      const doc = await databases.getDocument(
        DATABASE_ID,
        COLLECTIONS.CUSTOMERS,
        customerId
      );

      // Verificar se pertence ao usuário
      if (doc.userId !== userId) {
        return null;
      }

      return {
        $id: doc.$id,
        name: doc.name,
        phone: doc.phone || '',
        phoneNormalized: doc.phoneNormalized || '',
        email: doc.email || null,
        address: doc.address || null,
        balanceCents: doc.balanceCents || 0,
        createdAt: toTimestamp(doc.createdAt) as any,
        updatedAt: toTimestamp(doc.updatedAt) as any,
      };
    } catch (error: any) {
      if (error.code === 404) {
        return null;
      }
      throw new Error(error.message || 'Erro ao buscar cliente');
    }
  }

  async createCustomer(
    userId: string, 
    data: Omit<Customer, 'id' | 'createdAt' | 'updatedAt'>
  ): Promise<string> {
    try {
      const now = new Date().toISOString();
      const doc = await databases.createDocument(
        DATABASE_ID,
        COLLECTIONS.CUSTOMERS,
        ID.unique(),
        {
          userId,
          ...data,
          createdAt: now,
          updatedAt: now,
        }
      );

      return doc.$id;
    } catch (error: any) {
      throw new Error(error.message || 'Erro ao criar cliente');
    }
  }

  async updateCustomer(
    userId: string, 
    customerId: string, 
    data: Partial<Customer>
  ): Promise<void> {
    try {
      const now = new Date().toISOString();
      await databases.updateDocument(
        DATABASE_ID,
        COLLECTIONS.CUSTOMERS,
        customerId,
        {
          ...data,
          updatedAt: now,
        }
      );
    } catch (error: any) {
      throw new Error(error.message || 'Erro ao atualizar cliente');
    }
  }

  async deleteCustomer(userId: string, customerId: string): Promise<void> {
    try {
      await databases.deleteDocument(
        DATABASE_ID,
        COLLECTIONS.CUSTOMERS,
        customerId
      );
    } catch (error: any) {
      throw new Error(error.message || 'Erro ao excluir cliente');
    }
  }

  // ============================================================================
  // INVENTORY
  // ============================================================================

  async getInventoryItems(userId: string): Promise<InventoryItem[]> {
    try {
      const response = await databases.listDocuments(
        DATABASE_ID,
        COLLECTIONS.INVENTORY,
        [
          userQuery(userId),
          Query.orderDesc('createdAt'),
          Query.limit(1000)
        ]
      );

      return response.documents.map(doc => ({
        id: doc.$id,
        productId: doc.productId,
        sku: doc.sku || null,
        productName: doc.productName,
        brand: doc.brand,
        quantity: doc.quantity || 0,
        costPriceCents: doc.costPriceCents || 0,
        sellingPriceCents: doc.sellingPriceCents || 0,
        expiryDate: toTimestamp(doc.expiryDate) as any,
        imageUrl: doc.imageUrl || null,
        createdAt: toTimestamp(doc.createdAt) as any,
        updatedAt: toTimestamp(doc.updatedAt) as any,
      }));
    } catch (error: any) {
      console.error('Error getting inventory:', error);
      throw new Error(error.message || 'Erro ao buscar estoque');
    }
  }

  async getInventoryItem(userId: string, itemId: string): Promise<InventoryItem | null> {
    try {
      const doc = await databases.getDocument(
        DATABASE_ID,
        COLLECTIONS.INVENTORY,
        itemId
      );

      if (doc.userId !== userId) {
        return null;
      }

      return {
        $id: doc.$id,
        productId: doc.productId,
        sku: doc.sku || null,
        productName: doc.productName,
        brand: doc.brand,
        quantity: doc.quantity || 0,
        costPriceCents: doc.costPriceCents || 0,
        sellingPriceCents: doc.sellingPriceCents || 0,
        expiryDate: toTimestamp(doc.expiryDate) as any,
        imageUrl: doc.imageUrl || null,
        createdAt: toTimestamp(doc.createdAt) as any,
        updatedAt: toTimestamp(doc.updatedAt) as any,
      };
    } catch (error: any) {
      if (error.code === 404) {
        return null;
      }
      throw new Error(error.message || 'Erro ao buscar item');
    }
  }

  async createInventoryItem(
    userId: string, 
    data: Omit<InventoryItem, 'id' | 'createdAt' | 'updatedAt'>
  ): Promise<string> {
    try {
      const now = new Date().toISOString();
      const doc = await databases.createDocument(
        DATABASE_ID,
        COLLECTIONS.INVENTORY,
        ID.unique(),
        {
          userId,
          ...data,
          createdAt: now,
          updatedAt: now,
        }
      );

      return doc.$id;
    } catch (error: any) {
      throw new Error(error.message || 'Erro ao criar item');
    }
  }

  async updateInventoryItem(
    userId: string, 
    itemId: string, 
    data: Partial<InventoryItem>
  ): Promise<void> {
    try {
      const now = new Date().toISOString();
      await databases.updateDocument(
        DATABASE_ID,
        COLLECTIONS.INVENTORY,
        itemId,
        {
          ...data,
          updatedAt: now,
        }
      );
    } catch (error: any) {
      throw new Error(error.message || 'Erro ao atualizar item');
    }
  }

  async deleteInventoryItem(userId: string, itemId: string): Promise<void> {
    try {
      await databases.deleteDocument(
        DATABASE_ID,
        COLLECTIONS.INVENTORY,
        itemId
      );
    } catch (error: any) {
      throw new Error(error.message || 'Erro ao excluir item');
    }
  }

  // ============================================================================
  // SALES
  // ============================================================================

  async getSales(
    userId: string, 
    filters?: { startDate?: Date; endDate?: Date }
  ): Promise<Sale[]> {
    try {
      const queries = [
        userQuery(userId),
        Query.orderDesc('createdAt'),
        Query.limit(1000)
      ];

      if (filters?.startDate) {
        queries.push(Query.greaterThanEqual('createdAt', filters.startDate.toISOString()));
      }

      if (filters?.endDate) {
        queries.push(Query.lessThanEqual('createdAt', filters.endDate.toISOString()));
      }

      const response = await databases.listDocuments(
        DATABASE_ID,
        COLLECTIONS.SALES,
        queries
      );

      return response.documents.map(doc => ({
        id: doc.$id,
        customerId: doc.customerId,
        items: JSON.parse(doc.items || '[]'),
        totalCents: doc.totalCents || 0,
        paidCents: doc.paidCents || 0,
        paymentType: doc.paymentType,
        createdAt: toTimestamp(doc.createdAt) as any,
        updatedAt: toTimestamp(doc.updatedAt) as any,
      }));
    } catch (error: any) {
      console.error('Error getting sales:', error);
      throw new Error(error.message || 'Erro ao buscar vendas');
    }
  }

  async getSale(userId: string, saleId: string): Promise<Sale | null> {
    try {
      const doc = await databases.getDocument(
        DATABASE_ID,
        COLLECTIONS.SALES,
        saleId
      );

      if (doc.userId !== userId) {
        return null;
      }

      return {
        $id: doc.$id,
        customerId: doc.customerId,
        items: JSON.parse(doc.items || '[]'),
        totalCents: doc.totalCents || 0,
        paidCents: doc.paidCents || 0,
        paymentType: doc.paymentType,
        createdAt: toTimestamp(doc.createdAt) as any,
        updatedAt: toTimestamp(doc.updatedAt) as any,
      };
    } catch (error: any) {
      if (error.code === 404) {
        return null;
      }
      throw new Error(error.message || 'Erro ao buscar venda');
    }
  }

  async createSale(
    userId: string, 
    data: Omit<Sale, 'id' | 'createdAt' | 'updatedAt'>
  ): Promise<string> {
    try {
      const now = new Date().toISOString();
      const doc = await databases.createDocument(
        DATABASE_ID,
        COLLECTIONS.SALES,
        ID.unique(),
        {
          userId,
          customerId: data.customerId,
          items: JSON.stringify(data.items),
          totalCents: data.totalCents,
          paidCents: data.paidCents,
          paymentType: data.paymentType,
          createdAt: now,
          updatedAt: now,
        }
      );

      return doc.$id;
    } catch (error: any) {
      throw new Error(error.message || 'Erro ao criar venda');
    }
  }

  // ============================================================================
  // RECEIVABLES
  // ============================================================================

  async getReceivables(
    userId: string, 
    filters?: { status?: string; customerId?: string }
  ): Promise<Receivable[]> {
    try {
      const queries = [
        userQuery(userId),
        Query.orderDesc('createdAt'),
        Query.limit(1000)
      ];

      if (filters?.status) {
        queries.push(Query.equal('status', filters.status));
      }

      if (filters?.customerId) {
        queries.push(Query.equal('customerId', filters.customerId));
      }

      const response = await databases.listDocuments(
        DATABASE_ID,
        COLLECTIONS.RECEIVABLES,
        queries
      );

      return response.documents.map(doc => ({
        id: doc.$id,
        saleId: doc.saleId,
        customerId: doc.customerId,
        dueDate: toTimestamp(doc.dueDate) as any,
        amountCents: doc.amountCents || 0,
        paidCents: doc.paidCents || 0,
        status: doc.status,
        createdAt: toTimestamp(doc.createdAt) as any,
        updatedAt: toTimestamp(doc.updatedAt) as any,
      }));
    } catch (error: any) {
      console.error('Error getting receivables:', error);
      throw new Error(error.message || 'Erro ao buscar recebíveis');
    }
  }

  async getReceivable(userId: string, receivableId: string): Promise<Receivable | null> {
    try {
      const doc = await databases.getDocument(
        DATABASE_ID,
        COLLECTIONS.RECEIVABLES,
        receivableId
      );

      if (doc.userId !== userId) {
        return null;
      }

      return {
        $id: doc.$id,
        saleId: doc.saleId,
        customerId: doc.customerId,
        dueDate: toTimestamp(doc.dueDate) as any,
        amountCents: doc.amountCents || 0,
        paidCents: doc.paidCents || 0,
        status: doc.status,
        createdAt: toTimestamp(doc.createdAt) as any,
        updatedAt: toTimestamp(doc.updatedAt) as any,
      };
    } catch (error: any) {
      if (error.code === 404) {
        return null;
      }
      throw new Error(error.message || 'Erro ao buscar recebível');
    }
  }

  async createReceivable(
    userId: string, 
    data: Omit<Receivable, 'id' | 'createdAt' | 'updatedAt'>
  ): Promise<string> {
    try {
      const now = new Date().toISOString();
      const doc = await databases.createDocument(
        DATABASE_ID,
        COLLECTIONS.RECEIVABLES,
        ID.unique(),
        {
          userId,
          ...data,
          createdAt: now,
          updatedAt: now,
        }
      );

      return doc.$id;
    } catch (error: any) {
      throw new Error(error.message || 'Erro ao criar recebível');
    }
  }

  async updateReceivable(
    userId: string, 
    receivableId: string, 
    data: Partial<Receivable>
  ): Promise<void> {
    try {
      const now = new Date().toISOString();
      await databases.updateDocument(
        DATABASE_ID,
        COLLECTIONS.RECEIVABLES,
        receivableId,
        {
          ...data,
          updatedAt: now,
        }
      );
    } catch (error: any) {
      throw new Error(error.message || 'Erro ao atualizar recebível');
    }
  }

  // ============================================================================
  // PROFILE
  // ============================================================================

  async getUserProfile(userId: string): Promise<UserProfile | null> {
    try {
      const response = await databases.listDocuments(
        DATABASE_ID,
        COLLECTIONS.PROFILES,
        [
          userQuery(userId),
          Query.limit(1)
        ]
      );

      if (response.documents.length === 0) {
        return null;
      }

      const doc = response.documents[0];
      return {
        createdAt: toTimestamp(doc.createdAt) as any,
        updatedAt: toTimestamp(doc.updatedAt) as any,
        onboardedAt: doc.onboardedAt ? toTimestamp(doc.onboardedAt) as any : null,
        growthLevel: doc.growthLevel,
        brandMargins: doc.brandMargins ? JSON.parse(doc.brandMargins) : undefined,
        planStatus: doc.planStatus,
        themeColor: doc.themeColor,
      };
    } catch (error: any) {
      console.error('Error getting profile:', error);
      return null;
    }
  }

  async createUserProfile(userId: string, data: Partial<UserProfile>): Promise<void> {
    try {
      const now = new Date().toISOString();
      await databases.createDocument(
        DATABASE_ID,
        COLLECTIONS.PROFILES,
        ID.unique(),
        {
          userId,
          createdAt: now,
          updatedAt: now,
          ...data,
          brandMargins: data.brandMargins ? JSON.stringify(data.brandMargins) : undefined,
        }
      );
    } catch (error: any) {
      throw new Error(error.message || 'Erro ao criar perfil');
    }
  }

  async updateUserProfile(userId: string, data: Partial<UserProfile>): Promise<void> {
    try {
      // Primeiro, buscar o documento do perfil
      const response = await databases.listDocuments(
        DATABASE_ID,
        COLLECTIONS.PROFILES,
        [
          userQuery(userId),
          Query.limit(1)
        ]
      );

      if (response.documents.length === 0) {
        throw new Error('Perfil não encontrado');
      }

      const profileId = response.documents[0].$id;
      const now = new Date().toISOString();

      await databases.updateDocument(
        DATABASE_ID,
        COLLECTIONS.PROFILES,
        profileId,
        {
          ...data,
          updatedAt: now,
          brandMargins: data.brandMargins ? JSON.stringify(data.brandMargins) : undefined,
        }
      );
    } catch (error: any) {
      throw new Error(error.message || 'Erro ao atualizar perfil');
    }
  }
}
