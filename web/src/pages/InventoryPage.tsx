import { useEffect, useState } from "react";
import type { AppUser } from "@/App";
import { databases, DATABASE_ID, COLLECTIONS, Query } from "@/lib/appwrite";
import { ID } from "appwrite";
import { toDate, toMillis } from "@/lib/timestamp";
import { useSearchParams } from "react-router-dom";
import DashboardLayout from "@/ui/DashboardLayout";
import { formatMoney, toCents } from "@/lib/money";
import type { InventoryItem } from "@/lib/types";
import { processImageForStorage, ImageUploadError } from "@/lib/imageUpload";
import { PLAN_LIMITS, getUserPlan } from "@/lib/plan";
import PlanLimitBanner from "@/ui/PlanLimitBanner";

type Row = InventoryItem & { $id: string };

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

export default function InventoryPage({ user }: { user: AppUser }) {
  const [rows, setRows] = useState<Row[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null); // null = novo, string = editando
  const [form, setForm] = useState(EMPTY_FORM);
  const [saving, setSaving] = useState(false);
  const [search, setSearch] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [searchParams, setSearchParams] = useSearchParams();

  // Filtros rápidos
  const [brandFilter, setBrandFilter] = useState<string | null>(null);
  const [expiryStatusFilter, setExpiryStatusFilter] = useState<"expired" | "expiring" | null>(null);

  // Imagem do produto
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [imagePreview, setImagePreview] = useState<string | null>(null);
  const [imageStatus, setImageStatus] = useState<string | null>(null);
  const [keepExistingImage, setKeepExistingImage] = useState(true); // ao editar

  // Modo de visualização
  type ViewMode = "list" | "grid" | "grid-large";
  const [viewMode, setViewMode] = useState<ViewMode>("list");

  // Filtro de vencimento vindo da URL (?expiry=30|60|90)
  const expiryFilter = searchParams.get("expiry"); // "30" | "60" | "90" | null

  const EXPIRY_LABELS: Record<string, string> = {
    "30": "Vencem em menos de 30 dias",
    "60": "Vencem em menos de 60 dias",
    "90": "Vencem em menos de 90 dias",
  };

  async function load() {
    setLoading(true);
    const res = await databases.listDocuments(DATABASE_ID, COLLECTIONS.INVENTORY, [
      Query.equal("userId", user.uid),
      Query.orderAsc("expiryDate"),
      Query.limit(1000),
    ]);
    setRows(res.documents.map(d => ({ $id: d.$id, ...(d as unknown as InventoryItem) })));
    setLoading(false);
  }

  useEffect(() => { load().catch(() => setLoading(false)); }, [user.uid]);

  function openNew() {
    setEditingId(null);
    setForm(EMPTY_FORM);
    setImageFile(null);
    setImagePreview(null);
    setKeepExistingImage(true);
    setError(null);
    setShowForm(true);
  }

  function openEdit(r: Row) {
    setEditingId(r.$id);
    setForm({
      productName: r.productName,
      brand: r.brand,
      sku: r.sku ?? "",
      quantity: String(r.quantity),
      costPrice: r.costPriceCents > 0 ? (r.costPriceCents / 100).toFixed(2) : "",
      sellingPrice: r.sellingPriceCents > 0 ? (r.sellingPriceCents / 100).toFixed(2) : "",
      expiryDate: r.expiryDate ? toDate(r.expiryDate).toISOString().split("T")[0] : "",
    });
    setImageFile(null);
    setImagePreview(r.imageUrl ?? null);
    setKeepExistingImage(true);
    setError(null);
    setShowForm(true);
  }

  async function handleSave(e: React.FormEvent) {
    e.preventDefault();
    if (!form.productName || !form.quantity || !form.expiryDate) {
      setError("Preencha nome, quantidade e validade.");
      return;
    }
    setSaving(true);
    setError(null);
    try {
      // Processa imagem se selecionada
      let imageUrl: string | null = null;
      if (imageFile) {
        setImageStatus("Comprimindo imagem…");
        imageUrl = await processImageForStorage(imageFile, setImageStatus);
        setImageStatus(null);
      } else if (editingId && keepExistingImage) {
        // Mantém a imagem existente
        imageUrl = rows.find(r => r.$id === editingId)?.imageUrl ?? null;
      }

      const expiryDate = new Date(`${form.expiryDate}T00:00:00`).toISOString();
      const data = {
        sku: form.sku || null,
        productName: form.productName.trim(),
        brand: form.brand,
        quantity: Number(form.quantity),
        costPriceCents: toCents(form.costPrice),
        sellingPriceCents: toCents(form.sellingPrice),
        expiryDate,
        imageUrl: imageUrl ?? null,
        updatedAt: new Date().toISOString(),
      };

      if (editingId) {
        // EDITAR produto existente
        await databases.updateDocument(DATABASE_ID, COLLECTIONS.INVENTORY, editingId, data);
      } else {
        // CRIAR novo produto
        await databases.createDocument(DATABASE_ID, COLLECTIONS.INVENTORY, ID.unique(), {
          ...data,
          userId: user.uid,
          productId: `manual_${Date.now()}`,
          createdAt: new Date().toISOString(),
        });
      }

      setForm(EMPTY_FORM);
      setImageFile(null);
      setImagePreview(null);
      setEditingId(null);
      setShowForm(false);
      await load();
    } catch (err) {
      if (err instanceof ImageUploadError) {
        setError(err.message);
      } else {
        setError(err instanceof Error ? err.message : "Erro ao salvar.");
      }
    } finally {
      setSaving(false);
      setImageStatus(null);
    }
  }

  function handleImageChange(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) return;
    // Valida tipo antes de qualquer coisa
    const accepted = ["image/jpeg", "image/png", "image/webp"];
    if (!accepted.includes(file.type)) {
      setError("Formato inválido. Use JPG, PNG ou WebP.");
      e.target.value = "";
      return;
    }
    setError(null);
    setImageFile(file);
    // Preview imediato da imagem original
    const reader = new FileReader();
    reader.onload = () => setImagePreview(reader.result as string);
    reader.readAsDataURL(file);
  }

  async function handleDelete(id: string, name: string) {
    if (!confirm(`Excluir "${name}"?`)) return;
    await databases.deleteDocument(DATABASE_ID, COLLECTIONS.INVENTORY, id);
    setRows(r => r.filter(x => x.$id !== id));
  }

  const now = Date.now();
  const sixty = now + 60 * 24 * 60 * 60 * 1000;
  const ninety = now + 90 * 24 * 60 * 60 * 1000;

  // Marcas únicas presentes no estoque
  const brandsInStock = Array.from(new Set(rows.map(r => r.brand))).sort();

  const filtered = rows.filter(r => {
    // Filtro de texto
    const matchText =
      r.productName.toLowerCase().includes(search.toLowerCase()) ||
      r.brand.toLowerCase().includes(search.toLowerCase()) ||
      (r.sku ?? "").toLowerCase().includes(search.toLowerCase());
    if (!matchText) return false;

    // Filtro de marca (botões rápidos)
    if (brandFilter && r.brand !== brandFilter) return false;

    // Filtro de validade (botões rápidos)
    if (expiryStatusFilter) {
      const ms = toMillis(r.expiryDate);
      if (expiryStatusFilter === "expired" && ms > now) return false;
      if (expiryStatusFilter === "expiring" && (ms <= now || ms > sixty)) return false;
    }

    // Filtro de vencimento (vindo da URL)
    if (expiryFilter) {
      const ms = toMillis(r.expiryDate);
      const days = Number(expiryFilter);
      const cutoff = now + days * 24 * 60 * 60 * 1000;
      return ms > 0 && ms <= cutoff && r.quantity > 0;
    }

    return true;
  });

  const activeFiltersCount = (brandFilter ? 1 : 0) + (expiryStatusFilter ? 1 : 0) + (expiryFilter ? 1 : 0);

  // Limites do plano
  const plan = getUserPlan();
  const productLimit = PLAN_LIMITS[plan].products;
  const atProductLimit = rows.length >= productLimit;

  function clearAllFilters() {
    setBrandFilter(null);
    setExpiryStatusFilter(null);
    setSearchParams({});
  }

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
      <div className="space-y-4">
        {/* Toolbar */}
        <div className="flex flex-col sm:flex-row gap-3">
          <input
            className="inp flex-1"
            placeholder="Buscar produto, marca ou SKU…"
            value={search}
            onChange={e => setSearch(e.target.value)}
          />
          {/* Botões de modo de visualização */}
          <div className="flex gap-1 bg-white border border-slate-200 rounded-xl p-1 shadow-sm self-start sm:self-auto">
            <button
              onClick={() => setViewMode("list")}
              title="Lista"
              className={`px-2.5 py-1.5 rounded-lg text-sm transition-colors ${viewMode === "list" ? "bg-teal-600 text-white" : "text-gray-400 hover:text-gray-700"}`}
            >
              ☰
            </button>
            <button
              onClick={() => setViewMode("grid")}
              title="Ícones"
              className={`px-2.5 py-1.5 rounded-lg text-sm transition-colors ${viewMode === "grid" ? "bg-teal-600 text-white" : "text-gray-400 hover:text-gray-700"}`}
            >
              ⊞
            </button>
            <button
              onClick={() => setViewMode("grid-large")}
              title="Ícones grandes"
              className={`px-2.5 py-1.5 rounded-lg text-sm transition-colors ${viewMode === "grid-large" ? "bg-teal-600 text-white" : "text-gray-400 hover:text-gray-700"}`}
            >
              ◻
            </button>
          </div>
          <button
            onClick={openNew}
            disabled={atProductLimit}
            className="rounded-xl bg-teal-600 hover:bg-teal-700 text-white px-5 py-2.5 text-sm font-medium transition-colors shadow-sm disabled:opacity-50 disabled:cursor-not-allowed"
            title={atProductLimit ? `Limite de ${productLimit} produtos atingido` : undefined}
          >
            + Novo produto
          </button>
        </div>

        {/* Filtros rápidos */}
        <div className="flex flex-wrap gap-2 items-center">
          {/* Filtros por marca */}
          {brandsInStock.map(brand => (
            <button
              key={brand}
              onClick={() => setBrandFilter(brandFilter === brand ? null : brand)}
              className={`px-3 py-1.5 rounded-xl text-xs font-medium border transition-colors ${
                brandFilter === brand
                  ? "bg-teal-600 text-white border-teal-600"
                  : "bg-white text-gray-600 border-slate-200 hover:border-teal-300 hover:text-teal-700"
              }`}
            >
              {brand}
            </button>
          ))}

          {/* Separador visual se há marcas */}
          {brandsInStock.length > 0 && (
            <span className="w-px h-5 bg-slate-200 mx-1" />
          )}

          {/* Filtro: Vencidos */}
          <button
            onClick={() => setExpiryStatusFilter(expiryStatusFilter === "expired" ? null : "expired")}
            className={`px-3 py-1.5 rounded-xl text-xs font-medium border transition-colors ${
              expiryStatusFilter === "expired"
                ? "bg-red-600 text-white border-red-600"
                : "bg-white text-gray-600 border-slate-200 hover:border-red-300 hover:text-red-600"
            }`}
          >
            🔴 Vencidos
          </button>

          {/* Filtro: Vencendo em breve */}
          <button
            onClick={() => setExpiryStatusFilter(expiryStatusFilter === "expiring" ? null : "expiring")}
            className={`px-3 py-1.5 rounded-xl text-xs font-medium border transition-colors ${
              expiryStatusFilter === "expiring"
                ? "bg-orange-500 text-white border-orange-500"
                : "bg-white text-gray-600 border-slate-200 hover:border-orange-300 hover:text-orange-600"
            }`}
          >
            🟠 Vence em 60d
          </button>

          {/* Limpar todos os filtros */}
          {activeFiltersCount > 0 && (
            <button
              onClick={clearAllFilters}
              className="px-3 py-1.5 rounded-xl text-xs font-medium text-gray-400 hover:text-gray-700 underline transition-colors ml-1"
            >
              Limpar filtros
            </button>
          )}
        </div>

        {/* Banner de limite do plano */}
        <PlanLimitBanner current={rows.length} limit={productLimit} label="produtos" />

        {/* Banner de filtro de vencimento via URL */}
        {expiryFilter && (
          <div className={`rounded-xl border px-4 py-3 flex items-center justify-between ${
            expiryFilter === "30" ? "bg-red-50 border-red-200 text-red-700" :
            expiryFilter === "60" ? "bg-orange-50 border-orange-200 text-orange-700" :
            "bg-yellow-50 border-yellow-200 text-yellow-700"
          }`}>
            <div className="flex items-center gap-2">
              <span className="text-base">{expiryFilter === "30" ? "🔴" : expiryFilter === "60" ? "🟠" : "🟡"}</span>
              <span className="text-sm font-medium">{EXPIRY_LABELS[expiryFilter]}</span>
              <span className="text-xs opacity-70">— {filtered.length} produto{filtered.length !== 1 ? "s" : ""}</span>
            </div>
            <button
              onClick={() => setSearchParams({})}
              className="text-xs font-medium underline opacity-70 hover:opacity-100"
            >
              Limpar filtro
            </button>
          </div>
        )}

        {/* Formulário — novo ou edição */}
        {showForm && (
          <div className="card-brand p-5">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-base font-bold">
                {editingId ? "✏️ Editar produto" : "Novo produto no estoque"}
              </h2>
              <button type="button" onClick={() => setShowForm(false)}
                className="text-gray-400 hover:text-gray-700 text-xl leading-none">×</button>
            </div>
            <form onSubmit={handleSave} className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div className="sm:col-span-2">
                <label className="inp-label">Nome do produto *</label>
                <input className="inp" value={form.productName}
                  onChange={e => setForm(f => ({ ...f, productName: e.target.value }))} required />
              </div>
              <div>
                <label className="inp-label">Marca *</label>
                <select className="inp-select" value={form.brand}
                  onChange={e => setForm(f => ({ ...f, brand: e.target.value }))}>
                  {BRANDS.map(b => <option key={b}>{b}</option>)}
                </select>
              </div>
              <div>
                <label className="inp-label">SKU / Código</label>
                <input className="inp" placeholder="Opcional" value={form.sku}
                  onChange={e => setForm(f => ({ ...f, sku: e.target.value }))} />
              </div>
              <div>
                <label className="inp-label">Quantidade *</label>
                <input type="number" min="1" className="inp" placeholder="Ex: 10" value={form.quantity}
                  onChange={e => setForm(f => ({ ...f, quantity: e.target.value }))} required />
              </div>
              <div>
                <label className="inp-label">Validade *</label>
                <input type="date" className="inp" value={form.expiryDate}
                  onChange={e => setForm(f => ({ ...f, expiryDate: e.target.value }))} required />
              </div>
              <div>
                <label className="inp-label">Preço de custo (R$)</label>
                <input type="number" step="0.01" min="0" className="inp" placeholder="Ex: 25,00" value={form.costPrice}
                  onChange={e => setForm(f => ({ ...f, costPrice: e.target.value }))} />
              </div>
              <div>
                <label className="inp-label">Preço de venda (R$)</label>
                <input type="number" step="0.01" min="0" className="inp" placeholder="Ex: 40,00" value={form.sellingPrice}
                  onChange={e => setForm(f => ({ ...f, sellingPrice: e.target.value }))} />
              </div>

              {/* Foto do produto */}
              <div className="sm:col-span-2">
                <label className="inp-label">
                  Foto do produto
                  <span className="text-gray-400 font-normal normal-case ml-1">— opcional, JPG/PNG/WebP</span>
                </label>
                <div className="mt-1 flex items-center gap-3">
                  {/* Preview */}
                  {imagePreview ? (
                    <div className="relative flex-shrink-0">
                      <img src={imagePreview} alt="Preview"
                        className="w-20 h-20 rounded-xl object-cover border-2 border-teal-200" />
                      <button type="button"
                        onClick={() => { setImageFile(null); setImagePreview(null); setKeepExistingImage(false); }}
                        className="absolute -top-1.5 -right-1.5 w-5 h-5 rounded-full bg-red-500 text-white text-xs flex items-center justify-center"
                        title="Remover foto">×</button>
                    </div>
                  ) : (
                    <div className="w-20 h-20 rounded-xl border-2 border-dashed border-slate-300 flex items-center justify-center text-slate-300 text-3xl flex-shrink-0">
                      📷
                    </div>
                  )}
                  <div className="flex-1">
                    <input type="file" accept="image/jpeg,image/png,image/webp"
                      onChange={handleImageChange}
                      className="text-sm text-gray-600 file:mr-3 file:py-2 file:px-3 file:rounded-lg file:border-0 file:bg-teal-50 file:text-teal-700 file:text-xs file:font-semibold hover:file:bg-teal-100 cursor-pointer" />
                    {editingId && imagePreview && !imageFile && (
                      <p className="text-xs text-gray-400 mt-1">Foto atual mantida. Selecione outra para substituir.</p>
                    )}
                  </div>
                </div>
                {imageStatus && (
                  <p className="mt-1.5 text-xs text-teal-600 flex items-center gap-1">
                    <span className="animate-spin inline-block">⏳</span> {imageStatus}
                  </p>
                )}
              </div>

              {error && <p className="sm:col-span-2 text-xs text-red-600 font-semibold">{error}</p>}
              <div className="sm:col-span-2 flex gap-2 pt-1">
                <button type="button" onClick={() => setShowForm(false)}
                  className="rounded-xl border-2 border-slate-300 px-4 py-2.5 text-sm font-semibold text-gray-600 hover:bg-slate-50">
                  Cancelar
                </button>
                <button type="submit" disabled={saving}
                  className="rounded-xl bg-teal-600 hover:bg-teal-700 text-white px-6 py-2.5 text-sm font-bold disabled:opacity-60">
                  {saving ? (imageStatus ?? "Salvando…") : editingId ? "Salvar alterações" : "Adicionar produto"}
                </button>
              </div>
            </form>
          </div>
        )}

        {/* Produtos */}
        {loading ? (
          <div className="text-sm text-gray-500 py-8 text-center">Carregando…</div>
        ) : filtered.length === 0 ? (
          <div className="text-sm text-gray-500 py-8 text-center">
            {search ? "Nenhum resultado." : "Nenhum produto cadastrado."}
          </div>
        ) : viewMode === "list" ? (

          /* ── MODO LISTA ── */
          <div className="card-brand overflow-hidden">
            <div className="text-xs text-gray-500 px-4 py-2 border-b bg-slate-50">
              {filtered.length} produto{filtered.length !== 1 ? "s" : ""}
            </div>
            <div className="divide-y divide-slate-50">
              {filtered.map(r => {
                const ms = toMillis(r.expiryDate);
                return (
                  <div key={r.$id} className="flex items-center gap-3 px-4 py-3 hover:bg-slate-50 transition-colors">
                    {r.imageUrl ? (
                      <img src={r.imageUrl} alt={r.productName} className="w-9 h-9 rounded-xl object-cover flex-shrink-0 border border-slate-100" />
                    ) : (
                      <div className="w-9 h-9 rounded-xl bg-teal-100 flex items-center justify-center text-teal-700 font-bold text-sm flex-shrink-0">
                        {r.brand.charAt(0)}
                      </div>
                    )}
                    <div className="flex-1 min-w-0">
                      <div className="text-sm font-medium text-gray-900 truncate">{r.productName}</div>
                      <div className="text-xs text-gray-500">{r.brand}{r.sku ? ` • ${r.sku}` : ""}</div>
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
                    <button onClick={() => openEdit(r)}
                      className="text-gray-400 hover:text-teal-600 transition-colors flex-shrink-0 text-sm px-1.5 py-1 rounded-lg hover:bg-teal-50"
                      title="Editar">✏️</button>
                    <button onClick={() => handleDelete(r.$id, r.productName)}
                      className="text-gray-300 hover:text-red-500 transition-colors flex-shrink-0 text-lg leading-none" title="Excluir">×</button>
                  </div>
                );
              })}
            </div>
          </div>

        ) : viewMode === "grid" ? (

          /* ── MODO ÍCONES (grid pequeno) ── */
          <>
            <div className="text-xs text-gray-500 px-1">{filtered.length} produto{filtered.length !== 1 ? "s" : ""}</div>
            <div className="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-5 lg:grid-cols-6 gap-3">
              {filtered.map(r => {
                const ms = toMillis(r.expiryDate);
                return (
                  <div key={r.$id} className="relative bg-white rounded-2xl border border-slate-100 shadow-sm overflow-hidden hover:shadow-md transition-shadow group">
                    {/* Imagem ou placeholder */}
                    <div className="aspect-square w-full bg-slate-50 flex items-center justify-center overflow-hidden">
                      {r.imageUrl ? (
                        <img src={r.imageUrl} alt={r.productName} className="w-full h-full object-cover" />
                      ) : (
                        <span className="text-3xl font-bold text-teal-200">{r.brand.charAt(0)}</span>
                      )}
                    </div>
                    {/* Badge de validade */}
                    {ms > 0 && (
                      <span className={`absolute top-1.5 left-1.5 text-[10px] font-bold px-1.5 py-0.5 rounded-md ${expiryClass(ms)}`}>
                        {expiryLabel(ms)}
                      </span>
                    )}
                    {/* Botões ação — aparecem no hover */}
                    <div className="absolute top-1.5 right-1.5 flex gap-1 opacity-0 group-hover:opacity-100 transition-all">
                      <button onClick={() => openEdit(r)}
                        className="w-6 h-6 rounded-full bg-white/90 text-teal-600 hover:bg-teal-50 text-xs flex items-center justify-center shadow-sm"
                        title="Editar">✏️</button>
                      <button onClick={() => handleDelete(r.$id, r.productName)}
                        className="w-6 h-6 rounded-full bg-white/90 text-gray-400 hover:text-red-500 hover:bg-white text-xs flex items-center justify-center shadow-sm"
                        title="Excluir">×</button>
                    </div>
                    {/* Info */}
                    <div className="p-2">
                      <div className="text-xs font-semibold text-gray-900 truncate leading-tight">{r.productName}</div>
                      <div className="text-[10px] text-gray-400 truncate">{r.brand}</div>
                      <div className="flex items-center justify-between mt-1">
                        <span className="text-[10px] font-medium text-teal-700">{r.quantity} un</span>
                        {r.sellingPriceCents > 0 && (
                          <span className="text-[10px] text-gray-500">{formatMoney(r.sellingPriceCents)}</span>
                        )}
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          </>

        ) : (

          /* ── MODO ÍCONES GRANDES ── */
          <>
            <div className="text-xs text-gray-500 px-1">{filtered.length} produto{filtered.length !== 1 ? "s" : ""}</div>
            <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-4">
              {filtered.map(r => {
                const ms = toMillis(r.expiryDate);
                return (
                  <div key={r.$id} className="relative bg-white rounded-2xl border border-slate-100 shadow-sm overflow-hidden hover:shadow-md transition-shadow group">
                    {/* Imagem grande ou placeholder */}
                    <div className="aspect-square w-full bg-slate-50 flex items-center justify-center overflow-hidden">
                      {r.imageUrl ? (
                        <img src={r.imageUrl} alt={r.productName} className="w-full h-full object-cover" />
                      ) : (
                        <div className="flex flex-col items-center gap-1">
                          <span className="text-5xl font-bold text-teal-200">{r.brand.charAt(0)}</span>
                          <span className="text-xs text-teal-300">{r.brand}</span>
                        </div>
                      )}
                    </div>
                    {/* Badge de validade */}
                    {ms > 0 && (
                      <span className={`absolute top-2 left-2 text-xs font-bold px-2 py-1 rounded-lg ${expiryClass(ms)}`}>
                        {expiryLabel(ms)}
                      </span>
                    )}
                    {/* Botões ação — aparecem no hover */}
                    <div className="absolute top-2 right-2 flex gap-1 opacity-0 group-hover:opacity-100 transition-all">
                      <button onClick={() => openEdit(r)}
                        className="w-7 h-7 rounded-full bg-white/90 text-teal-600 hover:bg-teal-50 text-sm flex items-center justify-center shadow"
                        title="Editar">✏️</button>
                      <button onClick={() => handleDelete(r.$id, r.productName)}
                        className="w-7 h-7 rounded-full bg-white/90 text-gray-400 hover:text-red-500 hover:bg-white text-base flex items-center justify-center shadow"
                        title="Excluir">×</button>
                    </div>
                    {/* Info detalhada */}
                    <div className="p-3 space-y-1">
                      <div className="text-sm font-semibold text-gray-900 leading-tight">{r.productName}</div>
                      <div className="flex items-center gap-1.5 flex-wrap">
                        <span className="text-xs bg-slate-100 text-slate-600 px-1.5 py-0.5 rounded">{r.brand}</span>
                        {r.sku && <span className="text-xs text-gray-400">{r.sku}</span>}
                      </div>
                      <div className="flex items-center justify-between pt-1">
                        <span className="text-sm font-bold text-teal-700">{r.quantity} un</span>
                        {r.sellingPriceCents > 0 && (
                          <span className="text-sm font-semibold text-gray-800">{formatMoney(r.sellingPriceCents)}</span>
                        )}
                      </div>
                      {r.costPriceCents > 0 && (
                        <div className="text-xs text-gray-400">custo {formatMoney(r.costPriceCents)}</div>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          </>
        )}
      </div>
    </DashboardLayout>
  );
}

