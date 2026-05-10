out = open("web/src/pages/ReceivablesPage.tsx","a",encoding="utf-8")
out.write("""
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
""")
out.close()
print("page done")
