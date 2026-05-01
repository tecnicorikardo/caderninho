import { useEffect, useState } from "react";
import type { User } from "firebase/auth";
import {
  collection, addDoc, deleteDoc, doc, getDocs,
  orderBy, query, serverTimestamp, Timestamp
} from "firebase/firestore";
import { useSearchParams } from "react-router-dom";
import DashboardLayout from "@/ui/DashboardLayout";
import { db } from "@/lib/firebase";
import { formatMoney, toCents } from "@/lib/money";
import type { InventoryItem } from "@/lib/types";

type Row = InventoryItem & { id: string };

const BRANDS = ["Natura", "Avon", "Casa & Estilo", "Outra"];

const EMPTY_FORM = {
  productName: "",
  brand: "Natura",
  sku: "",
  quantity: "",
  costPrice: "",
  sellingPrice: "",
  expiryDate: "",
};

export default function InventoryPage({ user }: { user: User }) {
  const [rows, setRows] = useState<Row[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState(EMPTY_FORM);
  const [saving, setSaving] = useState(false);
  const [search, setSearch] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [searchParams, setSearchParams] = useSearchParams();

  // Filtro de vencimento vindo da URL (?expiry=30|60|90)
  const expiryFilter = searchParams.get("expiry"); // "30" | "60" | "90" | null

  const EXPIRY_LABELS: Record<string, string> = {
    "30": "Vencem em menos de 30 dias",
    "60": "Vencem em menos de 60 dias",
    "90": "Vencem em menos de 90 dias",
  };

  async function load() {
    setLoading(true);
    const q = query(collection(db, "users", user.uid, "inventory"), orderBy("expiryDate", "asc"));
    const snap = await getDocs(q);
    setRows(snap.docs.map(d => ({ id: d.id, ...(d.data() as InventoryItem) })));
    setLoading(false);
  }

  useEffect(() => { load().catch(() => setLoading(false)); }, [user.uid]);

  async function handleSave(e: React.FormEvent) {
    e.preventDefault();
    if (!form.productName || !form.quantity || !form.expiryDate) {
      setError("Preencha nome, quantidade e validade.");
      return;
    }
    setSaving(true);
    setError(null);
    try {
      const expiryDate = Timestamp.fromDate(new Date(`${form.expiryDate}T00:00:00`));
      await addDoc(collection(db, "users", user.uid, "inventory"), {
        productId: `manual_${Date.now()}`,
        sku: form.sku || null,
        productName: form.productName.trim(),
        brand: form.brand,
        quantity: Number(form.quantity),
        costPriceCents: toCents(form.costPrice),
        sellingPriceCents: toCents(form.sellingPrice),
        expiryDate,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      } satisfies Omit<InventoryItem, "expiryDate"> & { expiryDate: Timestamp });
      setForm(EMPTY_FORM);
      setShowForm(false);
      await load();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Erro ao salvar.");
    } finally {
      setSaving(false);
    }
  }

  async function handleDelete(id: string, name: string) {
    if (!confirm(`Excluir "${name}"?`)) return;
    await deleteDoc(doc(db, "users", user.uid, "inventory", id));
    setRows(r => r.filter(x => x.id !== id));
  }

  const now = Date.now();
  const sixty = now + 60 * 24 * 60 * 60 * 1000;
  const ninety = now + 90 * 24 * 60 * 60 * 1000;

  const filtered = rows.filter(r => {
    // Filtro de texto
    const matchText =
      r.productName.toLowerCase().includes(search.toLowerCase()) ||
      r.brand.toLowerCase().includes(search.toLowerCase()) ||
      (r.sku ?? "").toLowerCase().includes(search.toLowerCase());

    if (!matchText) return false;

    // Filtro de vencimento (vindo da URL)
    if (expiryFilter) {
      const ms = r.expiryDate?.toMillis?.() ?? 0;
      const days = Number(expiryFilter);
      const cutoff = now + days * 24 * 60 * 60 * 1000;
      return ms > 0 && ms <= cutoff && r.quantity > 0;
    }

    return true;
  });

  function expiryClass(ms: number) {
    if (ms <= now) return "bg-red-100 text-red-700";
    if (ms <= sixty) return "bg-orange-100 text-orange-700";
    if (ms <= ninety) return "bg-yellow-100 text-yellow-700";
    return "bg-green-100 text-green-700";
  }

  function expiryLabel(ms: number) {
    const days = Math.ceil((ms - now) / (24 * 60 * 60 * 1000));
    if (days < 0) return "Vencido";
    if (days === 0) return "Vence hoje";
    return `${days}d`;
  }

  return (
    <DashboardLayout title="Estoque">
      <div className="space-y-4 animate-fade-in">
        {/* Toolbar */}
        <div className="flex flex-col sm:flex-row gap-3">
          <input
            className="flex-1 rounded-xl border border-slate-200 px-4 py-2.5 text-sm bg-white shadow-sm focus:outline-none focus:ring-2 focus:ring-teal-400"
            placeholder="Buscar produto, marca ou SKUâ€¦"
            value={search}
            onChange={e => setSearch(e.target.value)}
          />
          <button
            onClick={() => { setShowForm(true); setError(null); }}
            className="rounded-xl bg-teal-600 hover:bg-teal-700 text-white px-5 py-2.5 text-sm font-medium transition-colors shadow-sm"
          >
            + Novo produto
          </button>
        </div>

        {/* Banner de filtro ativo */}
        {expiryFilter && (
          <div className={`rounded-xl border px-4 py-3 flex items-center justify-between ${
            expiryFilter === "30" ? "bg-red-50 border-red-200 text-red-700" :
            expiryFilter === "60" ? "bg-orange-50 border-orange-200 text-orange-700" :
            "bg-yellow-50 border-yellow-200 text-yellow-700"
          }`}>
            <div className="flex items-center gap-2">
              <span className="text-base">{expiryFilter === "30" ? "ðŸ”´" : expiryFilter === "60" ? "ðŸŸ " : "ðŸŸ¡"}</span>
              <span className="text-sm font-medium">{EXPIRY_LABELS[expiryFilter]}</span>
              <span className="text-xs opacity-70">â€” {filtered.length} produto{filtered.length !== 1 ? "s" : ""}</span>
            </div>
            <button
              onClick={() => setSearchParams({})}
              className="text-xs font-medium underline opacity-70 hover:opacity-100"
            >
              Limpar filtro
            </button>
          </div>
        )}

        {/* Formulário */}
        {showForm && (
          <div className="rounded-2xl bg-white border border-slate-100 shadow-sm p-5">
            <h2 className="text-base font-semibold mb-4">Novo produto no estoque</h2>
            <form onSubmit={handleSave} className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div className="sm:col-span-2">
                <label className="text-xs font-medium text-gray-600">Nome do produto *</label>
                <input className="mt-1 w-full rounded-lg border px-3 py-2 text-sm" value={form.productName}
                  onChange={e => setForm(f => ({ ...f, productName: e.target.value }))} required />
              </div>
              <div>
                <label className="text-xs font-medium text-gray-600">Marca *</label>
                <select className="mt-1 w-full rounded-lg border px-3 py-2 text-sm bg-white" value={form.brand}
                  onChange={e => setForm(f => ({ ...f, brand: e.target.value }))}>
                  {BRANDS.map(b => <option key={b}>{b}</option>)}
                </select>
              </div>
              <div>
                <label className="text-xs font-medium text-gray-600">SKU / Código</label>
                <input className="mt-1 w-full rounded-lg border px-3 py-2 text-sm" value={form.sku}
                  onChange={e => setForm(f => ({ ...f, sku: e.target.value }))} />
              </div>
              <div>
                <label className="text-xs font-medium text-gray-600">Quantidade *</label>
                <input type="number" min="1" className="mt-1 w-full rounded-lg border px-3 py-2 text-sm" value={form.quantity}
                  onChange={e => setForm(f => ({ ...f, quantity: e.target.value }))} required />
              </div>
              <div>
                <label className="text-xs font-medium text-gray-600">Validade *</label>
                <input type="date" className="mt-1 w-full rounded-lg border px-3 py-2 text-sm" value={form.expiryDate}
                  onChange={e => setForm(f => ({ ...f, expiryDate: e.target.value }))} required />
              </div>
              <div>
                <label className="text-xs font-medium text-gray-600">Preço de custo (R$)</label>
                <input type="number" step="0.01" min="0" className="mt-1 w-full rounded-lg border px-3 py-2 text-sm" value={form.costPrice}
                  onChange={e => setForm(f => ({ ...f, costPrice: e.target.value }))} />
              </div>
              <div>
                <label className="text-xs font-medium text-gray-600">Preço de venda (R$)</label>
                <input type="number" step="0.01" min="0" className="mt-1 w-full rounded-lg border px-3 py-2 text-sm" value={form.sellingPrice}
                  onChange={e => setForm(f => ({ ...f, sellingPrice: e.target.value }))} />
              </div>
              {error && <p className="sm:col-span-2 text-xs text-red-600">{error}</p>}
              <div className="sm:col-span-2 flex gap-2 pt-1">
                <button type="button" onClick={() => setShowForm(false)}
                  className="rounded-lg border px-4 py-2 text-sm">Cancelar</button>
                <button type="submit" disabled={saving}
                  className="rounded-lg bg-teal-600 hover:bg-teal-700 text-white px-5 py-2 text-sm font-medium disabled:opacity-60">
                  {saving ? "Salvandoâ€¦" : "Salvar"}
                </button>
              </div>
            </form>
          </div>
        )}

        {/* Lista */}
        {loading ? (
          <div className="text-sm text-gray-500 py-8 text-center">Carregandoâ€¦</div>
        ) : filtered.length === 0 ? (
          <div className="text-sm text-gray-500 py-8 text-center">
            {search ? "Nenhum resultado." : "Nenhum produto cadastrado."}
          </div>
        ) : (
          <div className="rounded-2xl bg-white border border-slate-100 shadow-sm overflow-hidden">
            <div className="text-xs text-gray-500 px-4 py-2 border-b bg-slate-50">
              {filtered.length} produto{filtered.length !== 1 ? "s" : ""}
            </div>
            <div className="divide-y divide-slate-50">
              {filtered.map(r => {
                const ms = r.expiryDate?.toMillis?.() ?? 0;
                return (
                  <div key={r.id} className="flex items-center gap-3 px-4 py-3 hover:bg-slate-50 transition-colors">
                    <div className="w-9 h-9 rounded-xl bg-teal-100 flex items-center justify-center text-teal-700 font-bold text-sm flex-shrink-0">
                      {r.brand.charAt(0)}
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="text-sm font-medium text-gray-900 truncate">{r.productName}</div>
                      <div className="text-xs text-gray-500">{r.brand}{r.sku ? ` â€¢ ${r.sku}` : ""}</div>
                    </div>
                    <div className="text-right flex-shrink-0">
                      <div className="text-sm font-semibold text-gray-900">{r.quantity} un</div>
                      {r.sellingPriceCents > 0 && (
                        <div className="text-xs text-gray-500">{formatMoney(r.sellingPriceCents)}</div>
                      )}
                    </div>
                    {ms > 0 && (
                      <span className={`text-xs font-medium px-2 py-1 rounded-lg flex-shrink-0 ${expiryClass(ms)}`}>
                        {expiryLabel(ms)}
                      </span>
                    )}
                    <button
                      onClick={() => handleDelete(r.id, r.productName)}
                      className="text-gray-300 hover:text-red-500 transition-colors flex-shrink-0 text-lg leading-none"
                      title="Excluir"
                    >×</button>
                  </div>
                );
              })}
            </div>
          </div>
        )}
      </div>
    </DashboardLayout>
  );
}

