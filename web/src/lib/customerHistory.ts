import { collection, getDocs, limit, orderBy, query, where } from "firebase/firestore";
import { db } from "@/lib/firebase";
import { formatMoney } from "@/lib/money";
import type { Customer, Receivable, Sale } from "@/lib/types";

function formatDate(d: Date): string {
  return d.toLocaleDateString("pt-BR");
}

export async function buildCustomerHistoryText(params: { uid: string; customerId: string; customer: Customer }) {
  const { uid, customerId, customer } = params;

  const salesCol = collection(db, "users", uid, "sales");
  const receivablesCol = collection(db, "users", uid, "receivables");

  const salesQ = query(salesCol, where("customerId", "==", customerId), orderBy("createdAt", "desc"), limit(10));
  const recvQ = query(receivablesCol, where("customerId", "==", customerId), orderBy("dueDate", "asc"), limit(20));

  const [salesSnap, recvSnap] = await Promise.all([getDocs(salesQ), getDocs(recvQ)]);
  const sales = salesSnap.docs.map((d) => ({ id: d.id, ...(d.data() as Sale) }));
  const receivables = recvSnap.docs.map((d) => ({ id: d.id, ...(d.data() as Receivable) }));

  const lines: string[] = [];
  lines.push(`Cliente: ${customer.name}`);
  lines.push(`Telefone: ${customer.phone}`);
  lines.push(`Saldo (fiado/parcelas): ${formatMoney(customer.balanceCents ?? 0)}`);
  lines.push("");

  if (sales.length > 0) {
    lines.push("Últimas vendas:");
    for (const s of sales) {
      const createdAt = (s.createdAt as { toDate?: () => Date })?.toDate?.() ?? new Date();
      lines.push(`- ${formatDate(createdAt)} • ${formatMoney(s.totalCents)} • pago ${formatMoney(s.paidCents)}`);
    }
    lines.push("");
  }

  const pending = receivables.filter((r) => (r.amountCents ?? 0) > (r.paidCents ?? 0));
  if (pending.length > 0) {
    lines.push("Parcelas pendentes:");
    for (const r of pending.slice(0, 20)) {
      const due = (r.dueDate as { toDate?: () => Date })?.toDate?.() ?? new Date();
      const open = (r.amountCents ?? 0) - (r.paidCents ?? 0);
      lines.push(`- vence ${formatDate(due)} • em aberto ${formatMoney(open)}`);
    }
  }

  return lines.join("\n");
}

