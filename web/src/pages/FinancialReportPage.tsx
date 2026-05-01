/**
 * Página de Relatório Financeiro
 * Mostra se o negócio está lucrando com visão completa de receitas, despesas e lucro
 */
import { useEffect, useState } from "react";
import type { User } from "firebase/auth";
import {
  collection, getDocs, query, where, orderBy,
  Timestamp, doc, getDoc
} from "firebase/firestore";
import DashboardLayout from "@/ui/DashboardLayout";
import { db } from "@/lib/firebase";
import { formatMoney } from "@/lib/money";
import type { Sale, Receivable, Customer, UserProfile, GrowthLevel } from "@/lib/types";
import { getMarginPercent } from "@/lib/margins";

type Period = "month" | "last30" | "quarter" | "year" | "all";

type FinancialSummary = {
  period: string;
  revenue: number;
  cost: number;
  grossProfit: number;
  grossMargin: number;
  receivablesCollected: number;
  outstandingReceivables: number;
  salesCount: number;
  avgSaleValue: number;
  topProducts: Array<{ name: string; revenue: number; quantity: number }>;
  topCustomers: Array<{ name: string; revenue: number; purchases: number }>;
  monthlyTrend: Array<{ month: string; revenue: number; profit: number }>;
};

export default function FinancialReportPage({ user }: { user: User }) {
  const [summary, setSummary] = useState<FinancialSummary | null>(null);
  const [loading, setLoading] = useState(true);
  const [period, setPeriod] = useState<Period>("month");
  const [userLevel, setUserLevel] = useState<GrowthLevel>("Semente");

  useEffect(() => {
    loadFinancialData();
  }, [user.uid, period]);

  async function loadFinancialData() {
    setLoading(true);
    try {
      const uid = user.uid;
      
      // Carregar perfil do usuário
      const profileSnap = await getDoc(doc(db, "users", uid));
      const level: GrowthLevel = profileSnap.exists()
        ? ((profileSnap.data() as UserProfile).growthLevel ?? "Semente")
        : "Semente";
      setUserLevel(level);

      // Definir período
      const now = new Date();
      let startDate: Date;
      let periodLabel: string;
      
      switch (period) {
        case "month":
          startDate = new Date(now.getFullYear(), now.getMonth(), 1);
          periodLabel = "Este mês";
          break;
        case "last30":
          startDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
          periodLabel = "Últimos 30 dias";
          break;
        case "quarter":
          startDate = new Date(now.getFullYear(), now.getMonth() - 2, 1);
          periodLabel = "Último trimestre";
          break;
        case "year":
          startDate = new Date(now.getFullYear() - 1, now.getMonth(), 1);
          periodLabel = "Último ano";
          break;
        default:
          startDate = new Date(2020, 0, 1);
          periodLabel = "Todo período";
      }

      // Carregar vendas do período
      const salesQuery = query(
        collection(db, "users", uid, "sales"),
        where("createdAt", ">=", Timestamp.fromDate(startDate)),
        orderBy("createdAt", "desc")
      );
      const salesSnap = await getDocs(salesQuery);

      // Carregar recebíveis
      const receivablesQuery = query(
        collection(db, "users", uid, "receivables"),
        where("createdAt", ">=", Timestamp.fromDate(startDate))
      );
      const receivablesSnap = await getDocs(receivablesQuery);

      // Carregar clientes
      const customersSnap = await getDocs(collection(db, "users", uid, "customers"));
      const customersMap = new Map<string, Customer>();
      customersSnap.docs.forEach(doc => {
        customersMap.set(doc.id, doc.data() as Customer);
      });

      // Processar dados
      let revenue = 0;
      let cost = 0;
      let salesCount = 0;
      const productMap = new Map<string, { revenue: number; quantity: number }>();
      const customerMap = new Map<string, { revenue: number; purchases: number }>();
      const monthlyMap = new Map<string, { revenue: number; profit: number }>();

      for (const saleDoc of salesSnap.docs) {
        const sale = saleDoc.data() as Sale;
        revenue += sale.totalCents ?? 0;
        salesCount++;

        // Processar itens da venda
        for (const item of sale.items ?? []) {
          const itemCost = (item.unitCostCents ?? 0) * (item.quantity ?? 0);
          const itemRevenue = (item.unitPriceCents ?? 0) * (item.quantity ?? 0);
          cost += itemCost;

          // Agrupar por produto
          const productKey = item.productName;
          const currentProduct = productMap.get(productKey) || { revenue: 0, quantity: 0 };
          productMap.set(productKey, {
            revenue: currentProduct.revenue + itemRevenue,
            quantity: currentProduct.quantity + (item.quantity ?? 0),
          });

          // Agrupar por cliente
          const customerKey = sale.customerId;
          const currentCustomer = customerMap.get(customerKey) || { revenue: 0, purchases: 0 };
          customerMap.set(customerKey, {
            revenue: currentCustomer.revenue + itemRevenue,
            purchases: currentCustomer.purchases + 1,
          });
        }

        // Agrupar por mês
        const saleDate = sale.createdAt?.toDate?.() || new Date();
        const monthKey = `${saleDate.getFullYear()}-${String(saleDate.getMonth() + 1).padStart(2, '0')}`;
        const currentMonth = monthlyMap.get(monthKey) || { revenue: 0, profit: 0 };
        const saleProfit = (sale.totalCents ?? 0) - cost;
        monthlyMap.set(monthKey, {
          revenue: currentMonth.revenue + (sale.totalCents ?? 0),
          profit: currentMonth.profit + saleProfit,
        });
      }

      // Calcular recebíveis
      let receivablesCollected = 0;
      let outstandingReceivables = 0;
      
      for (const recDoc of receivablesSnap.docs) {
        const receivable = recDoc.data() as Receivable;
        if (receivable.status === "paid") {
          receivablesCollected += receivable.paidCents;
        } else {
          outstandingReceivables += receivable.amountCents - receivable.paidCents;
        }
      }

      // Preparar top produtos
      const topProducts = Array.from(productMap.entries())
        .map(([name, stats]) => ({ name, ...stats }))
        .sort((a, b) => b.revenue - a.revenue)
        .slice(0, 5);

      // Preparar top clientes
      const topCustomers = Array.from(customerMap.entries())
        .map(([customerId, stats]) => ({
          name: customersMap.get(customerId)?.name || "Cliente não encontrado",
          ...stats,
        }))
        .sort((a, b) => b.revenue - a.revenue)
        .slice(0, 5);

      // Preparar tendência mensal
      const monthlyTrend = Array.from(monthlyMap.entries())
        .map(([monthKey, stats]) => {
          const [year, month] = monthKey.split('-');
          const monthNames = ["Jan", "Fev", "Mar", "Abr", "Mai", "Jun", "Jul", "Ago", "Set", "Out", "Nov", "Dez"];
          return {
            month: `${monthNames[parseInt(month) - 1]}/${year.slice(2)}`,
            revenue: stats.revenue,
            profit: stats.profit,
          };
        })
        .sort((a, b) => {
          // Ordenar por data
          const [aMonth, aYear] = a.month.split('/');
          const [bMonth, bYear] = b.month.split('/');
          const monthNames = ["Jan", "Fev", "Mar", "Abr", "Mai", "Jun", "Jul", "Ago", "Set", "Out", "Nov", "Dez"];
          const aIndex = monthNames.indexOf(aMonth) + parseInt(aYear) * 12;
          const bIndex = monthNames.indexOf(bMonth) + parseInt(bYear) * 12;
          return aIndex - bIndex;
        });

      const grossProfit = revenue - cost;
      const grossMargin = revenue > 0 ? (grossProfit / revenue) * 100 : 0;
      const avgSaleValue = salesCount > 0 ? revenue / salesCount : 0;

      setSummary({
        period: periodLabel,
        revenue,
        cost,
        grossProfit,
        grossMargin,
        receivablesCollected,
        outstandingReceivables,
        salesCount,
        avgSaleValue,
        topProducts,
        topCustomers,
        monthlyTrend,
      });
    } catch (error) {
      console.error("Erro ao carregar dados financeiros:", error);
    } finally {
      setLoading(false);
    }
  }

  const getProfitColor = (profit: number) => {
    if (profit > 0) return "text-green-600";
    if (profit < 0) return "text-red-600";
    return "text-gray-600";
  };

  const getMarginColor = (margin: number) => {
    if (margin > 20) return "text-green-600";
    if (margin > 10) return "text-yellow-600";
    return "text-red-600";
  };

  return (
    <DashboardLayout title="Relatório Financeiro">
      <div className="space-y-6 animate-fade-in">
        
        {/* Header com período */}
        <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
          <div>
            <h1 className="text-xl font-bold text-gray-900">Relatório Financeiro</h1>
            <p className="text-sm text-gray-500">Veja se seu negócio está lucrando</p>
          </div>
          
          <div className="flex flex-wrap gap-2">
            {(["month", "last30", "quarter", "year", "all"] as Period[]).map(p => (
              <button
                key={p}
                onClick={() => setPeriod(p)}
                className={`px-4 py-2 rounded-xl text-sm font-medium transition-colors border ${
                  period === p
                    ? "bg-teal-600 text-white border-teal-600"
                    : "bg-white text-gray-600 border-slate-200 hover:border-teal-300"
                }`}
              >
                {p === "month" ? "Este mês" : 
                 p === "last30" ? "30 dias" : 
                 p === "quarter" ? "Trimestre" : 
                 p === "year" ? "Ano" : "Tudo"}
              </button>
            ))}
          </div>
        </div>

        {loading ? (
          <div className="text-sm text-gray-400 py-12 text-center">Calculando relatórioâ€¦</div>
        ) : !summary ? (
          <div className="text-sm text-gray-400 py-12 text-center">Não há dados para o período selecionado.</div>
        ) : (
          <>
            {/* Cards de resumo */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
              <div className="rounded-2xl bg-white border border-slate-100 shadow-sm p-5">
                <div className="text-xs text-gray-500 mb-1">Receita Total</div>
                <div className="text-2xl font-bold text-gray-900">{formatMoney(summary.revenue)}</div>
                <div className="text-xs text-gray-400 mt-1">{summary.salesCount} venda{summary.salesCount !== 1 ? "s" : ""}</div>
              </div>
              
              <div className="rounded-2xl bg-white border border-slate-100 shadow-sm p-5">
                <div className="text-xs text-gray-500 mb-1">Custo Total</div>
                <div className="text-2xl font-bold text-gray-900">{formatMoney(summary.cost)}</div>
                <div className="text-xs text-gray-400 mt-1">{formatMoney(summary.avgSaleValue)} por venda</div>
              </div>
              
              <div className="rounded-2xl bg-white border border-slate-100 shadow-sm p-5">
                <div className="text-xs text-gray-500 mb-1">Lucro Bruto</div>
                <div className={`text-2xl font-bold ${getProfitColor(summary.grossProfit)}`}>
                  {formatMoney(summary.grossProfit)}
                </div>
                <div className={`text-xs font-medium ${getMarginColor(summary.grossMargin)} mt-1`}>
                  {summary.grossMargin.toFixed(1)}% de margem
                </div>
              </div>
              
              <div className="rounded-2xl bg-white border border-slate-100 shadow-sm p-5">
                <div className="text-xs text-gray-500 mb-1">Fluxo de Caixa</div>
                <div className="text-2xl font-bold text-gray-900">{formatMoney(summary.receivablesCollected)}</div>
                <div className="text-xs text-gray-400 mt-1">
                  + {formatMoney(summary.outstandingReceivables)} a receber
                </div>
              </div>
            </div>

            {/* Gráfico de tendência */}
            {summary.monthlyTrend.length > 0 && (
              <div className="rounded-2xl bg-white border border-slate-100 shadow-sm p-5">
                <h2 className="text-base font-semibold text-gray-800 mb-4">Tendência Mensal</h2>
                <div className="h-64 flex items-end gap-2">
                  {summary.monthlyTrend.map((month, index) => {
                    const maxRevenue = Math.max(...summary.monthlyTrend.map(m => m.revenue));
                    const height = maxRevenue > 0 ? (month.revenue / maxRevenue) * 100 : 0;
                    const profitHeight = maxRevenue > 0 ? (Math.abs(month.profit) / maxRevenue) * 100 : 0;
                    
                    return (
                      <div key={index} className="flex-1 flex flex-col items-center">
                        <div className="text-xs text-gray-500 mb-1">{month.month}</div>
                        <div className="w-full flex flex-col items-center" style={{ height: "150px" }}>
                          {/* Barra de receita */}
                          <div 
                            className="w-3/4 bg-teal-500 rounded-t-lg"
                            style={{ height: `${height}%` }}
                            title={`Receita: ${formatMoney(month.revenue)}`}
                          />
                          {/* Barra de lucro */}
                          <div 
                            className={`w-3/4 ${month.profit >= 0 ? 'bg-green-500' : 'bg-red-500'} rounded-b-lg mt-1`}
                            style={{ height: `${profitHeight}%` }}
                            title={`Lucro: ${formatMoney(month.profit)}`}
                          />
                        </div>
                        <div className="text-xs text-gray-400 mt-1 text-center">
                          {formatMoney(month.revenue).replace('R$', '').trim()}
                        </div>
                      </div>
                    );
                  })}
                </div>
                <div className="flex items-center justify-center gap-4 mt-4 text-xs text-gray-500">
                  <div className="flex items-center gap-1">
                    <div className="w-3 h-3 bg-teal-500 rounded"></div>
                    <span>Receita</span>
                  </div>
                  <div className="flex items-center gap-1">
                    <div className="w-3 h-3 bg-green-500 rounded"></div>
                    <span>Lucro</span>
                  </div>
                  <div className="flex items-center gap-1">
                    <div className="w-3 h-3 bg-red-500 rounded"></div>
                    <span>Prejuízo</span>
                  </div>
                </div>
              </div>
            )}

            {/* Top produtos e clientes */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {/* Top produtos */}
              <div className="rounded-2xl bg-white border border-slate-100 shadow-sm p-5">
                <h2 className="text-base font-semibold text-gray-800 mb-4">Produtos Mais Rentáveis</h2>
                <div className="space-y-3">
                  {summary.topProducts.length > 0 ? (
                    summary.topProducts.map((product, index) => (
                      <div key={index} className="flex items-center justify-between">
                        <div className="flex items-center gap-3">
                          <div className="w-8 h-8 rounded-lg bg-teal-100 flex items-center justify-center text-teal-700 font-bold text-sm">
                            {index + 1}
                          </div>
                          <div>
                            <div className="text-sm font-medium text-gray-900">{product.name}</div>
                            <div className="text-xs text-gray-500">{product.quantity} unidade{product.quantity !== 1 ? "s" : ""} vendida{product.quantity !== 1 ? "s" : ""}</div>
                          </div>
                        </div>
                        <div className="text-right">
                          <div className="text-sm font-semibold text-gray-900">{formatMoney(product.revenue)}</div>
                          <div className="text-xs text-gray-500">
                            {product.quantity > 0 ? formatMoney(product.revenue / product.quantity) : "â€”"} por unidade
                          </div>
                        </div>
                      </div>
                    ))
                  ) : (
                    <div className="text-sm text-gray-400 text-center py-4">Nenhum produto vendido no período.</div>
                  )}
                </div>
              </div>

              {/* Top clientes */}
              <div className="rounded-2xl bg-white border border-slate-100 shadow-sm p-5">
                <h2 className="text-base font-semibold text-gray-800 mb-4">Clientes Mais Valiosos</h2>
                <div className="space-y-3">
                  {summary.topCustomers.length > 0 ? (
                    summary.topCustomers.map((customer, index) => (
                      <div key={index} className="flex items-center justify-between">
                        <div className="flex items-center gap-3">
                          <div className="w-8 h-8 rounded-full bg-blue-100 flex items-center justify-center text-blue-700 font-bold text-sm">
                            {customer.name.charAt(0)}
                          </div>
                          <div>
                            <div className="text-sm font-medium text-gray-900 truncate max-w-[120px]">{customer.name}</div>
                            <div className="text-xs text-gray-500">{customer.purchases} compra{customer.purchases !== 1 ? "s" : ""}</div>
                          </div>
                        </div>
                        <div className="text-right">
                          <div className="text-sm font-semibold text-gray-900">{formatMoney(customer.revenue)}</div>
                          <div className="text-xs text-gray-500">
                            {customer.purchases > 0 ? formatMoney(customer.revenue / customer.purchases) : "â€”"} por compra
                          </div>
                        </div>
                      </div>
                    ))
                  ) : (
                    <div className="text-sm text-gray-400 text-center py-4">Nenhum cliente com compras no período.</div>
                  )}
                </div>
              </div>
            </div>

            {/* Análise de rentabilidade */}
            <div className="rounded-2xl bg-white border border-slate-100 shadow-sm p-5">
              <h2 className="text-base font-semibold text-gray-800 mb-4">Análise de Rentabilidade</h2>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div className="p-4 rounded-xl bg-slate-50 border border-slate-100">
                  <div className="text-xs text-gray-500 mb-1">Margem de Lucro</div>
                  <div className={`text-2xl font-bold ${getMarginColor(summary.grossMargin)}`}>
                    {summary.grossMargin.toFixed(1)}%
                  </div>
                  <div className="text-xs text-gray-400 mt-1">
                    {summary.grossMargin > 20 ? "Excelente" : 
                     summary.grossMargin > 15 ? "Boa" : 
                     summary.grossMargin > 10 ? "Aceitável" : "Baixa"}
                  </div>
                </div>
                
                <div className="p-4 rounded-xl bg-slate-50 border border-slate-100">
                  <div className="text-xs text-gray-500 mb-1">Ticket Médio</div>
                  <div className="text-2xl font-bold text-gray-900">{formatMoney(summary.avgSaleValue)}</div>
                  <div className="text-xs text-gray-400 mt-1">
                    {summary.avgSaleValue > 50000 ? "Alto" : 
                     summary.avgSaleValue > 20000 ? "Médio" : "Baixo"}
                  </div>
                </div>
                
                <div className="p-4 rounded-xl bg-slate-50 border border-slate-100">
                  <div className="text-xs text-gray-500 mb-1">Eficiência Operacional</div>
                  <div className="text-2xl font-bold text-gray-900">
                    {summary.salesCount > 0 ? (summary.grossProfit / summary.salesCount / 100).toFixed(2) : "0"}
                  </div>
                  <div className="text-xs text-gray-400 mt-1">Lucro por venda (R$)</div>
                </div>
              </div>
              
              <div className="mt-4 p-3 rounded-lg bg-teal-50 border border-teal-100">
                <div className="text-xs text-teal-700">
                  ðŸ’¡ <strong>Recomendação:</strong>{" "}
                  {summary.grossMargin > 20 
                    ? "Sua margem está excelente! Continue focando nos produtos mais rentáveis."
                    : summary.grossMargin > 15
                    ? "Sua margem está boa. Tente aumentar o ticket médio oferecendo combos."
                    : "Sua margem está baixa. Revise seus preços e custos para melhorar a rentabilidade."}
                </div>
              </div>
            </div>
          </>
        )}
      </div>
    </DashboardLayout>
  );
}
