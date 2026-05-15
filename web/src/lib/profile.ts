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
      // Se o Appwrite não tiver onboardedAt (campo pode não existir no schema),
      // usa o fallback do localStorage
      const onboardedAt = doc.onboardedAt ?? localStorage.getItem(`onboarded_${uid}`) ?? null;
      console.log("[ensureUserProfile] onboardedAt do Appwrite:", doc.onboardedAt, "| localStorage:", localStorage.getItem(`onboarded_${uid}`));
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
    return { createdAt: now, updatedAt: now, onboardedAt: null };
  }
}

export async function markOnboarded(uid: string) {
  const res = await databases.listDocuments(DATABASE_ID, COLLECTIONS.PROFILES, [
    Query.equal("userId", uid),
    Query.limit(1),
  ]);
  if (res.documents.length === 0) {
    console.warn("[markOnboarded] perfil não encontrado para uid:", uid);
    return;
  }
  const now = new Date().toISOString();
  try {
    const updated = await databases.updateDocument(DATABASE_ID, COLLECTIONS.PROFILES, res.documents[0].$id, {
      onboardedAt: now,
      updatedAt: now,
    });
    console.log("[markOnboarded] salvo no Appwrite:", updated.onboardedAt);
  } catch (err) {
    console.error("[markOnboarded] erro ao salvar no Appwrite:", err);
  }
  // Fallback local para garantir que o onboarding não apareça de novo
  // mesmo que o campo onboardedAt não exista no schema do Appwrite
  localStorage.setItem(`onboarded_${uid}`, now);
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
