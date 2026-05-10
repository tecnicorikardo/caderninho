/**
 * Appwrite Auth Adapter
 */

import { account } from '../appwrite';
import type { IAuthService } from '../db-adapter';
import { ID } from 'appwrite';

export class AppwriteAuthService implements IAuthService {
  async signIn(email: string, password: string): Promise<{ userId: string }> {
    try {
      const session = await account.createEmailPasswordSession(email, password);
      return { userId: session.userId };
    } catch (error: any) {
      throw new Error(error.message || 'Erro ao fazer login');
    }
  }

  async signUp(email: string, password: string): Promise<{ userId: string }> {
    try {
      const user = await account.create(ID.unique(), email, password);
      // Fazer login automaticamente após criar conta
      await this.signIn(email, password);
      return { userId: user.$id };
    } catch (error: any) {
      throw new Error(error.message || 'Erro ao criar conta');
    }
  }

  async signOut(): Promise<void> {
    try {
      await account.deleteSession('current');
    } catch (error: any) {
      throw new Error(error.message || 'Erro ao fazer logout');
    }
  }

  async resetPassword(email: string): Promise<void> {
    try {
      const redirectUrl = `${window.location.origin}/reset-password`;
      await account.createRecovery(email, redirectUrl);
    } catch (error: any) {
      throw new Error(error.message || 'Erro ao enviar e-mail de recuperação');
    }
  }

  async getCurrentUser(): Promise<{ userId: string; email: string } | null> {
    try {
      const user = await account.get();
      return {
        userId: user.$id,
        email: user.email,
      };
    } catch {
      return null;
    }
  }

  onAuthStateChanged(
    callback: (user: { userId: string; email: string } | null) => void
  ): () => void {
    // Appwrite não tem listener nativo, então fazemos polling ou verificação inicial
    let isActive = true;

    const checkAuth = async () => {
      if (!isActive) return;
      
      try {
        const user = await this.getCurrentUser();
        callback(user);
      } catch {
        callback(null);
      }
    };

    // Verificação inicial
    checkAuth();

    // Retornar função de cleanup
    return () => {
      isActive = false;
    };
  }
}
