/**
 * Firebase Auth Adapter
 * 
 * Mantém compatibilidade com Firebase durante a migração
 */

import { 
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  signOut as firebaseSignOut,
  sendPasswordResetEmail,
  onAuthStateChanged as firebaseOnAuthStateChanged,
} from 'firebase/auth';
import { auth } from '../firebase';
import type { IAuthService } from '../db-adapter';

export class FirebaseAuthService implements IAuthService {
  async signIn(email: string, password: string): Promise<{ userId: string }> {
    try {
      const userCredential = await signInWithEmailAndPassword(auth, email, password);
      return { userId: userCredential.user.uid };
    } catch (error: any) {
      throw new Error(error.message || 'Erro ao fazer login');
    }
  }

  async signUp(email: string, password: string): Promise<{ userId: string }> {
    try {
      const userCredential = await createUserWithEmailAndPassword(auth, email, password);
      return { userId: userCredential.user.uid };
    } catch (error: any) {
      throw new Error(error.message || 'Erro ao criar conta');
    }
  }

  async signOut(): Promise<void> {
    try {
      await firebaseSignOut(auth);
    } catch (error: any) {
      throw new Error(error.message || 'Erro ao fazer logout');
    }
  }

  async resetPassword(email: string): Promise<void> {
    try {
      await sendPasswordResetEmail(auth, email);
    } catch (error: any) {
      throw new Error(error.message || 'Erro ao enviar e-mail de recuperação');
    }
  }

  async getCurrentUser(): Promise<{ userId: string; email: string } | null> {
    const user = auth.currentUser;
    if (!user || !user.email) {
      return null;
    }
    return {
      userId: user.uid,
      email: user.email,
    };
  }

  onAuthStateChanged(
    callback: (user: { userId: string; email: string } | null) => void
  ): () => void {
    return firebaseOnAuthStateChanged(auth, (firebaseUser) => {
      if (firebaseUser && firebaseUser.email) {
        callback({
          userId: firebaseUser.uid,
          email: firebaseUser.email,
        });
      } else {
        callback(null);
      }
    });
  }
}
