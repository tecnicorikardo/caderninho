import {
  Timestamp,
  collection,
  doc,
  runTransaction,
  serverTimestamp,
} from "firebase/firestore";
import { db } from "@/lib/firebase";
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

  const salesCol = collection(db, "users", uid, "sales");
  const receivablesCol = collection(db, "users", uid, "receivables");
  const customersCol = collection(db, "users", uid, "customers");
  const inventoryCol = collection(db, "users", uid, "inventory");

  const saleRef = doc(salesCol);
  const customerRef = doc(customersCol, customerId);

  const outstanding = Math.max(0, totalCents - paidCents);

  await runTransaction(db, async (tx) => {
    // Atualiza estoque (se o item referenciar inventoryId)
    for (const it of items) {
      if (!it.inventoryId) continue;
      const invRef = doc(inventoryCol, it.inventoryId);
      const snap = await tx.get(invRef);
      if (!snap.exists()) throw new Error("Item de estoque não encontrado.");
      const qty = Number((snap.data() as { quantity?: number }).quantity ?? 0);
      const next = qty - it.quantity;
      if (next < 0) throw new Error("Estoque insuficiente.");
      tx.update(invRef, { quantity: next, updatedAt: serverTimestamp() });
    }

    const sale: Sale = {
      customerId,
      items,
      totalCents,
      paidCents,
      paymentType,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    };
    tx.set(saleRef, sale);

    if (paymentType === "fiado") {
      const ref = doc(receivablesCol);
      const dueDate = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
      const rec: Receivable = {
        saleId: saleRef.id,
        customerId,
        dueDate: Timestamp.fromDate(dueDate),
        amountCents: outstanding,
        paidCents: 0,
        status: "pending",
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      };
      tx.set(ref, rec);
    }

    if (paymentType === "installments") {
      const plan = installments ?? [];
      for (const inst of plan) {
        const ref = doc(receivablesCol);
        const paid = 0;
        const rec: Receivable = {
          saleId: saleRef.id,
          customerId,
          dueDate: Timestamp.fromDate(inst.dueDate),
          amountCents: inst.amountCents,
          paidCents: paid,
          status: computeReceivableStatus(inst.amountCents, paid),
          createdAt: serverTimestamp(),
          updatedAt: serverTimestamp(),
        };
        tx.set(ref, rec);
      }
    }

    if (outstanding > 0) {
      const custSnap = await tx.get(customerRef);
      const current = custSnap.exists() ? Number((custSnap.data() as { balanceCents?: number }).balanceCents ?? 0) : 0;
      tx.set(
        customerRef,
        { balanceCents: current + outstanding, updatedAt: serverTimestamp(), createdAt: serverTimestamp() },
        { merge: true },
      );
    }
  });

  return saleRef.id;
}

