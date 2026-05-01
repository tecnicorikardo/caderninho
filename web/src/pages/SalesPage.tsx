import { useEffect, useRef, useState } from "react";
import type { User } from "firebase/auth";
import {
  collection, getDocs, orderBy, query, limit, doc, getDoc
} from "firebase/firestore";
import DashboardLayout from "@/ui/DashboardLayout";
import { db } from "@/lib/firebase";
import { formatMoney, toCents } from "@/lib/money";
import { createSaleWithReceivables, type InstallmentPlan } from "@/lib/sales";
import { calculatePriceFromConfigured } from "@/lib/margins";
import type { BrandMargin, Customer, InventoryItem, PaymentType, SaleItem, UserProfile } from "@/lib/types";

type InvRow = InventoryItem & { id: string };
type CartItem = { inv: InvRow; qty: number };
type CustomerRow = Customer & { id: string };

const PAYMENT_LABELS: Record<PaymentType, string> = {
  cash: "Dinheiro",
  pix: "PIX",
  card: "Cartão",
  fiado: "Fiado (a prazo)",
  installments: "Parcelado",
};

const DEFAULT_MARGINS: BrandMargin[] = [
  { brand: "Natura", marginPercent: 30 },
  { brand: "Avon", marginPercent: 30 },
  { brand: "Casa & Estilo", marginPercent: 15 },
];

/** Gera plano de parcelas iguais a partir de hoje */
function buildInstallmentPlan(totalCents: number, numInstallments: number, firstDueDays: number): InstallmentPlan {
  const base = Math.floor(totalCents / numInstallments);
  const remainder = totalCents - base * numInstallments;
  const plan: InstallmentPlan = [];
  for (let i = 0; i < numInstallments; i++) {
    const dueDate = new Date();
    dueDate.setDate(dueDate.getDate() + firstDueDays + i * 30);
    plan.push({ dueDate, amountCents: base + (i === 0 ? remainder : 0) });
  }
  return plan;
}

