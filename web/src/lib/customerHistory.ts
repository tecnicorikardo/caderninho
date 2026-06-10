import { databases, DATABASE_ID, COLLECTIONS, Query } from "@/lib/supabase";
import { toDate } from "@/lib/timestamp";
import { formatMoney } from "@/lib/money";
import type { Customer, Receivable, Sale } from "@/lib/types";

function formatDate(d: Date): string {
  return d.toLocaleDateString("pt-BR");
}

export async function buildCustomerHistoryText(params: { uid: string; customerId: string; customer: Customer }) {
  const { uid, customerId, customer } = params;

  const [salesRes, recvRes] = await Promise.all([
    databases.listDocuments(DATABASE_ID, COLLECTIONS.SALES, [
      Query.equal("userId", uid),
      Query.equal("customerId", customerId),
      Query.orderDesc("createdAt"),
      Query.limit(10),
    ]),
    databases.listDocuments(DATABASE_ID, COLLECTIONS.RECEIVABLES, [
      Query.equal("userId", uid),
      Query.equal("customerId", customerId),
      Query.orderAsc("dueDate"),
      Query.limit(20),
    ]),
  ]);

  const sales = salesRes.documents.map(d => ({
    ...d,
    items: JSON.parse(d.items || "[]"),
  } as unknown as Sale & { $id: string }));

  const receivables = recvRes.documents as unknown as (Receivable & { $id: string })[];

  const lines: string[] = [];
  lines.push(`Cliente: ${customer.name}`);
  lines.push(`Telefone: ${customer.phone}`);
  lines.push(`Saldo (fiado/parcelas): ${formatMoney(customer.balanceCents ?? 0)}`);
  lines.push("");

  if (sales.length > 0) {
    lines.push("Últimas vendas:");
    for (const s of sales) {
      const date = formatDate(toDate(s.createdAt));
      lines.push(`- ${date} • ${formatMoney(s.totalCents)} • pago ${formatMoney(s.paidCents)}`);
    }
    lines.push("");
  }

  const pending = receivables.filter(r => (r.amountCents ?? 0) > (r.paidCents ?? 0));
  if (pending.length > 0) {
    lines.push("Parcelas pendentes:");
    for (const r of pending.slice(0, 20)) {
      const due = formatDate(toDate(r.dueDate));
      const open = (r.amountCents ?? 0) - (r.paidCents ?? 0);
      lines.push(`- vence ${due} • em aberto ${formatMoney(open)}`);
    }
  }

  return lines.join("\n");
}
