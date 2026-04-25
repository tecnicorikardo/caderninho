import { useEffect, useMemo, useState } from "react";
import { collection, getDocs, orderBy, query } from "firebase/firestore";
import { db } from "@/lib/firebase";
import type { InventoryItem } from "@/lib/types";

export default function StockHealthWidget({ uid }: { uid: string }) {
  const [items, setItems] = useState<Array<InventoryItem & { id: string }>>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function load() {
      setLoading(true);
      const colRef = collection(db, "users", uid, "inventory");
      const q = query(colRef, orderBy("expiryDate", "asc"));
      const snap = await getDocs(q);
      setItems(snap.docs.map((d) => ({ id: d.id, ...(d.data() as InventoryItem) })));
      setLoading(false);
    }
    load().catch(() => setLoading(false));
  }, [uid]);

  const stats = useMemo(() => {
    const now = Date.now();
    const ninety = now + 90 * 24 * 60 * 60 * 1000;
    const sixty = now + 60 * 24 * 60 * 60 * 1000;

    let totalQty = 0;
    let exp90Qty = 0;
    const expSoon: Array<InventoryItem & { id: string }> = [];

    for (const it of items) {
      const qty = Number(it.quantity ?? 0);
      if (qty <= 0) continue;
      totalQty += qty;

      const ms = it.expiryDate?.toMillis?.() ?? 0;
      if (ms && ms <= ninety) exp90Qty += qty;
      if (ms && ms <= sixty) expSoon.push(it);
    }

    const pct = totalQty > 0 ? Math.round((exp90Qty / totalQty) * 100) : 0;
    return { totalQty, pct, expSoon };
  }, [items]);

  return (
    <section className="rounded-xl bg-white border p-5">
      <h2 className="text-lg font-semibold">Saúde do Estoque</h2>
      <p className="text-sm text-gray-700 mt-1">Percentual de itens (por quantidade) vencendo no próximo trimestre.</p>

      {loading ? (
        <div className="mt-4 text-sm text-gray-600">Carregando…</div>
      ) : (
        <div className="mt-4">
          <div className="text-3xl font-semibold">{stats.pct}%</div>
          <div className="text-sm text-gray-600 mt-1">Quantidade total em estoque: {stats.totalQty}</div>

          {stats.expSoon.length > 0 ? (
            <div className="mt-4">
              <div className="text-sm font-medium">Vencem em menos de 60 dias</div>
              <div className="mt-2 grid gap-2">
                {stats.expSoon.slice(0, 6).map((it) => (
                  <div key={it.id} className="rounded-lg bg-red-100 px-3 py-2 text-sm">
                    <div className="font-medium">{it.productName}</div>
                    <div className="text-gray-700">
                      {it.brand} • qty {it.quantity}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          ) : null}
        </div>
      )}
    </section>
  );
}

