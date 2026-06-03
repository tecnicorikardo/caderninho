/**
 * Pagina de Comissao por Marca e por Venda
 * Mostra quanto a revendedora ganhou de comissao por marca no periodo
 * e uma lista detalhada de comissao por venda individual.
 * Usa as margens configuradas pela usuaria em Configuracoes.
 */
import { useEffect, useState } from "react";
import type { AppUser } from "@/App";
import { databases, DATABASE_ID, COLLECTIONS, Query } from "@/lib/appwrite";
import DashboardLayout from "@/ui/DashboardLayout";
import { formatMoney, toCents } from "@/lib/money";
import { getConfiguredMargin, calculatePriceFromConfigured } from "@/lib/margins";
import { calculateBrandCommissionCents, calculateItemEarnings } from "@/lib/profit";
import { toDate } from "@/lib/timestamp";
import type { Sale, SaleItem, BrandMargin } from "@/lib/types";

const DEFAULT_BRANDS: BrandMargin[] = [
  { brand: "Natura", marginPercent: 30 },
  { brand: "Avon", marginPercent: 30 },
  { brand: "Casa & Estilo", marginPercent: 15 },
];

type BrandSummary = {
  brand: string;
  revenue: number;
  cost: number;
  grossProfit: number;
  commission: number;
  profit: number;
  salesCount: number;
  marginPct: number;
};

type SaleWithCommission = {
  $id: string;
  date: string;
  customerName: string;
  items: SaleItem[];
  totalCents: number;
  costCents: number;
  grossProfitCents: number;
  brandCommissionCents: number;
  profitCents: number;
  paymentType: string;
};

type Period = "month" | "last30" | "all" | "custom";
type Tab = "brand" | "sales" | "calc";

const MONTH_NAMES = ["Jan","Fev","Mar","Abr","Mai","Jun","Jul","Ago","Set","Out","Nov","Dez"];

const PAYMENT_LABELS: Record<string, string> = {
  cash: "Dinheiro", pix: "PIX", card: "Cartão",
  fiado: "Fiado", installments: "Parcelado",
};

