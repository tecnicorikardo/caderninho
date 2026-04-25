import { doc, getDoc, serverTimestamp, setDoc, updateDoc } from "firebase/firestore";
import { db } from "@/lib/firebase";
import type { UserProfile } from "@/lib/types";

export async function ensureUserProfile(uid: string): Promise<UserProfile> {
  const ref = doc(db, "users", uid);
  const snap = await getDoc(ref);

  if (!snap.exists()) {
    const profile: Omit<UserProfile, "onboardedAt"> = {
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    };
    await setDoc(ref, profile, { merge: true });
    return { ...profile, onboardedAt: null };
  }

  const data = snap.data() as UserProfile;
  return { ...data, onboardedAt: data.onboardedAt ?? null };
}

export async function markOnboarded(uid: string) {
  const ref = doc(db, "users", uid);
  await updateDoc(ref, { onboardedAt: serverTimestamp(), updatedAt: serverTimestamp() });
}

