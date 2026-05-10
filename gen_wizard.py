content = """import { useState } from \"react\";
import { downloadTemplate, parseImportFile, importFromWorkbook, type ImportPreview } from \"@/lib/spreadsheet\";
import type { WorkBook } from \"xlsx\";

export default function ImportWizard({ uid, onDone, onBack }: { uid: string; onDone: () => void; onBack: () => void }) {
  const [preview, setPreview] = useState<ImportPreview | null>(null);
  const [wb, setWb] = useState<WorkBook | null>(null);
  const [busy, setBusy] = useState(false);
  const [done, setDone] = useState<{ customers: number; products: number } | null>(null);
  const [err, setErr] = useState(\"\");

  async function onFile(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) return;
    setErr(\"\"); setPreview(null); setWb(null); setDone(null);
    try {
      const result = await parseImportFile(file);
      setPreview(result.preview);
      setWb(result.wb);
    } catch (ex) { setErr(ex instanceof Error ? ex.message : \"Erro ao ler planilha.\"); }
  }

  async function doImport() {
    if (!wb) return;
    setBusy(true); setErr(\"\");
    try {
      const result = await importFromWorkbook(uid, wb);
      setDone(result);
    } catch (ex) { setErr(ex instanceof Error ? ex.message : \"Erro ao importar.\"); }
    finally { setBusy(false); }
  }

  if (done) {
    return (
      <div className=\"rounded-2xl bg-white border border-slate-100 shadow-sm p-6 text-center space-y-4\">
        <div className=\"text-4xl\">✅</div>
        <div className=\"text-lg font-semibold text-gray-900\">Importacao concluida!</div>
        <div className=\"text-sm text-gray-600 space-y-1\">
          <div>{done.customers} cliente{done.customers !== 1 ? \"s\" : \"\"} importado{done.customers !== 1 ? \"s\" : \"\"}</div>
          <div>{done.products} produto{done.products !== 1 ? \"s\" : \"\"} importado{done.products !== 1 ? \"s\" : \"\"} no estoque</div>
        </div>
        <button onClick={onDone} className=\"rounded-xl bg-teal-600 hover:bg-teal-700 text-white px-6 py-3 text-sm font-semibold\">Ir para o Dashboard</button>
      </div>
    );
  }

  return (
    <div className=\"rounded-2xl bg-white border border-slate-100 shadow-sm p-5 space-y-5\">
      <div>
        <h2 className=\"text-base font-semibold text-gray-900\">Importar Planilha</h2>
        <p className=\"text-sm text-gray-500 mt-1\">Importe seus clientes e produtos de uma vez. Use o modelo abaixo para preencher.</p>
      </div>

      <div className=\"rounded-xl bg-teal-50 border border-teal-100 p-4 flex items-center justify-between gap-4\">
        <div>
          <div className=\"text-sm font-medium text-teal-800\">Baixar modelo de planilha</div>
          <div className=\"text-xs text-teal-600 mt-0.5\">Arquivo Excel com abas Clientes e Produtos, ja formatado com exemplos</div>
        </div>
        <button onClick={downloadTemplate} className=\"flex-shrink-0 rounded-xl bg-teal-600 hover:bg-teal-700 text-white px-4 py-2.5 text-sm font-semibold transition-colors\">
          Baixar modelo
        </button>
      </div>

      <div>
        <label className=\"text-xs font-medium text-gray-600\">Selecionar planilha preenchida (.xlsx)</label>
        <input type=\"file\" accept=\".xlsx,.xls,.csv\" onChange={onFile}
          className=\"mt-1 block w-full text-sm text-gray-600 file:mr-3 file:py-2 file:px-4 file:rounded-lg file:border-0 file:bg-teal-50 file:text-teal-700 file:font-medium hover:file:bg-teal-100 cursor-pointer\" />
      </div>

      {preview && (
        <div className=\"rounded-xl border border-slate-200 p-4 space-y-2\">
          <div className=\"text-sm font-medium text-gray-800\">Preview da importacao:</div>
          <div className=\"grid grid-cols-2 gap-2\">
            <div className=\"rounded-lg bg-blue-50 p-3 text-center\">
              <div className=\"text-2xl font-bold text-blue-700\">{preview.customers}</div>
              <div className=\"text-xs text-blue-600\">clientes</div>
            </div>
            <div className=\"rounded-lg bg-green-50 p-3 text-center\">
              <div className=\"text-2xl font-bold text-green-700\">{preview.products}</div>
              <div className=\"text-xs text-green-600\">produtos</div>
            </div>
          </div>
          {preview.errors.length > 0 && (
            <div className=\"rounded-lg bg-red-50 border border-red-100 p-3\">
              <div className=\"text-xs font-medium text-red-700 mb-1\">{preview.errors.length} erro{preview.errors.length !== 1 ? \"s\" : \"\"} encontrado{preview.errors.length !== 1 ? \"s\" : \"\"}:</div>
              <ul className=\"text-xs text-red-600 space-y-0.5 list-disc list-inside\">
                {preview.errors.slice(0, 5).map((e, i) => <li key={i}>{e}</li>)}
                {preview.errors.length > 5 && <li>...e mais {preview.errors.length - 5}</li>}
              </ul>
            </div>
          )}
        </div>
      )}

      {err && <div className=\"text-xs text-red-600 bg-red-50 rounded-lg px-3 py-2\">{err}</div>}

      <div className=\"flex gap-3\">
        <button onClick={onBack} disabled={busy} className=\"rounded-xl border border-slate-200 px-5 py-2.5 text-sm text-gray-600 hover:bg-slate-50 disabled:opacity-50\">Voltar</button>
        <button onClick={doImport} disabled={busy || !wb || (preview?.customers === 0 && preview?.products === 0)}
          className=\"flex-1 rounded-xl bg-teal-600 hover:bg-teal-700 text-white py-2.5 text-sm font-semibold disabled:opacity-50 transition-colors\">
          {busy ? \"Importando...\" : `Importar ${(preview?.customers ?? 0) + (preview?.products ?? 0)} registros`}
        </button>
      </div>
    </div>
  );
}
"""
open("web/src/pages/components/ImportWizard.tsx","w",encoding="utf-8").write(content)
print("ImportWizard ok:", len(content))
