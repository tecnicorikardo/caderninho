import { collection, doc, getDocs, orderBy, query, runTransaction, serverTimestamp, where } from "firebase/firestore";
import { db } from "@/lib/firebase";
import type { InventoryItem, SaleItem } from "@/lib/types";

export function fefoInventorySort(items: InventoryItem[]): InventoryItem[] {
  return [...items].sort((a, b) => a.expiryDate.toMillis() - b.expiryDate.toMillis());
}

export async function updateStockAfterSale(uid: string, saleItems: Array<Pick<SaleItem, "inventoryId" | "quantity">>) {
  const inventoryCol = collection(db, "users", uid, "inventory");

  await runTransaction(db, async (tx) => {
    for (const item of saleItems) {
      if (!item.inventoryId) continue;
      const ref = doc(inventoryCol, item.inventoryId);
      const snap = await tx.get(ref);
      if (!snap.exists()) throw new Error("Item de estoque não encontrado.");

      const data = snap.data() as InventoryItem;
      const nextQty = (data.quantity ?? 0) - item.quantity;
      if (nextQty < 0) throw new Error("Estoque insuficiente.");

      tx.update(ref, { quantity: nextQty, updatedAt: serverTimestamp() });
    }
  });
}

export async function listInventoryExpiringSoon(uid: string, daysAhead: number) {
  const now = new Date();
  const limitDate = new Date(now.getTime() + daysAhead * 24 * 60 * 60 * 1000);
  const colRef = collection(db, "users", uid, "inventory");
  const q = query(colRef, where("expiryDate", "<=", limitDate), orderBy("expiryDate", "asc"));
  const snap = await getDocs(q);
  return snap.docs.map((d) => ({ id: d.id, ...(d.data() as InventoryItem) }));
}

