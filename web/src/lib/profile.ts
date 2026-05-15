import { databases, account, DATABASE_ID, COLLECTIONS, Query } from "@/lib/appwrite";
import { ID } from "appwrite";
import type { UserProfile } from "@/lib/types";

export async function ensureUserProfile(uid: string): Promise<UserProfile> {
  try {
    const res = await databases.listDocuments(DATABASE_ID, COLLECTIONS.PROFILES, [
      Query.equal("userId", uid),
      Query.limit(1),
    ]);

    if (res.documents.length > 0) {
      const doc = res.documents[0];
      // Prioridade: Appwrite → localStorage → null
      // O localStorage garante que o onboarding não apareça de novo mesmo que
      // o campo onboardedAt não exista ou não seja salvo no schema do Appwrite
      const onboardedAt =
        (doc.onboardedAt as string | null | undefined) ||
        localStorage.getItem(`onboarded_${uid}`) ||
        null;
      return {
        createdAt: doc.createdAt,
        updatedAt: doc.updatedAt,
        onboardedAt,
        growthLevel: doc.growthLevel,
        brandMargins: doc.brandMargins ? JSON.parse(doc.brandMargins) : undefined,
        planStatus: doc.planStatus,
        themeColor: doc.themeColor,
      };
    }

    // Criar perfil novo
    const now = new Date().toISOString();
    const newProfile = {
      userId: uid,
      createdAt: now,
      updatedAt: now,
      onboardedAt: null,
      growthLevel: "Semente",
      brandMargins: JSON.stringify([
        { brand: "Natura", marginPercent: 30 },
        { brand: "Avon", marginPercent: 30 },
        { brand: "Casa & Estilo", marginPercent: 15 },
      ]),
      planStatus: "free",
      themeColor: null,
    };

    await databases.createDocument(DATABASE_ID, COLLECTIONS.PROFILES, ID.unique(), newProfile);

    return {
      createdAt: now,
      updatedAt: now,
      onboardedAt: null,
      growthLevel: "Semente",
      brandMargins: [
        { brand: "Natura", marginPercent: 30 },
        { brand: "Avon", marginPercent: 30 },
        { brand: "Casa & Estilo", marginPercent: 15 },
      ],
      planStatus: "free",
      themeColor: null,
    };
  } catch (err) {
    console.error("ensureUserProfile error:", err);
    const now = new Date().toISOString();
    // Mesmo em caso de erro, verifica o localStorage antes de retornar null
    return {
      createdAt: now,
      updatedAt: now,
      onboardedAt: localStorage.getItem(`onboarded_${uid}`) ?? null,
    };
  }
}

export async function markOnboarded(uid: string) {
  // Salva no localStorage imediatamente — fonte primária de verdade para o onboarding
  const now = new Date().toISOString();
  localStorage.setItem(`onboarded_${uid}`, now);

  // Tenta salvar no Appwrite também (best-effort, não bloqueia)
  try {
    const res = await databases.listDocuments(DATABASE_ID, COLLECTIONS.PROFILES, [
      Query.equal("userId", uid),
      Query.limit(1),
    ]);
    if (res.documents.length > 0) {
      await databases.updateDocument(DATABASE_ID, COLLECTIONS.PROFILES, res.documents[0].$id, {
        onboardedAt: now,
        updatedAt: now,
      });
    }
  } catch (err) {
    console.warn("[markOnboarded] não foi possível salvar no Appwrite:", err);
  }
}

export async function updateUserProfile(uid: string, data: Partial<UserProfile>) {
  const res = await databases.listDocuments(DATABASE_ID, COLLECTIONS.PROFILES, [
    Query.equal("userId", uid),
    Query.limit(1),
  ]);
  if (res.documents.length === 0) return;
  const now = new Date().toISOString();

  // Montar apenas os campos que foram passados (sem sobrescrever com undefined)
  const updateData: Record<string, unknown> = { updatedAt: now };
  if (data.themeColor !== undefined) updateData.themeColor = data.themeColor;
  if (data.planStatus !== undefined) updateData.planStatus = data.planStatus;
  if (data.growthLevel !== undefined) updateData.growthLevel = data.growthLevel;
  if (data.brandMargins !== undefined) updateData.brandMargins = JSON.stringify(data.brandMargins);
  if (data.onboardedAt !== undefined) updateData.onboardedAt = data.onboardedAt;

  await databases.updateDocument(DATABASE_ID, COLLECTIONS.PROFILES, res.documents[0].$id, updateData);
}
