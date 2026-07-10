import { account, getAuthRedirectUrl, ID } from "../supabase";
import type { IAuthService } from "../db-adapter";

export class SupabaseAuthService implements IAuthService {
  async signIn(email: string, password: string): Promise<{ userId: string }> {
    try {
      const session = await account.createEmailPasswordSession(email, password);
      return { userId: session.userId };
    } catch (error: any) {
      throw new Error(error.message || "Erro ao fazer login");
    }
  }

  async signUp(email: string, password: string): Promise<{ userId: string }> {
    try {
      const user = await account.create(ID.unique(), email, password);
      if (!user.emailConfirmationRequired) {
        await this.signIn(email, password);
      }
      return { userId: user.$id };
    } catch (error: any) {
      throw new Error(error.message || "Erro ao criar conta");
    }
  }

  async signOut(): Promise<void> {
    try {
      await account.deleteSession("current");
    } catch (error: any) {
      throw new Error(error.message || "Erro ao fazer logout");
    }
  }

  async resetPassword(email: string): Promise<void> {
    try {
      const redirectUrl = getAuthRedirectUrl();
      await account.createRecovery(email, redirectUrl);
    } catch (error: any) {
      throw new Error(error.message || "Erro ao enviar e-mail de recuperacao");
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
    return account.onAuthStateChanged(user => {
      callback(user ? { userId: user.$id, email: user.email } : null);
    });
  }
}
