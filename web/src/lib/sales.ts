import { databases, DATABASE_ID, COLLECTIONS, Query } from "@/lib/supabase";
import { ID } from "@/lib/supabase";
import { nowISO } from "@/lib/timestamp";
import type { PaymentType, Receivable, ReceivableStatus, Sale, SaleItem } from "@/lib/types";

function computeReceivableStatus(amountCents: number, paidCents: number): ReceivableStatus {
  if (paidCents <= 0) return "pending";
  if (paidCents >= amountCents) return "paid";
  return "partial";
}

export type InstallmentPlan = Array<{ dueDate: Date; amountCents: number }>;

export async function createSaleWithReceivables(params: {
  uid: string;
  customerId: string;
  items: SaleItem[];
  totalCents: number;
  paidCents: number;
  paymentType: PaymentType;
  installments?: InstallmentPlan;
}) {
  const { uid, customerId, items, totalCents, paidCents, paymentType, installments } = params;
  const now = nowISO();
  const outstanding = Math.max(0, totalCents - paidCents);

  // 1. Baixar estoque dos itens com inventoryId
  for (const item of items) {
    if (!item.inventoryId) continue;
    const doc = await databases.getDocument(DATABASE_ID, COLLECTIONS.INVENTORY, item.inventoryId);
    const currentQty = Number(doc.quantity ?? 0);
    const nextQty = currentQty - item.quantity;
    if (nextQty < 0) throw new Error(`Estoque insuficiente para: ${item.productName}`);
    await databases.updateDocument(DATABASE_ID, COLLECTIONS.INVENTORY, item.inventoryId, {
      quantity: nextQty,
      updatedAt: now,
    });
  }

  // 2. Criar venda
  const saleDoc = await databases.createDocument(DATABASE_ID, COLLECTIONS.SALES, ID.unique(), {
    userId: uid,
    customerId,
    items: JSON.stringify(items),
    totalCents,
    paidCents,
    paymentType,
    createdAt: now,
    updatedAt: now,
  });

  const saleId = saleDoc.$id;

  // 3. Criar recebível para fiado
  if (paymentType === "fiado") {
    const dueDate = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString();
    await databases.createDocument(DATABASE_ID, COLLECTIONS.RECEIVABLES, ID.unique(), {
      userId: uid,
      saleId,
      customerId,
      dueDate,
      amountCents: outstanding,
      paidCents: 0,
      status: "pending",
      createdAt: now,
      updatedAt: now,
    });
  }

  // 4. Criar recebíveis para parcelado
  if (paymentType === "installments") {
    const plan = installments ?? [];
    for (const inst of plan) {
      await databases.createDocument(DATABASE_ID, COLLECTIONS.RECEIVABLES, ID.unique(), {
        userId: uid,
        saleId,
        customerId,
        dueDate: inst.dueDate.toISOString(),
        amountCents: inst.amountCents,
        paidCents: 0,
        status: computeReceivableStatus(inst.amountCents, 0),
        createdAt: now,
        updatedAt: now,
      });
    }
  }

  // 5. Atualizar saldo do cliente
  if (outstanding > 0) {
    const res = await databases.listDocuments(DATABASE_ID, COLLECTIONS.CUSTOMERS, [
      Query.equal("$id", customerId),
      Query.limit(1),
    ]);
    if (res.documents.length > 0) {
      const current = Number(res.documents[0].balanceCents ?? 0);
      await databases.updateDocument(DATABASE_ID, COLLECTIONS.CUSTOMERS, customerId, {
        balanceCents: current + outstanding,
        updatedAt: now,
      });
    }
  }

  return saleId;
}
