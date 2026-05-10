import { databases, DATABASE_ID, COLLECTIONS, Query } from "@/lib/appwrite";
import { toMillis, nowISO } from "@/lib/timestamp";
import type { InventoryItem, SaleItem } from "@/lib/types";

export function fefoInventorySort(items: InventoryItem[]): InventoryItem[] {
  return [...items].sort((a, b) => toMillis(a.expiryDate) - toMillis(b.expiryDate));
}

export async function updateStockAfterSale(uid: string, saleItems: Array<Pick<SaleItem, "inventoryId" | "quantity">>) {
  for (const item of saleItems) {
    if (!item.inventoryId) continue;
    const doc = await databases.getDocument(DATABASE_ID, COLLECTIONS.INVENTORY, item.inventoryId);
    const data = doc as unknown as InventoryItem;
    const nextQty = (data.quantity ?? 0) - item.quantity;
    if (nextQty < 0) throw new Error("Estoque insuficiente.");
    await databases.updateDocument(DATABASE_ID, COLLECTIONS.INVENTORY, item.inventoryId, {
      quantity: nextQty,
      updatedAt: nowISO(),
    });
  }
}

export async function listInventoryExpiringSoon(uid: string, daysAhead: number) {
  const limitDate = new Date(Date.now() + daysAhead * 24 * 60 * 60 * 1000).toISOString();
  const res = await databases.listDocuments(DATABASE_ID, COLLECTIONS.INVENTORY, [
    Query.equal("userId", uid),
    Query.lessThanEqual("expiryDate", limitDate),
    Query.orderAsc("expiryDate"),
  ]);
  return res.documents.map(d => ({ ...d } as unknown as InventoryItem & { $id: string }));
}
