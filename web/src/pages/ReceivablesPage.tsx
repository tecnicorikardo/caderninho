import { useEffect, useState } from "react";
import type { User } from "firebase/auth";
import { collection, getDocs, query, orderBy, doc, serverTimestamp, runTransaction, updateDoc, Timestamp } from "firebase/firestore";
import DashboardLayout from "@/ui/DashboardLayout";
import { db } from "@/lib/firebase";
import { formatMoney, toCents } from "@/lib/money";
import type { Receivable, ReceivableStatus, Customer } from "@/lib/types";

const STATUS_LABELS: Record<ReceivableStatus, string> = { pending: "Pendente", partial: "Parcial", paid: "Pago", late: "Atrasado" };
const STATUS_COLORS: Record<ReceivableStatus, string> = { pending: "bg-yellow-100 text-yellow-800", partial: "bg-blue-100 text-blue-800", paid: "bg-green-100 text-green-800", late: "bg-red-100 text-red-800" };

type RecRow = Receivable & { id: string; daysLate: number; isOverdue: boolean };
type Group = { customerId: string; name: string; phone: string; totalOwed: number; overdueAmount: number; rows: RecRow[] };
type ModalMode = "list" | "paySelected" | "payAll" | "partial" | "changeDate";

function computeStatus(amount: number, paid: number): ReceivableStatus {
  if (paid <= 0) return "pending";
  if (paid >= amount) return "paid";
  return "partial";
}

