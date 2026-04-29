/**
 * Página de Comissão por Marca
 * Mostra quanto a revendedora ganhou de comissão por marca no período
 * e uma calculadora interativa de preço/comissão.
 * Usa as margens configuradas pela usuária em Configurações.
 */
import { useEffect, useState } from "react";
import type { User } from "firebase/auth";
import {
  collection, getDocs, query, orderBy, where,
  Timestamp, doc, getDoc
} from "firebase/firestore";
import DashboardLayout from "@/ui/DashboardLayout";
import { db } from "@/lib/firebase";
import { formatMoney, toCents } from "@/lib/money";
import { getConfiguredMargin, calculatePriceFromConfigured } from "@/lib/margins";
import type { Sale, SaleItem, UserProfile, BrandMargin } from "@/lib/types";

const DEFAULT_BRANDS: BrandMargin[] = [
  { brand: "Natura", marginPercent: 30 },
  { brand: "Avon", marginPercent: 30 },
  { brand: "Casa & Estilo", marginPercent: 15 },
];

type BrandSummary = {
  brand: string;
  revenue: number;
  cost: number;
  commission: number;
  salesCount: number;
  marginPct: number;
};

type Period = "month" | "last30" | "all";

export default function CommissionPage({ user }: { user: User }) {
  const [brandMargins, setBrandMargins] = useState<BrandMargin[]>(DEFAULT_BRANDS);
  const [summaries, setSummaries] = useState<BrandSummary[]>([]);
  const [loading, setLoading] = useState(true);
  const [period, setPeriod] = useState<Period>("month");

  // Calculadora
  const [calcBrand, setCalcBrand] = useState("");
  const [calcCost, setCalcCost] = useState("");
  const [calcSelling, setCalcSelling] = useState("");
  const [calcMode, setCalcMode] = useState<"fromCost" | "fromSelling">("fromCost");

  useEffect(() => {
    async function load() {
      setLoading(true);

      // Carregar margens configuradas
      const profileSnap = await getDoc(doc(db, "users", user.uid));
      const margins: BrandMargin[] = profileSnap.exists()
        ? ((profileSnap.data() as UserProfile).brandMargins ?? DEFAULT_BRANDS)
        : DEFAULT_BRANDS;
      setBrandMargins(margins);
      if (!calcBrand && margins.length > 0) setCalcBrand(margins[0].brand);

      // Período
      const now = new Date();
      let startDate: Date;
      if (period === "month") {
        startDate = new Date(now.getFullYear(), now.getMonth(), 1);
      } else if (period === "last30") {
        startDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
      } else {
        startDate = new Date(2020, 0, 1);
      }

      const q = query(
        collection(db, "users", user.uid, "sales"),
        where("createdAt", ">=", Timestamp.fromDate(startDate)),
        orderBy("createdAt", "desc")
      );

      // Carregar TODO o inventário (incluindo zerados) para resolver marca de itens antigos
      const invSnap = await getDocs(collection(db, "users", user.uid, "inventory"));
      const invById = new Map<string, string>();   // inventoryId → brand
      const invByName = new Map<string, string>(); // productName.lower → brand
      invSnap.docs.forEach(d => {
        const data = d.data() as { brand?: string; productName?: string };
        if (data.brand) {
          invById.set(d.id, data.brand);
          if (data.productName) invByName.set(data.productName.toLowerCase(), data.brand);
        }
      });

      const snap = await getDocs(q);

      // Agrupar por marca
      const map = new Map<string, BrandSummary>();

      for (const d of snap.docs) {
        const sale = d.data() as Sale;
        for (const item of (sale.items ?? []) as SaleItem[]) {
          // 1º: campo brand no item (vendas novas)
          // 2º: busca pelo inventoryId (vendas antigas com estoque ainda existente)
          // 3º: busca pelo productId (mesmo que inventoryId no seed)
          // 4º: busca pelo productName (fallback para itens deletados do estoque)
          // 5º: "Outra" como último recurso
          const brand =
            (item as any).brand ||
            (item.inventoryId ? invById.get(item.inventoryId) : undefined) ||
            (item.productId ? invById.get(item.productId) : undefined) ||
            (item.productName ? invByName.get(item.productName.toLowerCase()) : undefined) ||
            "Outra";

          if (!map.has(brand)) {
            map.set(brand, {
              brand,
              revenue: 0,
              cost: 0,
              commission: 0,
              salesCount: 0,
              marginPct: getConfiguredMargin(brand, margins),
            });
          }
          const s = map.get(brand)!;
          const rev = (item.unitPriceCents ?? 0) * (item.quantity ?? 0);
          const cost = (item.unitCostCents ?? 0) * (item.quantity ?? 0);
          s.revenue += rev;
          s.cost += cost;
          s.commission += rev - cost;
          s.salesCount++;
        }
      }

      // Fallback sem marca
      if (map.size === 0 && snap.size > 0) {
        let totalRev = 0, totalCost = 0;
        for (const d of snap.docs) {
          const sale = d.data() as Sale;
          totalRev += sale.totalCents ?? 0;
          totalCost += (sale.items ?? []).reduce((s: number, i: any) =>
            s + (i.unitCostCents ?? 0) * (i.quantity ?? 0), 0);
        }
        map.set("Geral", {
          brand: "Geral",
          revenue: totalRev,
          cost: totalCost,
          commission: totalRev - totalCost,
          salesCount: snap.size,
          marginPct: getConfiguredMargin("Natura", margins),
        });
      }

      setSummaries(Array.from(map.values()).sort((a, b) => b.commission - a.commission));
      setLoading(false);
    }
    load().catch(() => setLoading(false));
  }, [user.uid, period]);

  // Calculadora
  const activeBrand = calcBrand || (brandMargins[0]?.brand ?? "");
  const calcCostCents = toCents(calcCost);
  const calcSellingCents = toCents(calcSelling);
  const suggestedPrice = calcCostCents > 0
    ? calculatePriceFromConfigured(calcCostCents, activeBrand, brandMargins)
    : 0;
  const calcCommission = calcMode === "fromCost"
    ? suggestedPrice - calcCostCents
    : calcSellingCents - calcCostCents;
  const calcMargin = calcMode === "fromCost"
    ? getConfiguredMargin(activeBrand, brandMargins)
    : calcSellingCents > 0
      ? Math.round(((calcSellingCents - calcCostCents) / calcSellingCents) * 100)
      : 0;

  const totalCommission = summaries.reduce((s, b) => s + b.commission, 0);
  const totalRevenue = summaries.reduce((s, b) => s + b.revenue, 0);
  const periodLabel = period === "month" ? "Este mês" : period === "last30" ? "Últimos 30 dias" : "Todo período";

  return (
    <DashboardLayout title="Comissão & Ganhos">
      <div className="space-y-6">

        {/* Header com total */}
        <div className="rounded-2xl border border-teal-200 bg-teal-50 p-4 flex items-center justify-between">
          <div>
            <div className="text-xs font-medium text-teal-600">Comissão total</div>
            <div className="text-3xl font-bold text-teal-700">{formatMoney(totalCommission)}</div>
            <div className="text-xs text-teal-500 mt-0.5">{periodLabel}</div>
          </div>
          <div className="text-right">
            <div className="text-xs text-teal-600">Faturamento</div>
            <div className="text-xl font-semibold text-teal-700">{formatMoney(totalRevenue)}</div>
            <div className="text-xs text-teal-500 mt-0.5">
              {totalRevenue > 0 ? ((totalCommission / totalRevenue) * 100).toFixed(1) : "0"}% de margem
            </div>
          </div>
        </div>

        {/* Filtro de período */}
        <div className="flex gap-2">
          {(["month", "last30", "all"] as Period[]).map(p => (
            <button
              key={p}
              onClick={() => setPeriod(p)}
              className={`px-4 py-2 rounded-xl text-sm font-medium transition-colors border ${
                period === p
                  ? "bg-teal-600 text-white border-teal-600"
                  : "bg-white text-gray-600 border-slate-200 hover:border-teal-300"
              }`}
            >
              {p === "month" ? "Este mês" : p === "last30" ? "30 dias" : "Tudo"}
            </button>
          ))}
        </div>

        {/* Comissão por marca */}
        <div className="rounded-2xl bg-white border border-slate-100 shadow-sm overflow-hidden">
          <div className="px-5 py-4 border-b bg-slate-50">
            <h2 className="text-base font-semibold text-gray-800">Comissão por Marca</h2>
            <p className="text-xs text-gray-500 mt-0.5">Quanto você ganhou de cada marca no período</p>
          </div>

          {loading ? (
            <div className="p-8 text-center text-sm text-gray-400">Calculando…</div>
          ) : summaries.length === 0 ? (
            <div className="p-8 text-center text-sm text-gray-400">
              Nenhuma venda registrada no período.<br />
              <span className="text-xs">Registre vendas para ver sua comissão aqui.</span>
            </div>
          ) : (
            <div className="divide-y divide-slate-50">
              {summaries.map(b => {
                const pct = totalRevenue > 0 ? (b.revenue / totalRevenue) * 100 : 0;
                return (
                  <div key={b.brand} className="px-5 py-4">
                    <div className="flex items-center justify-between mb-2">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-xl bg-teal-100 flex items-center justify-center text-teal-700 font-bold text-sm">
                          {b.brand.charAt(0)}
                        </div>
                        <div>
                          <div className="font-semibold text-gray-900">{b.brand}</div>
                          <div className="text-xs text-gray-500">
                            {b.salesCount} item{b.salesCount !== 1 ? "s" : ""} vendido{b.salesCount !== 1 ? "s" : ""} •
                            margem {b.marginPct}%
                          </div>
                        </div>
                      </div>
                      <div className="text-right">
                        <div className="text-lg font-bold text-green-700">{formatMoney(b.commission)}</div>
                        <div className="text-xs text-gray-500">de {formatMoney(b.revenue)}</div>
                      </div>
                    </div>
                    <div className="h-2 rounded-full bg-slate-100 overflow-hidden">
                      <div
                        className="h-full rounded-full bg-teal-500 transition-all"
                        style={{ width: `${Math.min(pct, 100)}%` }}
                      />
                    </div>
                    <div className="flex justify-between text-xs text-gray-400 mt-1">
                      <span>Custo: {formatMoney(b.cost)}</span>
                      <span>{pct.toFixed(0)}% do faturamento total</span>
                    </div>
                  </div>
                );
              })}
            </div>
          )}

          {summaries.length > 0 && (
            <div className="px-5 py-4 bg-teal-50 border-t border-teal-100 flex justify-between items-center">
              <div className="text-sm font-semibold text-teal-800">Total de comissões</div>
              <div className="text-xl font-bold text-teal-700">{formatMoney(totalCommission)}</div>
            </div>
          )}
        </div>

        {/* Calculadora de comissão */}
        <div className="rounded-2xl bg-white border border-slate-100 shadow-sm p-5">
          <h2 className="text-base font-semibold text-gray-800 mb-1">Calculadora de Comissão</h2>
          <p className="text-xs text-gray-500 mb-4">
            Digite o preço de custo e veja quanto você vai ganhar
          </p>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="inp-label">Marca</label>
              <select
                className="inp-select"
                value={activeBrand}
                onChange={e => { setCalcBrand(e.target.value); setCalcSelling(""); setCalcMode("fromCost"); }}
              >
                {brandMargins.map(b => <option key={b.brand} value={b.brand}>{b.brand} ({b.marginPercent}%)</option>)}
              </select>
            </div>

            <div>
              <label className="inp-label">Preço de custo (R$)</label>
              <input
                type="number"
                step="0.01"
                min="0"
                placeholder="Ex: 25,00"
                className="inp"
                value={calcCost}
                onChange={e => setCalcCost(e.target.value)}
              />
            </div>

            <div className="sm:col-span-2">
              <label className="inp-label">
                Preço de venda (R$)
                <span className="text-gray-400 font-normal ml-1">— opcional, deixe vazio para usar o sugerido</span>
              </label>
              <input
                type="number"
                step="0.01"
                min="0"
                placeholder="Deixe vazio para calcular automaticamente"
                className="inp"
                value={calcSelling}
                onChange={e => {
                  setCalcSelling(e.target.value);
                  setCalcMode(e.target.value ? "fromSelling" : "fromCost");
                }}
              />
            </div>
          </div>

          {/* Resultado */}
          {calcCostCents > 0 && (
            <>
              <div className="mt-4 grid grid-cols-3 gap-3">
                <div className="rounded-xl bg-slate-50 border border-slate-100 p-4 text-center">
                  <div className="text-xs text-gray-500 mb-1">Preço sugerido</div>
                  <div className="text-xl font-bold text-gray-900">{formatMoney(suggestedPrice)}</div>
                  <div className="text-xs text-gray-400 mt-0.5">{activeBrand}</div>
                </div>
                <div className="rounded-xl bg-green-50 border border-green-100 p-4 text-center">
                  <div className="text-xs text-green-600 mb-1">Sua comissão</div>
                  <div className="text-xl font-bold text-green-700">
                    {formatMoney(calcCommission > 0 ? calcCommission : 0)}
                  </div>
                  <div className="text-xs text-green-500 mt-0.5">{calcMargin}% de margem</div>
                </div>
                <div className="rounded-xl bg-blue-50 border border-blue-100 p-4 text-center">
                  <div className="text-xs text-blue-600 mb-1">Custo</div>
                  <div className="text-xl font-bold text-blue-700">{formatMoney(calcCostCents)}</div>
                  <div className="text-xs text-blue-400 mt-0.5">você pagou</div>
                </div>
              </div>

              <div className="mt-3 rounded-xl bg-teal-50 border border-teal-100 p-3 text-xs text-teal-700">
                💡 Vendendo <strong>{activeBrand}</strong> com {calcMargin}% de margem:
                para cada <strong>{formatMoney(calcCostCents)}</strong> investido,
                você recebe <strong>{formatMoney(calcCommission > 0 ? calcCommission : 0)}</strong> de comissão.
              </div>
            </>
          )}
        </div>

      </div>
    </DashboardLayout>
  );
}
