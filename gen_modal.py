import textwrap
out = open("web/src/pages/ReceivablesPage.tsx","a",encoding="utf-8")

# MODE: LIST
out.write("""
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
""")

# MODE: PAY SELECTED
out.write("""
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
""")

# MODE: PAY ALL
out.write("""
          {mode === "payAll" && (
            <div className="rounded-xl bg-green-50 border border-green-100 p-4 text-center space-y-1">
              <div className="text-sm text-green-700">Confirmar pagamento total?</div>
              <div className="text-3xl font-bold text-green-700">{formatMoney(group.totalOwed)}</div>
              <div className="text-xs text-green-600">{open.length} parcela{open.length !== 1 ? "s" : ""} serao marcadas como pagas</div>
            </div>
          )}
""")

# MODE: PARTIAL
out.write("""
          {mode === "partial" && (
            <div className="space-y-3">
              <p className="text-xs text-gray-500">Qual parcela vai receber pagamento parcial?</p>
              <div className="space-y-1">
                {open.map((r, i) => (
                  <label key={r.id} className={`flex items-center gap-3 p-2.5 rounded-lg border cursor-pointer transition-colors ${partialRow?.id === r.id ? "border-teal-400 bg-teal-50" : "border-slate-200 hover:bg-slate-50"}`}>
                    <input type="radio" name="partial" checked={partialRow?.id === r.id} onChange={() => { setPartialRow(r); setPartialAmount(""); setErr(""); }} className="accent-teal-600" />
                    <span className="text-sm text-gray-700 flex-1">Parcela {i+1} - {r.dueDate?.toDate?.()?.toLocaleDateString("pt-BR")}</span>
                    <span className="text-sm font-semibold text-gray-900">{formatMoney(r.amountCents - r.paidCents)}</span>
                  </label>
                ))}
              </div>
              {partialRow && (
                <div className="space-y-3 pt-1">
                  <div>
                    <label className="text-xs font-medium text-gray-600">Valor recebido agora (R$) - max {formatMoney(partialRemaining - 1)}</label>
                    <input type="number" step="0.01" min="0.01" placeholder="0,00" autoFocus
                      className="mt-1 w-full rounded-xl border border-slate-200 px-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-teal-400"
                      value={partialAmount} onChange={e => { setPartialAmount(e.target.value); setErr(""); }} />
                  </div>
                  {paidNowCents > 0 && paidNowCents < partialRemaining && (
                    <>
                      <div className="rounded-xl bg-orange-50 border border-orange-100 px-3 py-2.5 text-xs text-orange-700 space-y-0.5">
                        <div>Recebendo agora: <strong>{formatMoney(paidNowCents)}</strong></div>
                        <div>Restante: <strong>{formatMoney(leftoverCents)}</strong> - defina a nova data abaixo</div>
                      </div>
                      <div>
                        <label className="text-xs font-medium text-gray-600">Nova data para o restante ({formatMoney(leftoverCents)})</label>
                        <input type="date" min={new Date().toISOString().split("T")[0]}
                          className="mt-1 w-full rounded-xl border border-slate-200 px-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-teal-400"
                          value={partialNewDate} onChange={e => setPartialNewDate(e.target.value)} />
                      </div>
                    </>
                  )}
                </div>
              )}
            </div>
          )}
""")

# MODE: CHANGE DATE
out.write("""
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
                    className="mt-1 w-full rounded-xl border border-slate-200 px-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-teal-400"
                    value={newDate} onChange={e => setNewDate(e.target.value)} />
                </div>
              )}
            </div>
          )}
""")

# ERROR + BUTTONS
out.write("""
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
              <button onClick={handlePartial} disabled={busy || !partialRow || paidNowCents <= 0 || !partialNewDate}
                className="flex-1 rounded-xl bg-teal-600 hover:bg-teal-700 text-white py-2.5 text-sm font-semibold disabled:opacity-50">
                {busy ? "Registrando..." : "Confirmar"}
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
""")
out.close()
print("modal jsx done")
