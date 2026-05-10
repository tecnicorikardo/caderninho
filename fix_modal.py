lines = open("web/src/pages/ReceivablesPage.tsx", encoding="utf-8").readlines()
header = [
  "  const paidNowCents = toCents(partialAmount);\n",
  "  const partialRemaining = partialRow ? (partialRow.amountCents - partialRow.paidCents) : 0;\n",
  "  const leftoverCents = partialRemaining - paidNowCents;\n",
  "  return (\n",
  "    <div className=\"fixed inset-0 bg-black/50 z-50 flex items-end sm:items-center justify-center\">\n",
  "      <div className=\"bg-white w-full sm:max-w-md rounded-t-2xl sm:rounded-2xl shadow-2xl max-h-[90vh] flex flex-col\">\n",
  "        <div className=\"flex items-center justify-between px-5 py-4 border-b\">\n",
  "          <div className=\"flex items-center gap-3\">\n",
  "            <div className=\"w-10 h-10 rounded-full bg-teal-100 text-teal-700 flex items-center justify-center font-bold text-sm\">{group.name.charAt(0)}</div>\n",
  "            <div><div className=\"font-semibold text-gray-900\">{group.name}</div><div className=\"text-xs text-gray-500\">{group.phone}</div></div>\n",
  "          </div>\n",
  "          <button onClick={onClose} className=\"text-gray-400 hover:text-gray-600 text-2xl w-8 h-8\">x</button>\n",
  "        </div>\n",
  "        <div className=\"px-5 py-3 bg-slate-50 border-b flex items-center justify-between\">\n",
  "          <span className=\"text-sm text-gray-600\">Total a receber</span>\n",
  "          <span className=\"text-xl font-bold\">{formatMoney(group.totalOwed)}</span>\n",
  "        </div>\n",
  "        <div className=\"flex-1 overflow-y-auto px-5 py-4 space-y-3 min-h-0\">\n",
]
new_lines = lines[:109] + header + lines[109:]
open("web/src/pages/ReceivablesPage.tsx","w",encoding="utf-8").writelines(new_lines)
print("done, total:", len(new_lines))
