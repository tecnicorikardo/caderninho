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

  // Pré-calcular refs de estoque para usar dentro da transação
  const inventoryRefs = items
    .filter(it => !!it.inventoryId)
    .map(it => ({ it, ref: doc(inventoryCol, it.inventoryId!) }));

  await runTransaction(db, async (tx) => {
    // ── FASE 1: TODAS AS LEITURAS ──────────────────────────────────────────
    const invSnaps = await Promise.all(inventoryRefs.map(({ ref }) => tx.get(ref)));

    // Leitura do cliente só se houver saldo a receber
    const custSnap = outstanding > 0 ? await tx.get(customerRef) : null;

    // ── VALIDAÇÕES (sem I/O) ───────────────────────────────────────────────
    const invUpdates: Array<{ ref: ReturnType<typeof doc>; nextQty: number }> = [];

    for (let i = 0; i < inventoryRefs.length; i++) {
      const snap = invSnaps[i];
      const { it, ref } = inventoryRefs[i];
      if (!snap.exists()) throw new Error(`Item de estoque não encontrado: ${it.productName}`);
      const qty = Number((snap.data() as { quantity?: number }).quantity ?? 0);
      const next = qty - it.quantity;
      if (next < 0) throw new Error(`Estoque insuficiente para: ${it.productName}`);
      invUpdates.push({ ref, nextQty: next });
    }

    // ── FASE 2: TODAS AS ESCRITAS ──────────────────────────────────────────

    // Atualizar estoque
    for (const { ref, nextQty } of invUpdates) {
      tx.update(ref, { quantity: nextQty, updatedAt: serverTimestamp() });
    }

    // Criar venda
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

    // Criar recebível para fiado
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

    // Criar recebíveis para parcelado
    if (paymentType === "installments") {
      const plan = installments ?? [];
      for (const inst of plan) {
        const ref = doc(receivablesCol);
        const rec: Receivable = {
          saleId: saleRef.id,
          customerId,
          dueDate: Timestamp.fromDate(inst.dueDate),
          amountCents: inst.amountCents,
          paidCents: 0,
          status: computeReceivableStatus(inst.amountCents, 0),
          createdAt: serverTimestamp(),
          updatedAt: serverTimestamp(),
        };
        tx.set(ref, rec);
      }
    }

    // Atualizar saldo do cliente
    if (outstanding > 0) {
      const current = custSnap?.exists()
        ? Number((custSnap.data() as { balanceCents?: number }).balanceCents ?? 0)
        : 0;
      tx.set(
        customerRef,
        { balanceCents: current + outstanding, updatedAt: serverTimestamp(), createdAt: serverTimestamp() },
        { merge: true },
      );
    }
  });

  return saleRef.id;
}
