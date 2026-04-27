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

  const filtered = useMemo(() =>
    rows.filter(c =>
      c.name.toLowerCase().includes(search.toLowerCase()) ||
      c.phone.includes(search) ||
      (c.email ?? "").toLowerCase().includes(search.toLowerCase())
    ), [rows, search]);

  return (
    <DashboardLayout title="Clientes">
      <div className="space-y-4">
        {/* Toolbar */}
        <div className="flex flex-col sm:flex-row gap-3">
          <input
            className="flex-1 rounded-xl border border-slate-200 px-4 py-2.5 text-sm bg-white shadow-sm focus:outline-none focus:ring-2 focus:ring-teal-400"
            placeholder="Buscar por nome, telefone ou e-mail…"
            value={search}
            onChange={e => setSearch(e.target.value)}
          />
          <button
            onClick={() => { setShowForm(true); setError(null); }}
            className="rounded-xl bg-teal-600 hover:bg-teal-700 text-white px-5 py-2.5 text-sm font-medium transition-colors shadow-sm"
          >
            + Novo cliente
          </button>
        </div>

        {/* Formulário de cadastro */}
        {showForm && (
          <div className="rounded-2xl bg-white border border-slate-100 shadow-sm p-5">
            <h2 className="text-base font-semibold mb-4">Novo cliente</h2>
            <form onSubmit={handleSave} className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div>
                <label className="text-xs font-medium text-gray-600">Nome *</label>
                <input className="mt-1 w-full rounded-lg border px-3 py-2 text-sm" value={form.name}
                  onChange={e => setForm(f => ({ ...f, name: e.target.value }))} required />
              </div>
              <div>
                <label className="text-xs font-medium text-gray-600">Telefone / WhatsApp *</label>
                <input className="mt-1 w-full rounded-lg border px-3 py-2 text-sm" value={form.phone}
                  onChange={e => setForm(f => ({ ...f, phone: e.target.value }))} required />
              </div>
              <div>
                <label className="text-xs font-medium text-gray-600">E-mail</label>
                <input type="email" className="mt-1 w-full rounded-lg border px-3 py-2 text-sm" value={form.email}
                  onChange={e => setForm(f => ({ ...f, email: e.target.value }))} />
              </div>
              <div>
                <label className="text-xs font-medium text-gray-600">Endereço</label>
                <input className="mt-1 w-full rounded-lg border px-3 py-2 text-sm" value={form.address}
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

