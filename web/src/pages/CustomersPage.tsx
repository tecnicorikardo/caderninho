import { useEffect, useMemo, useState } from "react";
import type { User } from "firebase/auth";
import { collection, getDocs, limit, orderBy, query } from "firebase/firestore";
import DashboardLayout from "@/ui/DashboardLayout";
import { db } from "@/lib/firebase";
import type { Customer } from "@/lib/types";
import { buildCustomerHistoryText } from "@/lib/customerHistory";
import { shareOrWhatsApp } from "@/lib/whatsapp";
import { formatMoney } from "@/lib/money";

type Row = Customer & { id: string };

export default function CustomersPage({ user }: { user: User }) {
  const [rows, setRows] = useState<Row[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function load() {
      setLoading(true);
      setError(null);
      const colRef = collection(db, "users", user.uid, "customers");
      const q = query(colRef, orderBy("createdAt", "desc"), limit(50));
      const snap = await getDocs(q);
      setRows(snap.docs.map((d) => ({ id: d.id, ...(d.data() as Customer) })));
      setLoading(false);
    }
    load().catch((err) => {
      setError(err instanceof Error ? err.message : "Falha ao carregar clientes.");
      setLoading(false);
    });
  }, [user.uid]);

  const content = useMemo(() => {
    if (loading) return <div className="text-sm text-gray-600">Carregando…</div>;
    if (error) return <div className="text-sm text-red-700">{error}</div>;
    if (rows.length === 0) return <div className="text-sm text-gray-600">Nenhum cliente cadastrado ainda.</div>;

    return (
      <div className="grid gap-2">
        {rows.map((c) => (
          <div key={c.id} className="rounded-xl bg-white border p-4 flex items-start justify-between gap-3">
            <div>
              <div className="font-semibold">{c.name}</div>
              <div className="text-sm text-gray-700">{c.phone}</div>
              <div className="text-sm text-gray-700">Saldo: {formatMoney(c.balanceCents ?? 0)}</div>
            </div>

            <button
              className="rounded-lg bg-gray-900 text-white px-4 py-3 min-h-12"
              onClick={async () => {
                const text = await buildCustomerHistoryText({ uid: user.uid, customerId: c.id, customer: c });
                await shareOrWhatsApp(text);
              }}
            >
              Enviar histórico (WhatsApp)
            </button>
          </div>
        ))}
      </div>
    );
  }, [error, loading, rows, user.uid]);

  return <DashboardLayout title="Clientes">{content}</DashboardLayout>;
}