export default function CommissionPage({ user }: { user: AppUser }) {
  const [brandMargins, setBrandMargins] = useState<BrandMargin[]>(DEFAULT_BRANDS);
  const [summaries, setSummaries] = useState<BrandSummary[]>([]);
  const [salesList, setSalesList] = useState<SaleWithCommission[]>([]);
  const [loading, setLoading] = useState(true);
  const [period, setPeriod] = useState<Period>("month");
  const [tab, setTab] = useState<Tab>("sales");
  const [expandedSale, setExpandedSale] = useState<string | null>(null);

  const now = new Date();
  const [customMonth, setCustomMonth] = useState(now.getMonth());
  const [customYear, setCustomYear] = useState(now.getFullYear());

  // Calculadora
  const [calcBrand, setCalcBrand] = useState("");
  const [calcCost, setCalcCost] = useState("");
  const [calcSelling, setCalcSelling] = useState("");
  const [calcMode, setCalcMode] = useState<"fromCost" | "fromSelling">("fromCost");

  const availableYears = Array.from({ length: 5 }, (_, i) => now.getFullYear() - i);

  useEffect(() => {
    async function load() {
      setLoading(true);

      const profileRes = await databases.listDocuments(DATABASE_ID, COLLECTIONS.PROFILES, [
        Query.equal("userId", user.uid),
        Query.limit(1),
      ]);
      const margins: BrandMargin[] = profileRes.documents.length > 0
        ? (profileRes.documents[0].brandMargins
            ? JSON.parse(profileRes.documents[0].brandMargins as string)
            : DEFAULT_BRANDS)
        : DEFAULT_BRANDS;
      setBrandMargins(margins);
      if (!calcBrand && margins.length > 0) setCalcBrand(margins[0].brand);

      const now = new Date();
      let startDate: Date;
      let endDate: Date | null = null;

      if (period === "month") {
        startDate = new Date(now.getFullYear(), now.getMonth(), 1);
      } else if (period === "last30") {
        startDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
      } else if (period === "custom") {
        startDate = new Date(customYear, customMonth, 1);
        endDate = new Date(customYear, customMonth + 1, 0, 23, 59, 59);
      } else {
        startDate = new Date(2020, 0, 1);
      }

      const salesQueries = [
        Query.equal("userId", user.uid),
        Query.greaterThanEqual("createdAt", startDate.toISOString()),
        Query.orderDesc("createdAt"),
        Query.limit(1000),
        ...(endDate ? [Query.lessThanEqual("createdAt", endDate.toISOString())] : []),
      ];

      const invRes = await databases.listDocuments(DATABASE_ID, COLLECTIONS.INVENTORY, [
        Query.equal("userId", user.uid),
        Query.limit(1000),
      ]);
      const invById = new Map<string, string>();
      const invByName = new Map<string, string>();
      invRes.documents.forEach(d => {
        const data = d as unknown as { brand?: string; productName?: string };
        if (data.brand) {
          invById.set(d.$id, data.brand);
          if (data.productName) invByName.set(data.productName.toLowerCase(), data.brand);
        }
      });

      // Buscar clientes para mostrar nome na lista por venda
      const custRes = await databases.listDocuments(DATABASE_ID, COLLECTIONS.CUSTOMERS, [
        Query.equal("userId", user.uid),
        Query.limit(1000),
      ]);
      const custById = new Map<string, string>();
      custRes.documents.forEach(d => custById.set(d.$id, (d as any).name || "Cliente"));

      const salesRes = await databases.listDocuments(DATABASE_ID, COLLECTIONS.SALES, salesQueries);

      const map = new Map<string, BrandSummary>();
      const salesWithComm: SaleWithCommission[] = [];

      for (const d of salesRes.documents) {
        const sale = d as unknown as Sale & { $id: string; createdAt: string; paymentType: string };
        const items: SaleItem[] = typeof sale.items === "string" ? JSON.parse(sale.items || "[]") : (sale.items ?? []);

        let saleCost = 0;
        let saleRevenue = 0;
        let saleGrossProfit = 0;
        let saleBrandCommission = 0;

        for (const item of items) {
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
              grossProfit: 0,
              commission: 0,
              profit: 0,
              salesCount: 0,
              marginPct: getConfiguredMargin(brand, margins),
            });
          }
          const s = map.get(brand)!;
          const rev = (item.unitPriceCents ?? 0) * (item.quantity ?? 0);
          const cost = (item.unitCostCents ?? 0) * (item.quantity ?? 0);
          const grossProfit = rev - cost; // lucro real = comissao real
          s.revenue    += rev;
          s.cost       += cost;
          s.grossProfit += grossProfit;
          s.commission  += grossProfit;   // comissao = lucro bruto
          s.profit      += grossProfit;
          s.salesCount++;

          saleRevenue      += rev;
          saleCost         += cost;
          saleGrossProfit  += grossProfit;
          saleBrandCommission += grossProfit;
        }

        salesWithComm.push({
          $id: d.$id,
          date: sale.createdAt ? toDate(sale.createdAt).toLocaleDateString("pt-BR") : "—",
          customerName: custById.get(sale.customerId) || "Cliente",
          items,
          totalCents: sale.totalCents ?? saleRevenue,
          costCents: saleCost,
          grossProfitCents: saleGrossProfit,
          brandCommissionCents: saleGrossProfit,  // comissao = lucro bruto
          profitCents: saleGrossProfit,
          paymentType: sale.paymentType || "cash",
        });
      }

      if (map.size === 0 && salesRes.total > 0) {
        let totalRev = 0, totalCost = 0;
        for (const d of salesRes.documents) {
          const sale = d as unknown as Sale;
          const items = typeof sale.items === "string" ? JSON.parse(sale.items || "[]") : (sale.items ?? []);
          totalRev += sale.totalCents ?? 0;
          totalCost += items.reduce((s: number, i: any) =>
            s + (i.unitCostCents ?? 0) * (i.quantity ?? 0), 0);
        }
        const grossProfit = totalRev - totalCost;
        map.set("Geral", {
          brand: "Geral",
          revenue: totalRev,
          cost: totalCost,
          grossProfit,
          commission: grossProfit,
          profit: grossProfit,
          salesCount: salesRes.total,
          marginPct: getConfiguredMargin("Natura", margins),
        });
      }

      setSummaries(Array.from(map.values()).sort((a, b) => b.profit - a.profit));
      setSalesList(salesWithComm);
      setLoading(false);
    }
    load().catch(() => setLoading(false));
  }, [user.uid, period, customMonth, customYear]);

  const activeBrand = calcBrand || (brandMargins[0]?.brand ?? "");
  const calcCostCents = toCents(calcCost);
  const calcSellingCents = toCents(calcSelling);
  const suggestedPrice = calcCostCents > 0
    ? calculatePriceFromConfigured(calcCostCents, activeBrand, brandMargins)
    : 0;
  const calcCommissionPct = getConfiguredMargin(activeBrand, brandMargins);
  const calcCommission = calcMode === "fromCost"
    ? calculateBrandCommissionCents(suggestedPrice, calcCommissionPct)
    : calculateBrandCommissionCents(calcSellingCents, calcCommissionPct);
  const calcGrossProfit = calcMode === "fromCost"
    ? suggestedPrice - calcCostCents
    : calcSellingCents - calcCostCents;
  const calcProfit = calcGrossProfit + calcCommission;

  const totalCommission = summaries.reduce((s, b) => s + b.commission, 0);
  const totalProfit = summaries.reduce((s, b) => s + b.profit, 0);
  const totalRevenue = summaries.reduce((s, b) => s + b.revenue, 0);
  const periodLabel = period === "month" ? "Este mes"
    : period === "last30" ? "Ultimos 30 dias"
    : period === "custom" ? `${MONTH_NAMES[customMonth]}/${customYear}`
    : "Todo periodo";

  return (
    <DashboardLayout title="Comissao e Ganhos">
      <div className="space-y-6 animate-fade-in">

        {/* Header com total */}
        <div className="rounded-2xl border border-teal-200 bg-teal-50 p-4 flex items-center justify-between">
          <div>
            <div className="text-xs font-medium text-teal-600">Lucro total</div>
            <div className="text-3xl font-bold text-teal-700">{formatMoney(totalProfit)}</div>
            <div className="text-xs text-teal-500 mt-0.5">{periodLabel}</div>
            <div className="text-xs text-teal-600 mt-1">Inclui {formatMoney(totalCommission)} de comissao</div>
          </div>
          <div className="text-right">
            <div className="text-xs text-teal-600">Faturamento</div>
            <div className="text-xl font-semibold text-teal-700">{formatMoney(totalRevenue)}</div>
            <div className="text-xs text-teal-500 mt-0.5">
              {totalRevenue > 0 ? ((totalProfit / totalRevenue) * 100).toFixed(1) : "0"}% de lucro
            </div>
          </div>
        </div>

        {/* Filtro de periodo */}
        <div className="space-y-3">
          <div className="flex flex-wrap gap-2">
            {(["month", "last30", "all"] as Period[]).map(p => (
              <button key={p} onClick={() => setPeriod(p)}
                className={`px-4 py-2 rounded-xl text-sm font-medium transition-all duration-200 border ${period === p ? "bg-teal-600 text-white border-teal-600 shadow-sm" : "bg-white text-gray-600 border-slate-200 hover:border-teal-400 hover:text-teal-700"}`}>
                {p === "month" ? "Este mes" : p === "last30" ? "30 dias" : "Tudo"}
              </button>
            ))}
            <button onClick={() => setPeriod("custom")}
              className={`px-4 py-2 rounded-xl text-sm font-medium transition-all duration-200 border ${period === "custom" ? "bg-teal-600 text-white border-teal-600 shadow-sm" : "bg-white text-gray-600 border-slate-200 hover:border-teal-400 hover:text-teal-700"}`}>
              Escolher mes
            </button>
          </div>
          {period === "custom" && (
            <div className="flex items-center gap-3 p-4 rounded-2xl bg-teal-50 border border-teal-100">
              <span className="text-sm font-medium text-teal-700">Mes:</span>
              <select className="rounded-xl border border-teal-200 bg-white px-3 py-2 text-sm" value={customMonth} onChange={e => setCustomMonth(Number(e.target.value))}>
                {MONTH_NAMES.map((m, i) => <option key={i} value={i}>{m}</option>)}
              </select>
              <select className="rounded-xl border border-teal-200 bg-white px-3 py-2 text-sm" value={customYear} onChange={e => setCustomYear(Number(e.target.value))}>
                {availableYears.map(y => <option key={y} value={y}>{y}</option>)}
              </select>
            </div>
          )}
        </div>

        {/* Abas */}
        <div className="flex gap-1 bg-slate-100 rounded-2xl p-1">
          {([{ key: "sales", label: "💰 Por Venda" }, { key: "brand", label: "🏷️ Por Marca" }, { key: "calc", label: "🧮 Calculadora" }] as { key: Tab; label: string }[]).map(t => (
            <button key={t.key} onClick={() => setTab(t.key)}
              className={`flex-1 py-2 rounded-xl text-sm font-medium transition-all ${tab === t.key ? "bg-white text-teal-700 shadow-sm" : "text-gray-500 hover:text-gray-700"}`}>
              {t.label}
            </button>
          ))}
        </div>

        {/* ABA: Por Venda */}
        {tab === "sales" && <div className="card-brand overflow-hidden">
          <div className="px-5 py-4 border-b bg-slate-50 flex items-center justify-between">
            <div>
              <h2 className="text-base font-semibold text-gray-800">Comissao por Venda</h2>
              <p className="text-xs text-gray-500 mt-0.5">Cada venda com detalhes e lucro</p>
            </div>
            <div className="text-sm font-semibold text-teal-700">{salesList.length} venda{salesList.length !== 1 ? "s" : ""}</div>
          </div>
          {loading ? <div className="p-8 text-center text-sm text-gray-400">Carregando...</div>
          : salesList.length === 0 ? <div className="p-8 text-center text-sm text-gray-400">Nenhuma venda no periodo.</div>
          : <div className="divide-y divide-slate-100">
            {salesList.map(sale => {
              const isExpanded = expandedSale === sale.$id;
              const marginPct = sale.totalCents > 0 ? ((sale.profitCents / sale.totalCents) * 100).toFixed(1) : "0";
              return (
                <div key={sale.$id}>
                  <button onClick={() => setExpandedSale(isExpanded ? null : sale.$id)}
                    className="w-full px-5 py-4 flex items-center gap-4 hover:bg-slate-50 transition-colors text-left">
                    <div className="w-10 h-10 rounded-xl bg-green-100 flex items-center justify-center text-green-700 font-bold text-sm flex-shrink-0">💰</div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 flex-wrap">
                        <span className="font-semibold text-gray-900">{sale.customerName}</span>
                        <span className="text-xs bg-slate-100 text-slate-600 px-2 py-0.5 rounded-full">{PAYMENT_LABELS[sale.paymentType] || sale.paymentType}</span>
                      </div>
                      <div className="text-xs text-gray-500 mt-0.5">{sale.date} &bull; {sale.items.length} item{sale.items.length !== 1 ? "s" : ""}</div>
                    </div>
                    <div className="text-right flex-shrink-0">
                      <div className="text-base font-bold text-green-700">+{formatMoney(sale.profitCents)}</div>
                      <div className="text-xs text-gray-400">{marginPct}% de {formatMoney(sale.totalCents)}</div>
                    </div>
                    <div className={`text-gray-400 transition-transform ${isExpanded ? "rotate-180" : ""}`}>▾</div>
                  </button>
                  {isExpanded && (
                    <div className="px-5 pb-4 bg-slate-50 border-t border-slate-100">
                      <div className="mt-3 space-y-2">
                        <div className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-2">Produtos</div>
                        {sale.items.map((item, i) => {
                          const itemRev = (item.unitPriceCents ?? 0) * (item.quantity ?? 0);
                          const itemCost = (item.unitCostCents ?? 0) * (item.quantity ?? 0);
                          const itemEarnings = calculateItemEarnings(item, brandMargins);
                          return (
                            <div key={i} className="flex items-center gap-3 bg-white rounded-xl px-4 py-3 border border-slate-100">
                              <div className="flex-1 min-w-0">
                                <div className="text-sm font-medium text-gray-800 truncate">{item.productName}</div>
                                <div className="text-xs text-gray-500">{item.brand} &bull; {item.quantity}x &bull; {formatMoney(item.unitPriceCents ?? 0)}/un</div>
                              </div>
                              <div className="text-right flex-shrink-0 space-y-0.5">
                                <div className="text-sm font-semibold text-gray-800">{formatMoney(itemRev)}</div>
                                <div className="text-xs text-gray-400">custo {formatMoney(itemCost)}</div>
                                <div className="text-xs text-teal-600">comissao {formatMoney(itemEarnings.commissionCents)}</div>
                                <div className="text-xs font-semibold text-green-600">lucro {formatMoney(itemEarnings.profitCents)}</div>
                              </div>
                            </div>
                          );
                        })}
                        <div className="mt-3 rounded-xl bg-white border border-slate-200 px-4 py-3 grid grid-cols-2 sm:grid-cols-4 gap-3 text-center">
                          <div><div className="text-xs text-gray-500">Total venda</div><div className="text-sm font-bold text-gray-800">{formatMoney(sale.totalCents)}</div></div>
                          <div><div className="text-xs text-gray-500">Custo</div><div className="text-sm font-bold text-gray-600">{formatMoney(sale.costCents)}</div></div>
                          <div><div className="text-xs text-teal-600">Comissao</div><div className="text-sm font-bold text-teal-700">{formatMoney(sale.brandCommissionCents)}</div></div>
                          <div><div className="text-xs text-green-600">Lucro total</div><div className="text-sm font-bold text-green-700">{formatMoney(sale.profitCents)}</div></div>
                        </div>
                      </div>
                    </div>
                  )}
                </div>
              );
            })}
          </div>}
          {salesList.length > 0 && (
            <div className="px-5 py-4 bg-teal-50 border-t border-teal-100 flex justify-between items-center">
              <div className="text-sm font-semibold text-teal-800">Lucro total</div>
              <div className="text-xl font-bold text-teal-700">{formatMoney(totalProfit)}</div>
            </div>
          )}
        </div>}

        {/* ABA: Por Marca */}
        {tab === "brand" && <div className="card-brand overflow-hidden">
          <div className="px-5 py-4 border-b bg-slate-50">
            <h2 className="text-base font-semibold text-gray-800">Comissao por Marca</h2>
            <p className="text-xs text-gray-500 mt-0.5">Quanto voce ganhou de cada marca no periodo</p>
          </div>
          {loading ? <div className="p-8 text-center text-sm text-gray-400">Calculando...</div>
          : summaries.length === 0 ? <div className="p-8 text-center text-sm text-gray-400">Nenhuma venda registrada no periodo.</div>
          : <div className="divide-y divide-slate-50">
            {summaries.map(b => {
              const pct = totalRevenue > 0 ? (b.revenue / totalRevenue) * 100 : 0;
              return (
                <div key={b.brand} className="px-5 py-4">
                  <div className="flex items-center justify-between mb-2">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-xl bg-teal-100 flex items-center justify-center text-teal-700 font-bold text-sm">{b.brand.charAt(0)}</div>
                      <div>
                        <div className="font-semibold text-gray-900">{b.brand}</div>
                        <div className="text-xs text-gray-500">{b.salesCount} item{b.salesCount !== 1 ? "s" : ""} &bull; margem {b.marginPct}%</div>
                      </div>
                    </div>
                    <div className="text-right">
                      <div className="text-lg font-bold text-green-700">{formatMoney(b.profit)}</div>
                      <div className="text-xs text-gray-500">de {formatMoney(b.revenue)}</div>
                    </div>
                  </div>
                  <div className="h-2 rounded-full bg-slate-100 overflow-hidden">
                    <div className="h-full rounded-full bg-teal-500 transition-all" style={{ width: `${Math.min(pct, 100)}%` }} />
                  </div>
                  <div className="flex justify-between text-xs text-gray-400 mt-1">
                    <span>Custo: {formatMoney(b.cost)}</span>
                    <span>Comissao: {formatMoney(b.commission)}</span>
                    <span>Lucro bruto: {formatMoney(b.grossProfit)}</span>
                    <span>{pct.toFixed(0)}% do faturamento</span>
                  </div>
                </div>
              );
            })}
          </div>}
          {summaries.length > 0 && (
            <div className="px-5 py-4 bg-teal-50 border-t border-teal-100 flex justify-between items-center">
              <div className="text-sm font-semibold text-teal-800">Lucro total</div>
              <div className="text-xl font-bold text-teal-700">{formatMoney(totalProfit)}</div>
            </div>
          )}
        </div>}

        {/* ABA: Calculadora */}
        {tab === "calc" && <div className="card-brand p-5">
          <h2 className="text-base font-semibold text-gray-800 mb-1">Calculadora de Comissao</h2>
          <p className="text-xs text-gray-500 mb-4">Digite o preco de custo e veja quanto voce vai ganhar</p>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="inp-label">Marca</label>
              <select className="inp-select" value={activeBrand} onChange={e => { setCalcBrand(e.target.value); setCalcSelling(""); setCalcMode("fromCost"); }}>
                {brandMargins.map(b => <option key={b.brand} value={b.brand}>{b.brand} ({b.marginPercent}%)</option>)}
              </select>
            </div>
            <div>
              <label className="inp-label">Preco de custo (R$)</label>
              <input type="number" step="0.01" min="0" placeholder="Ex: 25,00" className="inp" value={calcCost} onChange={e => setCalcCost(e.target.value)} />
            </div>
            <div className="sm:col-span-2">
              <label className="inp-label">Preco de venda (R$) <span className="text-gray-400 font-normal ml-1">— opcional</span></label>
              <input type="number" step="0.01" min="0" placeholder="Deixe vazio para calcular automaticamente" className="inp" value={calcSelling}
                onChange={e => { setCalcSelling(e.target.value); setCalcMode(e.target.value ? "fromSelling" : "fromCost"); }} />
            </div>
          </div>
          {calcCostCents > 0 && (
            <>
              <div className="mt-4 grid grid-cols-3 gap-3">
                <div className="rounded-xl bg-slate-50 border border-slate-100 p-4 text-center">
                  <div className="text-xs text-gray-500 mb-1">Preco sugerido</div>
                  <div className="text-xl font-bold text-gray-900">{formatMoney(suggestedPrice)}</div>
                  <div className="text-xs text-gray-400 mt-0.5">{activeBrand}</div>
                </div>
                <div className="rounded-xl bg-green-50 border border-green-100 p-4 text-center">
                  <div className="text-xs text-green-600 mb-1">Lucro total</div>
                  <div className="text-xl font-bold text-green-700">{formatMoney(calcProfit > 0 ? calcProfit : 0)}</div>
                  <div className="text-xs text-green-500 mt-0.5">{calcCommissionPct}% de comissao</div>
                </div>
                <div className="rounded-xl bg-blue-50 border border-blue-100 p-4 text-center">
                  <div className="text-xs text-blue-600 mb-1">Custo</div>
                  <div className="text-xl font-bold text-blue-700">{formatMoney(calcCostCents)}</div>
                  <div className="text-xs text-blue-400 mt-0.5">voce pagou</div>
                </div>
              </div>
              <div className="mt-3 rounded-xl bg-teal-50 border border-teal-100 p-3 text-xs text-teal-700">
                Vendendo <strong>{activeBrand}</strong> com {calcCommissionPct}% de comissao: lucro bruto de <strong>{formatMoney(calcGrossProfit > 0 ? calcGrossProfit : 0)}</strong>, mais <strong>{formatMoney(calcCommission > 0 ? calcCommission : 0)}</strong> de comissao.
              </div>
            </>
          )}
        </div>}

      </div>
    </DashboardLayout>
  );
}
