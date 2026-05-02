import { useEffect, useMemo, useState } from "react";
import type { User } from "firebase/auth";
import {
  collection, getDocs, addDoc, limit, orderBy, query, serverTimestamp
} from "firebase/firestore";
import DashboardLayout from "@/ui/DashboardLayout";
import { db } from "@/lib/firebase";
import type { Customer } from "@/lib/types";
import { buildCustomerHistoryText } from "@/lib/customerHistory";
import { shareOrWhatsApp } from "@/lib/whatsapp";
import { formatMoney } from "@/lib/money";
import { PLAN_LIMITS, getUserPlan } from "@/lib/plan";
import PlanLimitBanner from "@/ui/PlanLimitBanner";

type Row = Customer & { id: string };

const EMPTY = { name: "", phone: "", email: "", address: "" };

export default function CustomersPage({ user }: { user: User }) {
  const [rows, setRows] = useState<Row[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState("");
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState(EMPTY);
  const [saving, setSaving] = useState(false);

  // Filtros rápidos
  type CustomerFilter = "all" | "withBalance" | "noBalance";
  type CustomerSort = "recent" | "az" | "balance";
  const [activeFilter, setActiveFilter] = useState<CustomerFilter>("all");
  const [activeSort, setActiveSort] = useState<CustomerSort>("recent");

  async function load() {
    setLoading(true);
    setError(null);
    const colRef = collection(db, "users", user.uid, "customers");
    const q = query(colRef, orderBy("createdAt", "desc"), limit(200));
    const snap = await getDocs(q);
    setRows(snap.docs.map((d) => ({ id: d.id, ...(d.data() as Customer) })));
    setLoading(false);
  }

  useEffect(() => {
    load().catch((err) => {
      setError(err instanceof Error ? err.message : "Falha ao carregar clientes.");
      setLoading(false);
    });
  }, [user.uid]);

  async function handleSave(e: React.FormEvent) {
    e.preventDefault();
    if (!form.name || !form.phone) { setError("Nome e telefone são obrigatórios."); return; }
    setSaving(true);
    setError(null);
    try {
      await addDoc(collection(db, "users", user.uid, "customers"), {
        name: form.name.trim(),
        phone: form.phone.trim(),
        phoneNormalized: form.phone.replace(/\D/g, ""),
        email: form.email.trim() || null,
        address: form.address.trim() || null,
        balanceCents: 0,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      } satisfies Omit<Customer, "createdAt" | "updatedAt"> & { createdAt: ReturnType<typeof serverTimestamp>; updatedAt: ReturnType<typeof serverTimestamp> });
      setForm(EMPTY);
      setShowForm(false);
      await load();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Erro ao salvar.");
    } finally {
      setSaving(false);
    }
  }

  const filtered = useMemo(() => {
    let result = rows.filter(c =>
      c.name.toLowerCase().includes(search.toLowerCase()) ||
      c.phone.includes(search) ||
      (c.email ?? "").toLowerCase().includes(search.toLowerCase())
    );

    // Filtro por saldo
    if (activeFilter === "withBalance") result = result.filter(c => (c.balanceCents ?? 0) > 0);
    if (activeFilter === "noBalance")   result = result.filter(c => (c.balanceCents ?? 0) === 0);

    // Ordenação
    if (activeSort === "az")      result = [...result].sort((a, b) => a.name.localeCompare(b.name, "pt-BR"));
    if (activeSort === "balance") result = [...result].sort((a, b) => (b.balanceCents ?? 0) - (a.balanceCents ?? 0));
    // "recent" já vem ordenado do Firestore (createdAt desc)

    return result;
  }, [rows, search, activeFilter, activeSort]);

  const withBalanceCount = rows.filter(c => (c.balanceCents ?? 0) > 0).length;

  // Limites do plano
  const plan = getUserPlan();
  const customerLimit = PLAN_LIMITS[plan].customers;
  const atCustomerLimit = rows.length >= customerLimit;

  return (
    <DashboardLayout title="Clientes">
      <div className="space-y-4">
        {/* Toolbar */}
        <div className="flex flex-col sm:flex-row gap-3">
          <input
            className="inp flex-1"
            placeholder="Buscar por nome, telefone ou e-mail…"
            value={search}
            onChange={e => setSearch(e.target.value)}
          />
          <button
            onClick={() => { setShowForm(true); setError(null); }}
            disabled={atCustomerLimit}
            className="rounded-xl bg-teal-600 hover:bg-teal-700 text-white px-5 py-2.5 text-sm font-medium transition-colors shadow-sm disabled:opacity-50 disabled:cursor-not-allowed"
            title={atCustomerLimit ? `Limite de ${customerLimit} clientes atingido` : undefined}
          >
            + Novo cliente
          </button>
        </div>

        {/* Filtros rápidos */}
        <div className="flex flex-wrap gap-2 items-center">
          {/* Filtro por saldo */}
          <button
            onClick={() => setActiveFilter("all")}
            className={`px-3 py-1.5 rounded-xl text-xs font-medium border transition-colors ${
              activeFilter === "all"
                ? "bg-teal-600 text-white border-teal-600"
                : "bg-white text-gray-600 border-slate-200 hover:border-teal-300 hover:text-teal-700"
            }`}
          >
            Todos ({rows.length})
          </button>
          <button
            onClick={() => setActiveFilter("withBalance")}
            className={`px-3 py-1.5 rounded-xl text-xs font-medium border transition-colors ${
              activeFilter === "withBalance"
                ? "bg-orange-500 text-white border-orange-500"
                : "bg-white text-gray-600 border-slate-200 hover:border-orange-300 hover:text-orange-600"
            }`}
          >
            💳 Com saldo ({withBalanceCount})
          </button>
          <button
            onClick={() => setActiveFilter("noBalance")}
            className={`px-3 py-1.5 rounded-xl text-xs font-medium border transition-colors ${
              activeFilter === "noBalance"
                ? "bg-green-600 text-white border-green-600"
                : "bg-white text-gray-600 border-slate-200 hover:border-green-300 hover:text-green-600"
            }`}
          >
            ✅ Quitados
          </button>

          {/* Separador */}
          <span className="w-px h-5 bg-slate-200 mx-1" />

          {/* Ordenação */}
          <button
            onClick={() => setActiveSort("recent")}
            className={`px-3 py-1.5 rounded-xl text-xs font-medium border transition-colors ${
              activeSort === "recent"
                ? "bg-slate-700 text-white border-slate-700"
                : "bg-white text-gray-600 border-slate-200 hover:border-slate-400"
            }`}
          >
            Recentes
          </button>
          <button
            onClick={() => setActiveSort("az")}
            className={`px-3 py-1.5 rounded-xl text-xs font-medium border transition-colors ${
              activeSort === "az"
                ? "bg-slate-700 text-white border-slate-700"
                : "bg-white text-gray-600 border-slate-200 hover:border-slate-400"
            }`}
          >
            A–Z
          </button>
          <button
            onClick={() => setActiveSort("balance")}
            className={`px-3 py-1.5 rounded-xl text-xs font-medium border transition-colors ${
              activeSort === "balance"
                ? "bg-slate-700 text-white border-slate-700"
                : "bg-white text-gray-600 border-slate-200 hover:border-slate-400"
            }`}
          >
            Maior saldo
          </button>
        </div>

        {/* Banner de limite do plano */}
        <PlanLimitBanner current={rows.length} limit={customerLimit} label="clientes" />

        {/* Formulário de cadastro */}
        {showForm && (
          <div className="rounded-2xl bg-white border border-slate-100 shadow-sm p-5">
            <h2 className="text-base font-semibold mb-4">Novo cliente</h2>
            <form onSubmit={handleSave} className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div>
                <label className="inp-label">Nome *</label>
                <input className="inp" placeholder="Nome completo" value={form.name}
                  onChange={e => setForm(f => ({ ...f, name: e.target.value }))} required />
              </div>
              <div>
                <label className="inp-label">Telefone / WhatsApp *</label>
                <input className="inp" placeholder="(11) 99999-9999" value={form.phone}
                  onChange={e => setForm(f => ({ ...f, phone: e.target.value }))} required />
              </div>
              <div>
                <label className="inp-label">E-mail</label>
                <input type="email" className="inp" placeholder="Opcional" value={form.email}
                  onChange={e => setForm(f => ({ ...f, email: e.target.value }))} />
              </div>
              <div>
                <label className="inp-label">Endereço</label>
                <input className="inp" placeholder="Opcional" value={form.address}
                  onChange={e => setForm(f => ({ ...f, address: e.target.value }))} />
              </div>
              {error && <p className="sm:col-span-2 text-xs text-red-600">{error}</p>}
              <div className="sm:col-span-2 flex gap-2 pt-1">
                <button type="button" onClick={() => setShowForm(false)}
                  className="rounded-lg border px-4 py-2 text-sm">Cancelar</button>
                <button type="submit" disabled={saving}
                  className="rounded-lg bg-teal-600 hover:bg-teal-700 text-white px-5 py-2 text-sm font-medium disabled:opacity-60">
                  {saving ? "Salvando…" : "Salvar"}
                </button>
              </div>
            </form>
          </div>
        )}

        {/* Lista */}
        {loading ? (
          <div className="text-sm text-gray-500 py-8 text-center">Carregando…</div>
        ) : error && rows.length === 0 ? (
          <div className="text-sm text-red-600">{error}</div>
        ) : filtered.length === 0 ? (
          <div className="text-sm text-gray-500 py-8 text-center">
            {search ? "Nenhum resultado." : "Nenhum cliente cadastrado ainda."}
          </div>
        ) : (
          <>
            <div className="text-xs text-gray-400 px-1">{filtered.length} cliente{filtered.length !== 1 ? "s" : ""}</div>
            <div className="grid gap-3 sm:grid-cols-2">
              {filtered.map((c) => (
                <div
                  key={c.id}
                  className="rounded-2xl bg-white border border-slate-100 shadow-sm p-4 flex items-center justify-between gap-3 hover:shadow-md transition-shadow"
                >
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-full bg-teal-100 flex items-center justify-center text-teal-700 font-bold text-lg flex-shrink-0">
                      {c.name.charAt(0).toUpperCase()}
                    </div>
                    <div>
                      <div className="font-semibold text-gray-900">{c.name}</div>
                      <div className="text-sm text-gray-500">{c.phone}</div>
                      {c.email && <div className="text-xs text-gray-400">{c.email}</div>}
                      {(c.balanceCents ?? 0) > 0 && (
                        <div className="text-xs font-medium text-orange-600 mt-0.5">
                          Saldo: {formatMoney(c.balanceCents ?? 0)}
                        </div>
                      )}
                    </div>
                  </div>
                  <button
                    className="rounded-xl bg-teal-600 hover:bg-teal-700 text-white px-3 py-2 text-xs font-medium min-h-10 transition-colors flex-shrink-0"
                    onClick={async () => {
                      const text = await buildCustomerHistoryText({ uid: user.uid, customerId: c.id, customer: c });
                      await shareOrWhatsApp(text);
                    }}
                  >
                    WhatsApp
                  </button>
                </div>
              ))}
            </div>
          </>
        )}
      </div>
    </DashboardLayout>
  );
}

