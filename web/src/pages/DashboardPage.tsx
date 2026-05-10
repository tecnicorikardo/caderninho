import { useEffect, useState } from "react";
import type { AppUser } from "@/App";
import { Link } from "react-router-dom";
import { databases, DATABASE_ID, COLLECTIONS, Query } from "@/lib/appwrite";
import { toMillis } from "@/lib/timestamp";
import DashboardLayout from "@/ui/DashboardLayout";
import StockHealthWidget from "@/ui/StockHealthWidget";
import { formatMoney } from "@/lib/money";
import type { Customer, InventoryItem, Sale, GrowthLevel } from "@/lib/types";
import { getMarginPercent } from "@/lib/margins";

type Stats = {
  customers: number;
  inventoryItems: number;
  totalStockValue: number;
  expiringSoon: number;
  monthRevenue: number;
  monthProfit: number;
  monthSalesCount: number;
  topCustomers: Array<Customer & { $id: string }>;
  userLevel: GrowthLevel;
};

export default function DashboardPage({ user }: { user: AppUser }) {
  const [stats, setStats] = useState<Stats | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function load() {
      const uid = user.uid;
      const now = new Date();
      const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1).toISOString();
      const endOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59).toISOString();

      const [profileRes, custRes, invRes, salesRes, topCustRes] = await Promise.all([
        databases.listDocuments(DATABASE_ID, COLLECTIONS.PROFILES, [
          Query.equal("userId", uid), Query.limit(1),
        ]),
        databases.listDocuments(DATABASE_ID, COLLECTIONS.CUSTOMERS, [
          Query.equal("userId", uid), Query.limit(1000),
        ]),
        databases.listDocuments(DATABASE_ID, COLLECTIONS.INVENTORY, [
          Query.equal("userId", uid), Query.limit(1000),
        ]),
        databases.listDocuments(DATABASE_ID, COLLECTIONS.SALES, [
          Query.equal("userId", uid),
          Query.greaterThanEqual("createdAt", startOfMonth),
          Query.lessThanEqual("createdAt", endOfMonth),
          Query.orderDesc("createdAt"),
        ]),
        databases.listDocuments(DATABASE_ID, COLLECTIONS.CUSTOMERS, [
          Query.equal("userId", uid),
          Query.greaterThan("balanceCents", 0),
          Query.orderDesc("balanceCents"),
          Query.limit(5),
        ]),
      ]);

      const profile = profileRes.documents[0] ?? null;
      const userLevel: GrowthLevel = (profile?.growthLevel as GrowthLevel) ?? "Semente";

      const sixty = Date.now() + 60 * 24 * 60 * 60 * 1000;
      let totalStockValue = 0;
      let expiringSoon = 0;

      for (const d of invRes.documents) {
        const it = d as unknown as InventoryItem;
        totalStockValue += (it.sellingPriceCents ?? 0) * (it.quantity ?? 0);
        const ms = toMillis(it.expiryDate);
        if (ms && ms <= sixty) expiringSoon += it.quantity ?? 0;
      }

      let monthRevenue = 0;
      let monthProfit = 0;
      let monthSalesCount = 0;

      for (const d of salesRes.documents) {
        const s = d as unknown as Sale;
        const items = typeof s.items === "string" ? JSON.parse(s.items) : (s.items ?? []);
        monthRevenue += s.totalCents ?? 0;
        monthSalesCount++;
        for (const item of items) {
          const profit = ((item.unitPriceCents ?? 0) - (item.unitCostCents ?? 0)) * (item.quantity ?? 0);
          monthProfit += profit;
        }
      }

      setStats({
        customers: custRes.total,
        inventoryItems: invRes.total,
        totalStockValue,
        expiringSoon,
        monthRevenue,
        monthProfit,
        monthSalesCount,
        topCustomers: topCustRes.documents.map(d => ({ $id: d.$id, ...(d as unknown as Customer) })),
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
        <div className="space-y-6">
          <div className="flex items-center justify-between">
            <div className="text-sm font-semibold text-gray-500 capitalize">{monthName}</div>
          </div>

          <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
            <StatCard label="Faturamento do mês" value={formatMoney(stats?.monthRevenue ?? 0)} sub={`${stats?.monthSalesCount ?? 0} venda${stats?.monthSalesCount !== 1 ? "s" : ""}`} icon="💰" color="bg-green-50 border-green-100" link="/sales" />
            <StatCard label="Lucro do mês" value={formatMoney(stats?.monthProfit ?? 0)} sub={stats?.monthRevenue ? `${((stats.monthProfit / stats.monthRevenue) * 100).toFixed(1)}% margem` : "—"} icon="📈" color="bg-teal-50 border-teal-100" link="/sales" />
            <StatCard label="Valor em estoque" value={formatMoney(stats?.totalStockValue ?? 0)} sub={`${stats?.inventoryItems ?? 0} produtos`} icon="📦" color="bg-blue-50 border-blue-100" link="/inventory" />
            <StatCard label="Clientes" value={String(stats?.customers ?? 0)} sub={stats?.topCustomers.length ? `${stats.topCustomers.length} com saldo` : "cadastrados"} icon="👥" color={stats?.expiringSoon ? "bg-orange-50 border-orange-100" : "bg-slate-50 border-slate-100"} link="/customers" />
          </div>

          <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
            {[
              { to: "/sales", label: "Nova Venda", icon: "🛒", color: "bg-teal-600 hover:bg-teal-700 text-white" },
              { to: "/inventory", label: "Ver Estoque", icon: "📦", color: "bg-white hover:bg-slate-50 text-gray-700 border border-slate-200" },
              { to: "/customers", label: "Clientes", icon: "👥", color: "bg-white hover:bg-slate-50 text-gray-700 border border-slate-200" },
              { to: "/commission", label: "Comissões", icon: "💰", color: "bg-white hover:bg-slate-50 text-gray-700 border border-slate-200" },
            ].map(a => (
              <Link key={a.to} to={a.to} className={`rounded-2xl p-4 flex items-center gap-3 font-medium text-sm transition-colors shadow-sm ${a.color}`}>
                <span className="text-xl">{a.icon}</span>
                {a.label}
              </Link>
            ))}
          </div>

          <StockHealthWidget uid={user.uid} />

          {(stats?.topCustomers?.length ?? 0) > 0 && (
            <div className="card-brand p-5">
              <div className="flex items-center justify-between mb-3">
                <h2 className="text-base font-semibold text-gray-800">Clientes com saldo em aberto</h2>
                <Link to="/customers" className="text-xs text-teal-600 hover:underline">Ver todos →</Link>
              </div>
              <div className="space-y-2">
                {stats!.topCustomers.map(c => (
                  <div key={c.$id} className="flex items-center justify-between py-2 border-b border-slate-50 last:border-0">
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

function StatCard({ label, value, sub, icon, color, link }: { label: string; value: string; sub: string; icon: string; color: string; link: string }) {
  return (
    <Link to={link} className={`rounded-2xl border p-4 block hover:shadow-md transition-shadow ${color}`}>
      <div className="text-2xl mb-1">{icon}</div>
      <div className="text-xl font-bold text-gray-900 leading-tight">{value}</div>
      <div className="text-xs text-gray-500 mt-0.5">{label}</div>
      <div className="text-xs text-gray-400 mt-0.5">{sub}</div>
    </Link>
  );
}