export default function SalesPage({ user }: { user: User }) {
  const [inventory, setInventory] = useState<InvRow[]>([]);
  const [allCustomers, setAllCustomers] = useState<CustomerRow[]>([]);
  const [brandMargins, setBrandMargins] = useState<BrandMargin[]>(DEFAULT_MARGINS);
  const [cart, setCart] = useState<CartItem[]>([]);
  const [payment, setPayment] = useState<PaymentType>("cash");

  // Parcelamento
  const [numInstallments, setNumInstallments] = useState(2);
  const [firstDueDays, setFirstDueDays] = useState(30);
  const [downPayment, setDownPayment] = useState(""); // entrada em R$

  // Cliente — sempre obrigatório
  const [customerId, setCustomerId] = useState("");
  const [customerSearch, setCustomerSearch] = useState("");
  const [customerSuggestions, setCustomerSuggestions] = useState<CustomerRow[]>([]);
  const [showSuggestions, setShowSuggestions] = useState(false);

  const [saving, setSaving] = useState(false);
  const [msg, setMsg] = useState<{ type: "ok" | "err"; text: string } | null>(null);
  const [search, setSearch] = useState("");
  const [recentSales, setRecentSales] = useState<Array<{ id: string; total: number; date: string; items: number }>>([]);

  const customerInputRef = useRef<HTMLInputElement>(null);
  const suggestionsRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    async function load() {
      const profileSnap = await getDoc(doc(db, "users", user.uid));
      if (profileSnap.exists()) {
        const p = profileSnap.data() as UserProfile;
        if (p.brandMargins && p.brandMargins.length > 0) setBrandMargins(p.brandMargins);
      }

      const q = query(collection(db, "users", user.uid, "inventory"), orderBy("expiryDate", "asc"));
      const snap = await getDocs(q);
      setInventory(snap.docs
        .map(d => ({ id: d.id, ...(d.data() as InventoryItem) }))
        .filter(i => i.quantity > 0)
      );

      const custSnap = await getDocs(collection(db, "users", user.uid, "customers"));
      setAllCustomers(custSnap.docs.map(d => ({ id: d.id, ...(d.data() as Customer) })));

      const salesQ = query(collection(db, "users", user.uid, "sales"), orderBy("createdAt", "desc"), limit(10));
      const salesSnap = await getDocs(salesQ);
      setRecentSales(salesSnap.docs.map(d => {
        const data = d.data();
        const date = data.createdAt?.toDate?.()?.toLocaleDateString("pt-BR") ?? "—";
        return { id: d.id, total: data.totalCents ?? 0, date, items: (data.items ?? []).length };
      }));
    }
    load().catch(console.error);
  }, [user.uid]);

  // Fechar sugestões ao clicar fora
  useEffect(() => {
    function handleClickOutside(e: MouseEvent) {
      if (
        suggestionsRef.current && !suggestionsRef.current.contains(e.target as Node) &&
        customerInputRef.current && !customerInputRef.current.contains(e.target as Node)
      ) {
        setShowSuggestions(false);
      }
    }
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  function handleCustomerInput(value: string) {
    setCustomerSearch(value);
    setCustomerId("");
    if (value.length >= 2) {
      const lower = value.toLowerCase().trim();
      const matches = allCustomers.filter(c => {
        const nameLower = c.name.toLowerCase();
        const phoneDig = c.phone.replace(/\D/g, "");
        const valueDig = value.replace(/\D/g, "");
        return nameLower.startsWith(lower) ||
               nameLower.split(" ").some(word => word.startsWith(lower)) ||
               (valueDig.length >= 2 && phoneDig.includes(valueDig));
      }).slice(0, 6);
      setCustomerSuggestions(matches);
      setShowSuggestions(true);
    } else {
      setCustomerSuggestions([]);
      setShowSuggestions(false);
    }
  }

  function selectCustomer(c: CustomerRow) {
    setCustomerId(c.id);
    setCustomerSearch(c.name);
    setShowSuggestions(false);
  }

  function addToCart(inv: InvRow) {
    setCart(c => {
      const existing = c.find(x => x.inv.id === inv.id);
      if (existing) {
        if (existing.qty >= inv.quantity) return c;
        return c.map(x => x.inv.id === inv.id ? { ...x, qty: x.qty + 1 } : x);
      }
      return [...c, { inv, qty: 1 }];
    });
  }

  function removeFromCart(id: string) {
    setCart(c => c.filter(x => x.inv.id !== id));
  }

  function updateQty(id: string, qty: number) {
    if (qty <= 0) { removeFromCart(id); return; }
    setCart(c => c.map(x => x.inv.id === id ? { ...x, qty: Math.min(qty, x.inv.quantity) } : x));
  }

  const totalCents = cart.reduce((sum, x) => sum + x.inv.sellingPriceCents * x.qty, 0);
  const totalCostCents = cart.reduce((sum, x) => sum + x.inv.costPriceCents * x.qty, 0);
  const lucro = totalCents - totalCostCents;
  const margem = totalCents > 0 ? ((lucro / totalCents) * 100).toFixed(1) : "0.0";

  // Preview das parcelas
  const downPaymentCents = toCents(downPayment);
  const remainingAfterDown = Math.max(0, totalCents - downPaymentCents);

  // Para parcelado: parcela a entrada do restante
  const installmentPlanPreview = payment === "installments" && totalCents > 0
    ? buildInstallmentPlan(remainingAfterDown, numInstallments, firstDueDays)
    : [];

  const filtered = inventory.filter(i =>
    i.productName.toLowerCase().includes(search.toLowerCase()) ||
    i.brand.toLowerCase().includes(search.toLowerCase())
  );

  const sixty = Date.now() + 60 * 24 * 60 * 60 * 1000;

  async function handleSale() {
    if (cart.length === 0) {
      setMsg({ type: "err", text: "Adicione produtos ao carrinho." });
      return;
    }
    if (!customerId) {
      setMsg({ type: "err", text: "Selecione um cliente antes de finalizar." });
      customerInputRef.current?.focus();
      return;
    }

    setSaving(true);
    setMsg(null);
    try {
      const items: SaleItem[] = cart.map(x => ({
        inventoryId: x.inv.id,
        productId: x.inv.productId,
        productName: x.inv.productName,
        brand: x.inv.brand,
        quantity: x.qty,
        unitPriceCents: x.inv.sellingPriceCents,
        unitCostCents: x.inv.costPriceCents,
        expiryDate: x.inv.expiryDate,
      }));

      const installments = payment === "installments"
        ? buildInstallmentPlan(remainingAfterDown, numInstallments, firstDueDays)
        : undefined;

      await createSaleWithReceivables({
        uid: user.uid,
        customerId,
        items,
        totalCents,
        paidCents: payment === "fiado" || payment === "installments"
          ? downPaymentCents
          : totalCents,
        paymentType: payment,
        installments,
      });

      const parcelasInfo = payment === "installments"
        ? ` | ${numInstallments}x de ${formatMoney(Math.round(remainingAfterDown / numInstallments))}`
        : "";
      const entradaInfo = downPaymentCents > 0 && (payment === "fiado" || payment === "installments")
        ? ` (entrada: ${formatMoney(downPaymentCents)})`
        : "";

      setMsg({ type: "ok", text: `Venda registrada! Total: ${formatMoney(totalCents)}${entradaInfo}${parcelasInfo} | Lucro: ${formatMoney(lucro)}` });
      setCart([]);
      setCustomerSearch("");
      setCustomerId("");
      setPayment("cash");
      setDownPayment("");

      // Recarregar estoque
      const q = query(collection(db, "users", user.uid, "inventory"), orderBy("expiryDate", "asc"));
      const snap = await getDocs(q);
      setInventory(snap.docs.map(d => ({ id: d.id, ...(d.data() as InventoryItem) })).filter(i => i.quantity > 0));
    } catch (e) {
      setMsg({ type: "err", text: e instanceof Error ? e.message : "Erro ao registrar venda." });
    } finally {
      setSaving(false);
    }
  }

  return (
    <DashboardLayout title="Vendas">
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">

        {/* Catálogo */}
        <div className="lg:col-span-2 space-y-3">
          <input
            className="inp"
            placeholder="Buscar produto…"
            value={search}
            onChange={e => setSearch(e.target.value)}
          />

          <div className="rounded-2xl bg-white border border-slate-100 shadow-sm overflow-hidden">
            <div className="text-xs text-gray-500 px-4 py-2 border-b bg-slate-50">
              {filtered.length} produto{filtered.length !== 1 ? "s" : ""} disponíveis
            </div>
            <div className="divide-y divide-slate-50 max-h-[420px] overflow-y-auto">
              {filtered.map(inv => {
                const ms = inv.expiryDate?.toMillis?.() ?? 0;
                const expiring = ms > 0 && ms <= sixty;
                const suggested = calculatePriceFromConfigured(inv.costPriceCents, inv.brand, brandMargins);
                const inCart = cart.find(x => x.inv.id === inv.id);

                return (
                  <div key={inv.id} className={`flex items-center gap-3 px-4 py-3 hover:bg-slate-50 transition-colors ${expiring ? "bg-orange-50" : ""}`}>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 flex-wrap">
                        <span className="text-sm font-medium text-gray-900 truncate">{inv.productName}</span>
                        <span className="text-xs bg-slate-100 text-slate-600 px-1.5 py-0.5 rounded">{inv.brand}</span>
                        {expiring && <span className="text-xs bg-orange-100 text-orange-700 px-1.5 py-0.5 rounded-md">⚠ Vence em breve</span>}
                      </div>
                      <div className="text-xs text-gray-500">{inv.quantity} un • Sugerido: {formatMoney(suggested)}</div>
                    </div>
                    <div className="text-right flex-shrink-0">
                      <div className="text-sm font-semibold text-teal-700">{formatMoney(inv.sellingPriceCents)}</div>
                      <div className="text-xs text-gray-400">custo {formatMoney(inv.costPriceCents)}</div>
                    </div>
                    <button
                      onClick={() => addToCart(inv)}
                      disabled={!!inCart && inCart.qty >= inv.quantity}
                      className="w-8 h-8 rounded-lg bg-teal-600 hover:bg-teal-700 text-white text-lg font-bold disabled:opacity-40 transition-colors flex-shrink-0 flex items-center justify-center"
                    >+</button>
                  </div>
                );
              })}
              {filtered.length === 0 && (
                <div className="text-sm text-gray-400 text-center py-8">Nenhum produto disponível.</div>
              )}
            </div>
          </div>
        </div>

        {/* Carrinho */}
        <div className="space-y-3">
          <div className="rounded-2xl bg-white border border-slate-100 shadow-sm p-4 space-y-3">
            <h2 className="text-base font-semibold">Carrinho</h2>

            {/* Cliente — sempre obrigatório */}
            <div className="relative">
              <label className="text-xs font-medium text-gray-600 flex items-center gap-1">
                Cliente *
                {customerId
                  ? <span className="text-teal-600">✓ selecionado</span>
                  : <span className="text-red-400">obrigatório</span>
                }
              </label>
              <input
                ref={customerInputRef}
                className={`inp ${customerId ? "border-teal-500 bg-teal-50" : ""}`}
                value={customerSearch}
                onChange={e => handleCustomerInput(e.target.value)}
                onFocus={() => customerSearch.length >= 2 && setShowSuggestions(true)}
                placeholder="Digite o nome do cliente…"
                autoComplete="off"
              />
              {showSuggestions && customerSuggestions.length > 0 && (
                <div
                  ref={suggestionsRef}
                  className="absolute z-20 left-0 right-0 mt-1 bg-white border border-slate-200 rounded-xl shadow-lg overflow-hidden"
                >
                  {customerSuggestions.map(c => (
                    <button
                      key={c.id}
                      type="button"
                      onMouseDown={e => { e.preventDefault(); selectCustomer(c); }}
                      className="w-full text-left px-4 py-3 hover:bg-teal-50 active:bg-teal-100 transition-colors border-b border-slate-50 last:border-0"
                    >
                      <div className="text-sm font-medium text-gray-900">{c.name}</div>
                      <div className="text-xs text-gray-500">{c.phone}</div>
                    </button>
                  ))}
                </div>
              )}
              {showSuggestions && customerSearch.length >= 2 && customerSuggestions.length === 0 && (
                <div className="absolute z-20 left-0 right-0 mt-1 bg-white border border-slate-200 rounded-xl shadow-lg px-4 py-3 text-sm text-gray-400">
                  Nenhum cliente encontrado.
                </div>
              )}
            </div>

            {/* Itens do carrinho */}
            {cart.length === 0 ? (
              <div className="text-sm text-gray-400 text-center py-3">Nenhum item adicionado.</div>
            ) : (
              <div className="space-y-2">
                {cart.map(({ inv, qty }) => (
                  <div key={inv.id} className="flex items-center gap-2 text-sm">
                    <div className="flex-1 min-w-0">
                      <div className="truncate font-medium text-gray-800">{inv.productName}</div>
                      <div className="text-xs text-gray-500">{inv.brand} • {formatMoney(inv.sellingPriceCents)} × {qty}</div>
                    </div>
                    <div className="flex items-center gap-1">
                      <button onClick={() => updateQty(inv.id, qty - 1)} className="w-6 h-6 rounded bg-slate-100 hover:bg-slate-200 text-sm font-bold">−</button>
                      <span className="w-6 text-center text-sm">{qty}</span>
                      <button onClick={() => updateQty(inv.id, qty + 1)} className="w-6 h-6 rounded bg-slate-100 hover:bg-slate-200 text-sm font-bold">+</button>
                    </div>
                    <button onClick={() => removeFromCart(inv.id)} className="text-gray-300 hover:text-red-500 text-lg leading-none">×</button>
                  </div>
                ))}
              </div>
            )}

            {/* Totais */}
            <div className="border-t pt-3 space-y-1 text-sm">
              <div className="flex justify-between text-gray-600">
                <span>Total</span>
                <span className="font-semibold text-gray-900">{formatMoney(totalCents)}</span>
              </div>
              <div className="flex justify-between text-gray-500 text-xs">
                <span>Custo</span>
                <span>{formatMoney(totalCostCents)}</span>
              </div>
              <div className="flex justify-between text-green-700 font-semibold">
                <span>Lucro ({margem}%)</span>
                <span>{formatMoney(lucro)}</span>
              </div>
            </div>

            {/* Pagamento */}
            <div>
              <label className="inp-label">Forma de pagamento</label>
              <select
                className="inp-select"
                value={payment}
                onChange={e => { setPayment(e.target.value as PaymentType); setDownPayment(""); }}
              >
                {(Object.keys(PAYMENT_LABELS) as PaymentType[]).map(k => (
                  <option key={k} value={k}>{PAYMENT_LABELS[k]}</option>
                ))}
              </select>
            </div>

            {/* Fiado */}
            {payment === "fiado" && (
              <div className="space-y-2">
                <div>
                  <label className="inp-label">
                    Entrada recebida agora (R$)
                    <span className="text-gray-400 font-normal ml-1">— opcional</span>
                  </label>
                  <input
                    type="text"
                    inputMode="decimal"
                    placeholder="Ex: 50,00"
                    className="inp"
                    value={downPayment}
                    onChange={e => setDownPayment(e.target.value)}
                  />
                </div>
                <div className="rounded-xl bg-orange-50 border border-orange-100 px-3 py-2.5 text-xs text-orange-700 space-y-0.5">
                  {downPaymentCents > 0 && (
                    <div>✅ Entrada: <strong>{formatMoney(downPaymentCents)}</strong></div>
                  )}
                  <div>
                    💳 Restante a receber: <strong>{formatMoney(Math.max(0, totalCents - downPaymentCents))}</strong>
                    {" "}— vence em 30 dias
                  </div>
                </div>
              </div>
            )}

            {/* Parcelado — configuração + preview */}
            {payment === "installments" && (
              <div className="space-y-3">
                {/* Aviso visual de que há configurações abaixo */}
                <div className="rounded-xl bg-blue-50 border border-blue-200 px-3 py-2 text-xs text-blue-700 font-medium">
                  📅 Configure as parcelas abaixo antes de finalizar
                </div>
                {/* Entrada */}
                <div>
                  <label className="inp-label">
                    Entrada recebida agora (R$)
                    <span className="text-gray-400 font-normal ml-1">— opcional</span>
                  </label>
                  <input
                    type="text"
                    inputMode="decimal"
                    placeholder="Ex: 50,00"
                    className="inp"
                    value={downPayment}
                    onChange={e => setDownPayment(e.target.value)}
                  />
                  {downPaymentCents > 0 && (
                    <div className="text-xs text-teal-600 mt-1">
                      Restante a parcelar: <strong>{formatMoney(remainingAfterDown)}</strong>
                    </div>
                  )}
                </div>
                <div className="grid grid-cols-2 gap-2">
                  <div>
                    <label className="inp-label">Nº de parcelas</label>
                    <select
                      className="inp-select"
                      value={numInstallments}
                      onChange={e => setNumInstallments(Number(e.target.value))}
                    >
                      {[2,3,4,5,6,8,10,12].map(n => (
                        <option key={n} value={n}>{n}x de {totalCents > 0 ? formatMoney(Math.round(totalCents / n)) : "—"}</option>
                      ))}
                    </select>
                  </div>
                  <div>
                    <label className="inp-label">1ª parcela em</label>
                    <select
                      className="inp-select"
                      value={firstDueDays}
                      onChange={e => setFirstDueDays(Number(e.target.value))}
                    >
                      <option value={7}>7 dias</option>
                      <option value={15}>15 dias</option>
                      <option value={30}>30 dias</option>
                    </select>
                  </div>
                </div>

                {/* Preview das parcelas */}
                {installmentPlanPreview.length > 0 && (
                  <div className="rounded-xl bg-blue-50 border border-blue-100 p-3">
                    <div className="text-xs font-medium text-blue-700 mb-2">📅 Parcelas geradas:</div>
                    <div className="space-y-1">
                      {installmentPlanPreview.map((inst, i) => (
                        <div key={i} className="flex justify-between text-xs text-blue-700">
                          <span>{i + 1}ª parcela — {inst.dueDate.toLocaleDateString("pt-BR")}</span>
                          <span className="font-semibold">{formatMoney(inst.amountCents)}</span>
                        </div>
                      ))}
                    </div>
                  </div>
                )}
              </div>
            )}

            {msg && (
              <div className={`text-xs p-2.5 rounded-lg ${msg.type === "ok" ? "bg-green-50 text-green-700" : "bg-red-50 text-red-700"}`}>
                {msg.text}
              </div>
            )}

            <button
              onClick={handleSale}
              disabled={saving || cart.length === 0}
              className="w-full rounded-xl bg-teal-600 hover:bg-teal-700 text-white py-3 text-sm font-semibold disabled:opacity-50 transition-colors"
            >
              {saving ? "Registrando…" : "Finalizar Venda"}
            </button>
          </div>

          {/* Vendas recentes */}
          {recentSales.length > 0 && (
            <div className="rounded-2xl bg-white border border-slate-100 shadow-sm p-4">
              <h3 className="text-sm font-semibold text-gray-700 mb-2">Vendas recentes</h3>
              <div className="space-y-1">
                {recentSales.map(s => (
                  <div key={s.id} className="flex justify-between text-xs text-gray-600 py-1 border-b border-slate-50 last:border-0">
                    <span>{s.date} • {s.items} item{s.items !== 1 ? "s" : ""}</span>
                    <span className="font-semibold text-gray-800">{formatMoney(s.total)}</span>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      </div>
    </DashboardLayout>
  );
}