function CustomerModal({ group, onClose, onRefresh, uid }: { group: Group; onClose: () => void; onRefresh: () => void; uid: string }) {
  const open = group.rows.filter(r => r.status !== "paid");
  const [mode, setMode] = useState<ModalMode>("list");
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [partialRow, setPartialRow] = useState<RecRow | null>(null);
  const [partialAmount, setPartialAmount] = useState("");
  // Reparcelamento do restante (sobre o total da dívida)
  const [reParcelNum, setReParcelNum] = useState(1);
  const [reParcelFirstDays, setReParcelFirstDays] = useState(30);
  // Total da dívida aberta (todas as parcelas)
  const totalOwedOpen = open.reduce((s, r) => s + (r.amountCents - r.paidCents), 0);
  const [changeDateId, setChangeDateId] = useState<string | null>(null);
  const [newDate, setNewDate] = useState("");
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState("");

  const selectedRows = open.filter(r => selected.has(r.id));
  const selectedTotal = selectedRows.reduce((s, r) => s + (r.amountCents - r.paidCents), 0);

  function toggleSelect(id: string) {
    setSelected(prev => { const next = new Set(prev); next.has(id) ? next.delete(id) : next.add(id); return next; });
  }
  function back() { setMode("list"); setErr(""); }

  async function handlePaySelected() {
    if (selectedRows.length === 0) { setErr('Selecione ao menos uma parcela.'); return; }
    setBusy(true); setErr('');
    try {
      const custRef = doc(db, 'users', uid, 'customers', group.customerId);
      await runTransaction(db, async tx => {
        const snap = await tx.get(custRef);
        const bal = snap.exists() ? Number((snap.data() as Customer).balanceCents ?? 0) : 0;
        for (const r of selectedRows) {
          tx.update(doc(db, 'users', uid, 'receivables', r.id), { paidCents: r.amountCents, status: 'paid', updatedAt: serverTimestamp() });
        }
        tx.update(custRef, { balanceCents: Math.max(0, bal - selectedTotal), updatedAt: serverTimestamp() });
      });
      onRefresh();
    } catch { setErr('Erro ao registrar.'); setBusy(false); }
  }

  async function handlePayAll() {
    setBusy(true); setErr('');
    try {
      const custRef = doc(db, 'users', uid, 'customers', group.customerId);
      await runTransaction(db, async tx => {
        const snap = await tx.get(custRef);
        const bal = snap.exists() ? Number((snap.data() as Customer).balanceCents ?? 0) : 0;
        for (const r of open) {
          tx.update(doc(db, 'users', uid, 'receivables', r.id), { paidCents: r.amountCents, status: 'paid', updatedAt: serverTimestamp() });
        }
        tx.update(custRef, { balanceCents: Math.max(0, bal - group.totalOwed), updatedAt: serverTimestamp() });
      });
      onRefresh();
    } catch { setErr('Erro ao registrar.'); setBusy(false); }
  }

  async function handlePartial() {
    const paidNow = toCents(partialAmount);
    if (paidNow <= 0 || paidNow >= totalOwedOpen) {
      setErr(`Digite um valor entre R$ 0,01 e ${formatMoney(totalOwedOpen - 1)}.`);
      return;
    }
    setBusy(true); setErr('');
    try {
      const leftover = totalOwedOpen - paidNow;
      const custRef = doc(db, 'users', uid, 'customers', group.customerId);
      const recCol = collection(db, 'users', uid, 'receivables');

      // Gerar plano de reparcelamento do restante
      const baseAmount = Math.floor(leftover / reParcelNum);
      const remainder = leftover - baseAmount * reParcelNum;
      const newInstallments = Array.from({ length: reParcelNum }, (_, i) => {
        const dueDate = new Date();
        dueDate.setDate(dueDate.getDate() + reParcelFirstDays + i * 30);
        return {
          dueDate: Timestamp.fromDate(dueDate),
          amountCents: baseAmount + (i === 0 ? remainder : 0),
        };
      });

      // Pegar o saleId de referência (da primeira parcela aberta)
      const refSaleId = open[0]?.saleId ?? '';

      await runTransaction(db, async tx => {
        const snap = await tx.get(custRef);
        const bal = snap.exists() ? Number((snap.data() as Customer).balanceCents ?? 0) : 0;

        // Marca TODAS as parcelas abertas como pagas (zeramos a dívida atual)
        for (const r of open) {
          tx.update(doc(db, 'users', uid, 'receivables', r.id), {
            paidCents: r.amountCents,
            status: 'paid',
            updatedAt: serverTimestamp(),
          });
        }

        // Cria novas parcelas para o restante
        for (const inst of newInstallments) {
          tx.set(doc(recCol), {
            saleId: refSaleId,
            customerId: group.customerId,
            dueDate: inst.dueDate,
            amountCents: inst.amountCents,
            paidCents: 0,
            status: 'pending',
            createdAt: serverTimestamp(),
            updatedAt: serverTimestamp(),
          });
        }

        // Atualiza saldo do cliente: desconta o total pago agora
        // O restante (leftover) continua como saldo pois as novas parcelas foram criadas
        tx.update(custRef, {
          balanceCents: Math.max(0, bal - paidNow),
          updatedAt: serverTimestamp(),
        });
      });
      onRefresh();
    } catch (e) { console.error(e); setErr('Erro ao registrar pagamento parcial.'); setBusy(false); }
  }

  async function handleChangeDate() {
    if (!changeDateId || !newDate) { setErr('Selecione a parcela e a nova data.'); return; }
    setBusy(true); setErr('');
    try {
      const [y,m,d] = newDate.split('-').map(Number);
      await updateDoc(doc(db, 'users', uid, 'receivables', changeDateId), { dueDate: Timestamp.fromDate(new Date(y, m-1, d)), updatedAt: serverTimestamp() });
      onRefresh();
    } catch { setErr('Erro ao alterar data.'); setBusy(false); }
  }

  const paidNowCents = toCents(partialAmount);
  const leftoverCents = totalOwedOpen - paidNowCents;

  // Preview do reparcelamento
  const reParcelPreview = paidNowCents > 0 && paidNowCents < totalOwedOpen && leftoverCents > 0
    ? Array.from({ length: reParcelNum }, (_, i) => {
        const base = Math.floor(leftoverCents / reParcelNum);
        const rem = leftoverCents - base * reParcelNum;
        const due = new Date();
        due.setDate(due.getDate() + reParcelFirstDays + i * 30);
        return { amount: base + (i === 0 ? rem : 0), due };
      })
    : [];
  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-end sm:items-center justify-center">
      <div className="bg-white w-full sm:max-w-md rounded-t-2xl sm:rounded-2xl shadow-2xl max-h-[90vh] flex flex-col">
        <div className="flex items-center justify-between px-5 py-4 border-b">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-teal-100 text-teal-700 flex items-center justify-center font-bold text-sm">{group.name.charAt(0)}</div>
            <div><div className="font-semibold text-gray-900">{group.name}</div><div className="text-xs text-gray-500">{group.phone}</div></div>
          </div>
          <button onClick={onClose} className="text-gray-400 hover:text-gray-600 text-2xl w-8 h-8">x</button>
        </div>
        <div className="px-5 py-3 bg-slate-50 border-b flex items-center justify-between">
          <span className="text-sm text-gray-600">Total a receber</span>
          <span className="text-xl font-bold">{formatMoney(group.totalOwed)}</span>
        </div>
        <div className="flex-1 overflow-y-auto px-5 py-4 space-y-3 min-h-0">
          {mode === "list" && (
            <>
              {open.length === 0 ? (
                <div className="text-center text-sm text-green-600 py-6">Tudo quitado!</div>
              ) : (
                <div className="space-y-2">
                  <p className="text-xs text-gray-500">Selecione as parcelas para pagar:</p>
                  {open.map((r, i) => {
                    const rem = r.amountCents - r.paidCents;
                    const due = r.dueDate?.toDate?.()?.toLocaleDateString("pt-BR") ?? "--";
                    const sel = selected.has(r.id);
                    return (
                      <label key={r.id} className={`flex items-center gap-3 p-3 rounded-xl border cursor-pointer transition-all ${sel ? "border-teal-400 bg-teal-50" : "border-slate-200 hover:bg-slate-50"}`}>
                        <input type="checkbox" checked={sel} onChange={() => toggleSelect(r.id)} className="w-4 h-4 accent-teal-600 flex-shrink-0" />
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-2 flex-wrap">
                            <span className={`text-xs font-medium px-2 py-0.5 rounded-full ${STATUS_COLORS[r.status]}`}>{STATUS_LABELS[r.status]}</span>
                            {r.isOverdue && <span className="text-xs text-red-600 font-medium">{r.daysLate}d atraso</span>}
                          </div>
                          <div className="text-xs text-gray-500 mt-0.5">Parcela {i+1} - Vence {due}</div>
                          {r.paidCents > 0 && <div className="text-xs text-gray-400">Ja pago: {formatMoney(r.paidCents)}</div>}
                        </div>
                        <div className="font-bold text-gray-900 flex-shrink-0">{formatMoney(rem)}</div>
                      </label>
                    );
                  })}
                  {selected.size > 0 && (
                    <div className="rounded-xl bg-teal-50 border border-teal-200 px-4 py-3 flex items-center justify-between">
                      <span className="text-sm text-teal-700">{selected.size} parcela{selected.size !== 1 ? "s" : ""} selecionada{selected.size !== 1 ? "s" : ""}</span>
                      <span className="text-lg font-bold text-teal-700">{formatMoney(selectedTotal)}</span>
                    </div>
                  )}
                </div>
              )}
            </>
          )}

          {mode === "paySelected" && (
            <div className="space-y-3">
              <div className="rounded-xl bg-teal-50 border border-teal-100 p-4 text-center space-y-1">
                <div className="text-sm text-teal-700">{selectedRows.length} parcela{selectedRows.length !== 1 ? "s" : ""} serao pagas</div>
                <div className="text-3xl font-bold text-teal-700">{formatMoney(selectedTotal)}</div>
                <div className="text-xs text-teal-500">Valor exato das parcelas selecionadas</div>
              </div>
              <div className="space-y-1">
                {selectedRows.map((r, i) => (
                  <div key={r.id} className="flex justify-between text-sm text-gray-600 py-1 border-b border-slate-100 last:border-0">
                    <span>Parcela {open.indexOf(r)+1} - {r.dueDate?.toDate?.()?.toLocaleDateString("pt-BR")}</span>
                    <span className="font-semibold">{formatMoney(r.amountCents - r.paidCents)}</span>
                  </div>
                ))}
              </div>
            </div>
          )}

          {mode === "payAll" && (
            <div className="rounded-xl bg-green-50 border border-green-100 p-4 text-center space-y-1">
              <div className="text-sm text-green-700">Confirmar pagamento total?</div>
              <div className="text-3xl font-bold text-green-700">{formatMoney(group.totalOwed)}</div>
              <div className="text-xs text-green-600">{open.length} parcela{open.length !== 1 ? "s" : ""} serao marcadas como pagas</div>
            </div>
          )}

          {mode === "partial" && (
            <div className="space-y-3">
              {/* Total da dívida */}
              <div className="rounded-xl bg-slate-50 border border-slate-200 px-4 py-3 flex items-center justify-between">
                <span className="text-sm text-gray-600">Total da dívida</span>
                <span className="text-xl font-bold text-gray-900">{formatMoney(totalOwedOpen)}</span>
              </div>
              {open.length > 1 && (
                <div className="text-xs text-gray-500 bg-blue-50 border border-blue-100 rounded-lg px-3 py-2">
                  ℹ️ {open.length} parcelas em aberto serão consolidadas e reparceladas automaticamente.
                </div>
              )}

              {/* Valor pago agora */}
              <div>
                <label className="text-xs font-medium text-gray-600">
                  Quanto o cliente pagou agora?
                </label>
                <input
                  type="text"
                  inputMode="decimal"
                  placeholder="Ex: 50,00"
                  autoFocus
                  className="inp"
                  value={partialAmount}
                  onChange={e => { setPartialAmount(e.target.value); setErr(""); }}
                />
              </div>

              {/* Reparcelamento do restante */}
              {paidNowCents > 0 && paidNowCents < totalOwedOpen && (
                <>
                  {/* Resumo */}
                  <div className="rounded-xl bg-orange-50 border border-orange-100 px-4 py-3 space-y-1">
                    <div className="flex justify-between text-sm">
                      <span className="text-orange-700">✅ Recebendo agora:</span>
                      <span className="font-bold text-orange-800">{formatMoney(paidNowCents)}</span>
                    </div>
                    <div className="flex justify-between text-sm">
                      <span className="text-orange-700">⏳ Restante a reparcelar:</span>
                      <span className="font-bold text-orange-800">{formatMoney(leftoverCents)}</span>
                    </div>
                  </div>

                  {/* Configuração do reparcelamento */}
                  <div className="rounded-xl bg-blue-50 border border-blue-100 p-4 space-y-3">
                    <div className="text-xs font-semibold text-blue-700">
                      Como parcelar os {formatMoney(leftoverCents)} restantes?
                    </div>
                    <div className="grid grid-cols-2 gap-3">
                      <div>
                        <label className="text-xs font-medium text-gray-600">Nº de parcelas</label>
                        <select
                          className="inp-select"
                          value={reParcelNum}
                          onChange={e => setReParcelNum(Number(e.target.value))}
                        >
                          {[1,2,3,4,5,6,8,10,12].map(n => (
                            <option key={n} value={n}>
                              {n}x de {formatMoney(Math.round(leftoverCents / n))}
                            </option>
                          ))}
                        </select>
                      </div>
                      <div>
                        <label className="text-xs font-medium text-gray-600">1ª parcela em</label>
                        <select
                          className="inp-select"
                          value={reParcelFirstDays}
                          onChange={e => setReParcelFirstDays(Number(e.target.value))}
                        >
                          <option value={7}>7 dias</option>
                          <option value={15}>15 dias</option>
                          <option value={30}>30 dias</option>
                          <option value={45}>45 dias</option>
                        </select>
                      </div>
                    </div>

                    {/* Preview das novas parcelas */}
                    {reParcelPreview.length > 0 && (
                      <div className="space-y-1">
                        <div className="text-xs font-medium text-blue-700 mb-1">Novas parcelas geradas:</div>
                        {reParcelPreview.map((inst, i) => (
                          <div key={i} className="flex justify-between text-xs text-blue-700 py-1 border-b border-blue-100 last:border-0">
                            <span>{i + 1}ª — {inst.due.toLocaleDateString("pt-BR")}</span>
                            <span className="font-semibold">{formatMoney(inst.amount)}</span>
                          </div>
                        ))}
                      </div>
                    )}
                  </div>
                </>
              )}
            </div>
          )}

          {mode === "changeDate" && (
            <div className="space-y-3">
              <p className="text-xs text-gray-500">Qual parcela quer reagendar?</p>
              <div className="space-y-1">
                {open.map((r, i) => (
                  <label key={r.id} className={`flex items-center gap-3 p-2.5 rounded-lg border cursor-pointer transition-colors ${changeDateId === r.id ? "border-teal-400 bg-teal-50" : "border-slate-200 hover:bg-slate-50"}`}>
                    <input type="radio" name="changeDate" checked={changeDateId === r.id} onChange={() => { setChangeDateId(r.id); setErr(""); }} className="accent-teal-600" />
                    <span className="text-sm text-gray-700 flex-1">Parcela {i+1} - vence {r.dueDate?.toDate?.()?.toLocaleDateString("pt-BR")}</span>
                    <span className="text-sm font-semibold">{formatMoney(r.amountCents - r.paidCents)}</span>
                  </label>
                ))}
              </div>
              {changeDateId && (
                <div>
                  <label className="text-xs font-medium text-gray-600">Nova data de vencimento</label>
                  <input type="date" min={new Date().toISOString().split("T")[0]}
                    className="inp"
                    value={newDate} onChange={e => setNewDate(e.target.value)} />
                </div>
              )}
            </div>
          )}

          {err && <div className="text-xs text-red-600 bg-red-50 rounded-lg px-3 py-2">{err}</div>}
        </div>
        <div className="px-5 py-4 border-t flex-shrink-0 space-y-2">
          {mode === "list" && (
            <>
              <div className="grid grid-cols-2 gap-2">
                <button onClick={() => { if (selected.size === 0) { setErr("Selecione ao menos uma parcela."); return; } setErr(""); setMode("paySelected"); }}
                  disabled={open.length === 0}
                  className="rounded-xl border border-teal-500 text-teal-700 py-2.5 text-sm font-medium hover:bg-teal-50 disabled:opacity-40 transition-colors">
                  Pagar selecionadas
                </button>
                <button onClick={() => { setErr(""); setMode("payAll"); }} disabled={open.length === 0}
                  className="rounded-xl bg-teal-600 hover:bg-teal-700 text-white py-2.5 text-sm font-semibold disabled:opacity-40 transition-colors">
                  Pagar tudo
                </button>
              </div>
              <div className="grid grid-cols-2 gap-2">
                <button onClick={() => { setErr(""); setMode("partial"); }} disabled={open.length === 0}
                  className="rounded-xl border border-slate-200 text-gray-600 py-2.5 text-sm font-medium hover:bg-slate-50 disabled:opacity-40 transition-colors">
                  Pagamento parcial
                </button>
                <button onClick={() => { setErr(""); setMode("changeDate"); }} disabled={open.length === 0}
                  className="rounded-xl border border-slate-200 text-gray-600 py-2.5 text-sm font-medium hover:bg-slate-50 disabled:opacity-40 transition-colors">
                  Mudar prazo
                </button>
              </div>
              {err && <div className="text-xs text-red-600">{err}</div>}
            </>
          )}
          {mode === "paySelected" && (
            <div className="flex gap-2">
              <button onClick={back} className="flex-1 rounded-xl border border-slate-200 py-2.5 text-sm text-gray-600 hover:bg-slate-50">Voltar</button>
              <button onClick={handlePaySelected} disabled={busy}
                className="flex-1 rounded-xl bg-teal-600 hover:bg-teal-700 text-white py-2.5 text-sm font-semibold disabled:opacity-50">
                {busy ? "Registrando..." : "Confirmar " + formatMoney(selectedTotal)}
              </button>
            </div>
          )}
          {mode === "payAll" && (
            <div className="flex gap-2">
              <button onClick={back} className="flex-1 rounded-xl border border-slate-200 py-2.5 text-sm text-gray-600 hover:bg-slate-50">Voltar</button>
              <button onClick={handlePayAll} disabled={busy}
                className="flex-1 rounded-xl bg-green-600 hover:bg-green-700 text-white py-2.5 text-sm font-semibold disabled:opacity-50">
                {busy ? "Registrando..." : "Confirmar " + formatMoney(group.totalOwed)}
              </button>
            </div>
          )}
          {mode === "partial" && (
            <div className="flex gap-2">
              <button onClick={back} className="flex-1 rounded-xl border border-slate-200 py-2.5 text-sm text-gray-600 hover:bg-slate-50">Voltar</button>
              <button
                onClick={handlePartial}
                disabled={busy || paidNowCents <= 0 || paidNowCents >= totalOwedOpen}
                className="flex-1 rounded-xl bg-teal-600 hover:bg-teal-700 text-white py-2.5 text-sm font-semibold disabled:opacity-50"
              >
                {busy ? "Registrando..." : leftoverCents > 0
                  ? `Confirmar — ${reParcelNum}x de ${formatMoney(Math.round(leftoverCents / reParcelNum))}`
                  : "Confirmar pagamento"
                }
              </button>
            </div>
          )}
          {mode === "changeDate" && (
            <div className="flex gap-2">
              <button onClick={() => { back(); setChangeDateId(null); setNewDate(""); }} className="flex-1 rounded-xl border border-slate-200 py-2.5 text-sm text-gray-600 hover:bg-slate-50">Voltar</button>
              <button onClick={handleChangeDate} disabled={busy || !changeDateId || !newDate}
                className="flex-1 rounded-xl bg-teal-600 hover:bg-teal-700 text-white py-2.5 text-sm font-semibold disabled:opacity-50">
                {busy ? "Salvando..." : "Salvar nova data"}
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

export default function ReceivablesPage({ user }: { user: User }) {
  const [groups, setGroups] = useState<Group[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeGroup, setActiveGroup] = useState<Group | null>(null);

  useEffect(() => { load(); }, [user.uid]);

  async function load() {
    setLoading(true);
    try {
      const uid = user.uid;
      const [recSnap, custSnap] = await Promise.all([
        getDocs(query(collection(db, "users", uid, "receivables"), orderBy("dueDate", "asc"))),
        getDocs(collection(db, "users", uid, "customers")),
      ]);
      const custMap = new Map<string, Customer>();
      custSnap.docs.forEach(d => custMap.set(d.id, d.data() as Customer));
      const now = Date.now();
      const map = new Map<string, Group>();
      for (const d of recSnap.docs) {
        const rec = d.data() as Receivable;
        const cid = rec.customerId;
        const cust = custMap.get(cid);
        const dueMs = rec.dueDate?.toMillis?.() ?? 0;
        const daysLate = dueMs > 0 ? Math.max(0, Math.floor((now - dueMs) / 86_400_000)) : 0;
        const isOverdue = daysLate > 0 && rec.status !== "paid";
        const remaining = rec.amountCents - rec.paidCents;
        if (!map.has(cid)) {
          map.set(cid, { customerId: cid, name: cust?.name ?? "Cliente nao encontrado", phone: cust?.phone ?? "", totalOwed: 0, overdueAmount: 0, rows: [] });
        }
        const g = map.get(cid)!;
        if (rec.status !== "paid") {
          g.totalOwed += remaining;
          if (isOverdue) g.overdueAmount += remaining;
        }
        g.rows.push({ id: d.id, ...rec, daysLate, isOverdue });
      }
      setGroups(Array.from(map.values()).sort((a, b) => b.totalOwed - a.totalOwed));
    } catch (e) { console.error(e); }
    finally { setLoading(false); }
  }

  const totalPending = groups.reduce((s, g) => s + g.totalOwed, 0);
  const totalOverdue = groups.reduce((s, g) => s + g.overdueAmount, 0);
  const withDebt = groups.filter(g => g.totalOwed > 0).length;

  return (
    <DashboardLayout title="Recebimentos">
      <div className="space-y-4">
        <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
          <div className="rounded-2xl bg-white border border-slate-100 shadow-sm p-4">
            <div className="text-xs text-gray-500">Total a receber</div>
            <div className="text-2xl font-bold text-gray-900 mt-1">{formatMoney(totalPending)}</div>
            <div className="text-xs text-gray-400 mt-0.5">{withDebt} cliente{withDebt !== 1 ? "s" : ""}</div>
          </div>
          <div className="rounded-2xl bg-white border border-slate-100 shadow-sm p-4">
            <div className="text-xs text-gray-500">Em atraso</div>
            <div className={`text-2xl font-bold mt-1 ${totalOverdue > 0 ? "text-red-600" : "text-gray-400"}`}>{formatMoney(totalOverdue)}</div>
            <div className="text-xs text-gray-400 mt-0.5">{groups.filter(g => g.overdueAmount > 0).length} cliente{groups.filter(g => g.overdueAmount > 0).length !== 1 ? "s" : ""}</div>
          </div>
          <div className="hidden sm:block rounded-2xl bg-teal-50 border border-teal-100 p-4">
            <div className="text-xs text-teal-600">Como usar</div>
            <div className="text-sm text-teal-700 mt-1">Toque em um cliente para ver as parcelas.</div>
          </div>
        </div>
        <div className="rounded-2xl bg-white border border-slate-100 shadow-sm overflow-hidden">
          <div className="px-5 py-3 border-b bg-slate-50">
            <h2 className="text-sm font-semibold text-gray-800">Clientes com saldo</h2>
          </div>
          {loading ? (
            <div className="p-8 text-center text-sm text-gray-400">Carregando...</div>
          ) : groups.length === 0 ? (
            <div className="p-8 text-center text-sm text-gray-400">Nenhuma conta a receber.<br /><span className="text-xs">Registre vendas como fiado ou parcelado.</span></div>
          ) : (
            <div className="divide-y divide-slate-100">
              {groups.map(g => {
                const openCount = g.rows.filter(r => r.status !== "paid").length;
                const pct = g.rows.length > 0 ? (g.rows.reduce((s, r) => s + r.paidCents, 0) / g.rows.reduce((s, r) => s + r.amountCents, 0)) * 100 : 100;
                return (
                  <button key={g.customerId} onClick={() => setActiveGroup(g)}
                    className="w-full text-left px-5 py-3.5 hover:bg-slate-50 active:bg-slate-100 transition-colors">
                    <div className="flex items-center gap-3">
                      <div className={`w-10 h-10 rounded-full flex items-center justify-center font-bold text-sm flex-shrink-0 ${g.overdueAmount > 0 ? "bg-red-100 text-red-700" : "bg-teal-100 text-teal-700"}`}>
                        {g.name.charAt(0)}
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center justify-between">
                          <span className="font-semibold text-gray-900 text-sm truncate">{g.name}</span>
                          <span className={`text-base font-bold ml-2 flex-shrink-0 ${g.totalOwed > 0 ? "text-gray-900" : "text-green-600"}`}>
                            {g.totalOwed > 0 ? formatMoney(g.totalOwed) : "Quitado"}
                          </span>
                        </div>
                        <div className="flex items-center justify-between mt-0.5">
                          <span className="text-xs text-gray-500">
                            {openCount > 0 ? `${openCount} parcela${openCount !== 1 ? "s" : ""} em aberto` : "Tudo pago"}
                            {g.overdueAmount > 0 && <span className="text-red-500 ml-1">- {formatMoney(g.overdueAmount)} atrasado</span>}
                          </span>
                          <span className="text-xs text-gray-400 ml-2">&rsaquo;</span>
                        </div>
                        <div className="mt-1.5 h-1 rounded-full bg-slate-100 overflow-hidden">
                          <div className="h-full rounded-full bg-teal-400 transition-all" style={{ width: `${pct}%` }} />
                        </div>
                      </div>
                    </div>
                  </button>
                );
              })}
            </div>
          )}
        </div>
      </div>
      {activeGroup && <CustomerModal group={activeGroup} uid={user.uid} onClose={() => setActiveGroup(null)} onRefresh={() => { load(); setActiveGroup(null); }} />}
    </DashboardLayout>
  );
}
