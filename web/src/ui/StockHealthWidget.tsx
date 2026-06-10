import { useEffect, useMemo, useState } from "react";
import { databases, DATABASE_ID, COLLECTIONS, Query } from "@/lib/supabase";
import { toMillis } from "@/lib/timestamp";
import { useNavigate } from "react-router-dom";
import { formatMoney } from "@/lib/money";
import type { InventoryItem } from "@/lib/types";

type Row = InventoryItem & { $id: string };

type Props = {
  uid: string;
  /** Dados de estoque já carregados — evita query duplicada quando passados pelo Dashboard */
  items?: Row[];
};

export default function StockHealthWidget({ uid, items: itemsProp }: Props) {
  const [items, setItems] = useState<Row[]>(itemsProp ?? []);
  const [loading, setLoading] = useState(!itemsProp);
  const navigate = useNavigate();

  useEffect(() => {
    // Se os dados foram passados como prop, não faz query própria
    if (itemsProp !== undefined) {
      setItems(itemsProp);
      setLoading(false);
      return;
    }
    async function load() {
      setLoading(true);
      const res = await databases.listDocuments(DATABASE_ID, COLLECTIONS.INVENTORY, [
        Query.equal("userId", uid),
        Query.orderAsc("expiryDate"),
        Query.limit(1000),
      ]);
      setItems(res.documents.map(d => ({ $id: d.$id, ...(d as unknown as InventoryItem) })));
      setLoading(false);
    }
    load().catch(() => setLoading(false));
  }, [uid, itemsProp]);

  const stats = useMemo(() => {
    const now = Date.now();
    const thirty = now + 30 * 24 * 60 * 60 * 1000;
    const sixty = now + 60 * 24 * 60 * 60 * 1000;
    const ninety = now + 90 * 24 * 60 * 60 * 1000;

    let totalQty = 0;
    let totalValue = 0;
    let exp90Qty = 0;
    const critical: Row[] = [];   // < 30 dias
    const warning: Row[] = [];    // 30–60 dias
    const caution: Row[] = [];    // 60–90 dias
    const expired: Row[] = [];    // já vencidos

    for (const it of items) {
      const qty = Number(it.quantity ?? 0);
      if (qty <= 0) continue;
      totalQty += qty;
      totalValue += (it.sellingPriceCents ?? 0) * qty;

      const ms = toMillis(it.expiryDate);
      if (!ms) continue;

      if (ms < now) { expired.push(it); continue; }
      if (ms <= thirty) { critical.push(it); exp90Qty += qty; }
      else if (ms <= sixty) { warning.push(it); exp90Qty += qty; }
      else if (ms <= ninety) { caution.push(it); exp90Qty += qty; }
    }

    const pct = totalQty > 0 ? Math.round((exp90Qty / totalQty) * 100) : 0;
    return { totalQty, totalValue, pct, critical, warning, caution, expired };
  }, [items]);

  if (loading) return (
    <div className="card-brand p-5">
      <div className="text-sm text-gray-400">Carregando estoque…</div>
    </div>
  );

  return (
    <div className="space-y-4">
      {/* Alertas críticos */}
      {stats.expired.length > 0 && (
        <div className="rounded-2xl bg-red-50 border border-red-200 p-4">
          <div className="flex items-center gap-2 mb-2">
            <span className="text-lg">🚨</span>
            <span className="text-sm font-semibold text-red-800">{stats.expired.length} produto{stats.expired.length !== 1 ? "s" : ""} VENCIDO{stats.expired.length !== 1 ? "S" : ""}</span>
          </div>
          <div className="space-y-1">
            {stats.expired.slice(0, 3).map(it => (
              <div key={it.$id} className="text-xs text-red-700 flex justify-between">
                <span>{it.productName} ({it.brand})</span>
                <span>{it.quantity} un • {formatMoney(it.sellingPriceCents * it.quantity)}</span>
              </div>
            ))}
            {stats.expired.length > 3 && <div className="text-xs text-red-500">+{stats.expired.length - 3} mais…</div>}
          </div>
        </div>
      )}

      {stats.critical.length > 0 && (
        <div className="rounded-2xl bg-orange-50 border border-orange-200 p-4">
          <div className="flex items-center gap-2 mb-2">
            <span className="text-lg">⚠️</span>
            <span className="text-sm font-semibold text-orange-800">Vencem em menos de 30 dias — converta em amostras!</span>
          </div>
          <div className="space-y-1">
            {stats.critical.slice(0, 4).map(it => (
              <div key={it.$id} className="text-xs text-orange-700 flex justify-between">
                <span>{it.productName}</span>
                <span>{it.quantity} un • {formatMoney(it.sellingPriceCents * it.quantity)}</span>
              </div>
            ))}
          </div>
          <div className="mt-2 text-xs text-orange-600 bg-orange-100 rounded-lg p-2">
            💡 <strong>Dica:</strong> Transforme esses itens em amostras de demonstração para atrair novas vendas e evitar perda total.
          </div>
        </div>
      )}

      {/* Widget principal */}
      <div className="card-brand p-5">
        <div className="flex items-center justify-between mb-4">
          <div>
            <h2 className="text-base font-semibold text-gray-800">Saúde do Estoque</h2>
            <p className="text-xs text-gray-500 mt-0.5">Método FEFO — prioridade por vencimento</p>
          </div>
          <div className="text-right">
            <div className="text-2xl font-bold text-gray-900">{formatMoney(stats.totalValue)}</div>
            <div className="text-xs text-gray-500">valor total em estoque</div>
          </div>
        </div>

        {/* Barra de saúde */}
        <div className="mb-4">
          <div className="flex justify-between text-xs text-gray-500 mb-1">
            <span>{stats.pct}% vence em 90 dias</span>
            <span>{stats.totalQty} unidades</span>
          </div>
          <div className="h-3 rounded-full bg-slate-100 overflow-hidden">
            <div
              className={`h-full rounded-full transition-all ${
                stats.pct > 50 ? "bg-red-500" : stats.pct > 25 ? "bg-orange-400" : "bg-teal-500"
              }`}
              style={{ width: `${Math.min(stats.pct, 100)}%` }}
            />
          </div>
        </div>

        {/* Grid de alertas — clicáveis */}
        <div className="grid grid-cols-3 gap-3">
          <AlertBadge
            count={stats.critical.length}
            label="< 30 dias"
            sublabel="crítico"
            color="red"
            onClick={() => navigate("/inventory?expiry=30")}
          />
          <AlertBadge
            count={stats.warning.length}
            label="30–60 dias"
            sublabel="atenção"
            color="orange"
            onClick={() => navigate("/inventory?expiry=60")}
          />
          <AlertBadge
            count={stats.caution.length}
            label="60–90 dias"
            sublabel="alerta"
            color="yellow"
            onClick={() => navigate("/inventory?expiry=90")}
          />
        </div>

        {/* Lista FEFO */}
        {(stats.critical.length > 0 || stats.warning.length > 0) && (
          <div className="mt-4 border-t pt-3">
            <div className="text-xs font-medium text-gray-600 mb-2">Prioridade de venda (FEFO):</div>
            <div className="space-y-1.5">
              {[...stats.critical, ...stats.warning].slice(0, 6).map(it => {
                const ms = toMillis(it.expiryDate);
                const days = Math.ceil((ms - Date.now()) / (24 * 60 * 60 * 1000));
                const isCritical = days <= 30;
                return (
                  <div key={it.$id} className={`flex items-center justify-between text-xs rounded-lg px-3 py-2 ${isCritical ? "bg-red-50" : "bg-orange-50"}`}>
                    <span className={`font-medium ${isCritical ? "text-red-800" : "text-orange-800"}`}>{it.productName}</span>
                    <div className="flex items-center gap-2">
                      <span className="text-gray-500">{it.quantity} un</span>
                      <span className={`font-semibold ${isCritical ? "text-red-700" : "text-orange-700"}`}>{days}d</span>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

function AlertBadge({
  count, label, sublabel, color, onClick,
}: {
  count: number;
  label: string;
  sublabel: string;
  color: "red" | "orange" | "yellow";
  onClick: () => void;
}) {
  const colors = {
    red:    "bg-red-50 border-red-200 text-red-700 hover:bg-red-100 active:bg-red-200",
    orange: "bg-orange-50 border-orange-200 text-orange-700 hover:bg-orange-100 active:bg-orange-200",
    yellow: "bg-yellow-50 border-yellow-200 text-yellow-700 hover:bg-yellow-100 active:bg-yellow-200",
  };
  return (
    <button
      onClick={onClick}
      className={`rounded-xl border p-3 text-center transition-colors w-full ${colors[color]} ${count > 0 ? "cursor-pointer" : "opacity-60 cursor-default"}`}
      disabled={count === 0}
      title={count > 0 ? `Ver ${count} produto${count !== 1 ? "s" : ""} que vencem em ${label}` : "Nenhum produto nesta faixa"}
    >
      <div className="text-xl font-bold">{count}</div>
      <div className="text-xs mt-0.5 font-medium">{label}</div>
      {count > 0 && (
        <div className="text-xs mt-0.5 opacity-70">ver →</div>
      )}
    </button>
  );
}

