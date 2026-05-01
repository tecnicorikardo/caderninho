import { useEffect, useState } from "react";
import type { User } from "firebase/auth";
import {
  collection, getDocs, query, where, orderBy, limit,
  Timestamp, doc, getDoc
} from "firebase/firestore";
import { Link } from "react-router-dom";
import DashboardLayout from "@/ui/DashboardLayout";
import StockHealthWidget from "@/ui/StockHealthWidget";
import { formatMoney } from "@/lib/money";
import type { Customer, InventoryItem, Sale, UserProfile, GrowthLevel } from "@/lib/types";
import { getMarginPercent } from "@/lib/margins";

type Stats = {
  customers: number;
  inventoryItems: number;
  totalStockValue: number;
  expiringSoon: number;
  monthRevenue: number;
  monthProfit: number;
  monthSalesCount: number;
  topCustomers: Array<Customer & { id: string }>;
  userLevel: GrowthLevel;
};

export default function DashboardPage({ user }: { user: User }) {
  const [stats, setStats] = useState<Stats | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function load() {
      const uid = user.uid;

      // Início e fim do mês atual
      const now = new Date();
      const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
      const endOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59);

      const [profileSnap, custSnap, invSnap, salesSnap, topCustSnap] = await Promise.all([
        getDoc(doc(db, "users", uid)),
        getDocs(collection(db, "users", uid, "customers")),
        getDocs(collection(db, "users", uid, "inventory")),
        getDocs(query(
          collection(db, "users", uid, "sales"),
          where("createdAt", ">=", Timestamp.fromDate(startOfMonth)),
          where("createdAt", "<=", Timestamp.fromDate(endOfMonth)),
          orderBy("createdAt", "desc")
        )),
        getDocs(query(
          collection(db, "users", uid, "customers"),
          where("balanceCents", ">", 0),
          orderBy("balanceCents", "desc"),
          limit(5)
        )),
      ]);

      const profile = profileSnap.exists() ? profileSnap.data() as UserProfile : null;
      const userLevel: GrowthLevel = profile?.growthLevel ?? "Semente";

      const sixty = Date.now() + 60 * 24 * 60 * 60 * 1000;
      let totalStockValue = 0;
      let expiringSoon = 0;

      for (const d of invSnap.docs) {
        const it = d.data() as InventoryItem;
        totalStockValue += (it.sellingPriceCents ?? 0) * (it.quantity ?? 0);
        const ms = it.expiryDate?.toMillis?.() ?? 0;
        if (ms && ms <= sixty) expiringSoon += it.quantity ?? 0;
      }

      let monthRevenue = 0;
      let monthProfit = 0;
      let monthSalesCount = 0;

      for (const d of salesSnap.docs) {
        const s = d.data() as Sale;
        monthRevenue += s.totalCents ?? 0;
        monthSalesCount++;
        // Calcular lucro pelos itens
        for (const item of s.items ?? []) {
          const profit = ((item.unitPriceCents ?? 0) - (item.unitCostCents ?? 0)) * (item.quantity ?? 0);
          monthProfit += profit;
        }
      }

      setStats({
        customers: custSnap.size,
        inventoryItems: invSnap.size,
        totalStockValue,
        expiringSoon,
        monthRevenue,
        monthProfit,
        monthSalesCount,
        topCustomers: topCustSnap.docs.map(d => ({ id: d.id, ...(d.data() as Customer) })),
        userLevel,
      });
      setLoading(false);
    }
    load().catch(() => setLoading(false));
  }, [user.uid]);

  const monthName = new Date().toLocaleDateString("pt-BR", { month: "long", year: "numeric" });

  return (
    <DashboardLayout title="Dashboard">
      {loading ? (
        <div className="text-sm text-gray-400 py-12 text-center">Carregando…</div>
      ) : (
        <div className="space-y-6 animate-fade-in">

          {/* Nível e mês */}
          <div className="flex items-center justify-between">
            <div className="text-sm font-medium text-slate-500 capitalize">{monthName}</div>
            <div className="flex items-center gap-2 bg-teal-50 border border-teal-200 rounded-xl px-3 py-1.5">
              <span className="text-xs text-teal-600 font-medium">Nível:</span>
              <span className="text-sm font-display font-bold text-teal-700">{stats?.userLevel}</span>
              <span className="text-xs text-teal-500">
                ({getMarginPercent("Natura", stats?.userLevel ?? "Semente")}% Natura)
              </span>
            </div>
          </div>

          {/* Cards principais */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-3 stagger">
            <StatCard
              label="Faturamento do mês"
              value={formatMoney(stats?.monthRevenue ?? 0)}
              sub={`${stats?.monthSalesCount ?? 0} venda${stats?.monthSalesCount !== 1 ? "s" : ""}`}
              icon="💰"
              color="bg-emerald-50 border-emerald-100"
              iconBg="bg-emerald-100"
              valueColor="text-emerald-700"
              link="/sales"
            />
            <StatCard
              label="Lucro do mês"
              value={formatMoney(stats?.monthProfit ?? 0)}
              sub={stats?.monthRevenue ? `${((stats.monthProfit / stats.monthRevenue) * 100).toFixed(1)}% margem` : "—"}
              icon="📈"
              color="bg-teal-50 border-teal-100"
              iconBg="bg-teal-100"
              valueColor="text-teal-700"
              link="/sales"
            />
            <StatCard
              label="Valor em estoque"
              value={formatMoney(stats?.totalStockValue ?? 0)}
              sub={`${stats?.inventoryItems ?? 0} produtos`}
              icon="📦"
              color="bg-blue-50 border-blue-100"
              iconBg="bg-blue-100"
              valueColor="text-blue-700"
              link="/inventory"
            />
            <StatCard
              label="Clientes"
              value={String(stats?.customers ?? 0)}
              sub={stats?.topCustomers.length ? `${stats.topCustomers.length} com saldo` : "cadastrados"}
              icon="👥"
              color={stats?.expiringSoon ? "bg-orange-50 border-orange-100" : "bg-slate-50 border-slate-100"}
              iconBg={stats?.expiringSoon ? "bg-orange-100" : "bg-slate-100"}
              valueColor={stats?.expiringSoon ? "text-orange-700" : "text-slate-700"}
              link="/customers"
            />
          </div>

          {/* Ação rápida */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
            {[
              { to: "/sales", label: "Nova Venda", icon: "🛒", color: "bg-brand-700 hover:bg-brand-800 text-white shadow-md hover:shadow-lg" },
              { to: "/inventory", label: "Ver Estoque", icon: "📦", color: "bg-white hover:bg-slate-50 text-gray-700 border border-slate-200 shadow-card hover:shadow-card-hover" },
              { to: "/customers", label: "Clientes", icon: "👥", color: "bg-white hover:bg-slate-50 text-gray-700 border border-slate-200 shadow-card hover:shadow-card-hover" },
              { to: "/commission", label: "Comissões", icon: "💰", color: "bg-white hover:bg-slate-50 text-gray-700 border border-slate-200 shadow-card hover:shadow-card-hover" },
            ].map(a => (
              <Link
                key={a.to}
                to={a.to}
                className={`rounded-2xl p-4 flex items-center gap-3 font-semibold text-sm transition-all duration-200 ${a.color}`}
              >
                <span className="text-xl">{a.icon}</span>
                {a.label}
              </Link>
            ))}
          </div>

          {/* Ação rápida - segunda linha */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
            {[
              { to: "/receivables", label: "Recebimentos", icon: "💳", color: "bg-white hover:bg-slate-50 text-gray-700 border border-slate-200 shadow-card hover:shadow-card-hover" },
              { to: "/financial-report", label: "Relatório", icon: "📊", color: "bg-white hover:bg-slate-50 text-gray-700 border border-slate-200 shadow-card hover:shadow-card-hover" },
              { to: "/settings", label: "Configurações", icon: "⚙️", color: "bg-white hover:bg-slate-50 text-gray-700 border border-slate-200 shadow-card hover:shadow-card-hover" },
            ].map(a => (
              <Link
                key={a.to}
                to={a.to}
                className={`rounded-2xl p-4 flex items-center gap-3 font-semibold text-sm transition-all duration-200 ${a.color}`}
              >
                <span className="text-xl">{a.icon}</span>
                {a.label}
              </Link>
            ))}
            <div className="rounded-2xl p-4 opacity-0 pointer-events-none" />
          </div>

          {/* Saúde do estoque */}
          <StockHealthWidget uid={user.uid} />

          {/* Clientes com saldo */}
          {(stats?.topCustomers?.length ?? 0) > 0 && (
            <div className="rounded-2xl bg-white border border-slate-100 shadow-sm p-5">
              <div className="flex items-center justify-between mb-3">
                <h2 className="text-base font-semibold text-gray-800">Clientes com saldo em aberto</h2>
                <Link to="/customers" className="text-xs text-teal-600 hover:underline">Ver todos →</Link>
              </div>
              <div className="space-y-2">
                {stats!.topCustomers.map(c => (
                  <div key={c.id} className="flex items-center justify-between py-2 border-b border-slate-50 last:border-0">
                    <div className="flex items-center gap-2">
                      <div className="w-8 h-8 rounded-full bg-orange-100 flex items-center justify-center text-orange-700 font-bold text-sm">
                        {c.name.charAt(0)}
                      </div>
                      <div>
                        <div className="text-sm font-medium text-gray-900">{c.name}</div>
                        <div className="text-xs text-gray-500">{c.phone}</div>
                      </div>
                    </div>
                    <span className="text-sm font-semibold text-orange-600">{formatMoney(c.balanceCents)}</span>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      )}
    </DashboardLayout>
  );
}

function StatCard({
  label, value, sub, icon, color, iconBg, valueColor, link
}: {
  label: string; value: string; sub: string; icon: string;
  color: string; iconBg?: string; valueColor?: string; link: string;
}) {
  return (
    <Link
      to={link}
      className={`rounded-2xl border p-4 block card-interactive transition-all duration-200 ${color}`}
    >
      <div className={`w-10 h-10 rounded-xl flex items-center justify-center text-xl mb-3 ${iconBg ?? "bg-white/60"}`}>
        {icon}
      </div>
      <div className={`text-money-md leading-tight ${valueColor ?? "text-gray-900"}`}>{value}</div>
      <div className="text-xs font-semibold text-gray-600 mt-1 leading-snug">{label}</div>
      <div className="text-xs text-gray-400 mt-0.5">{sub}</div>
    </Link>
  );
}

// Import db
import { db } from "@/lib/firebase";
