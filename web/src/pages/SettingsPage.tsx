import { useEffect, useState } from "react";
import type { User } from "firebase/auth";
import { updatePassword, EmailAuthProvider, reauthenticateWithCredential } from "firebase/auth";
import { doc, getDoc, updateDoc, serverTimestamp } from "firebase/firestore";
import DashboardLayout from "@/ui/DashboardLayout";
import { db } from "@/lib/firebase";
import type { BrandMargin, UserProfile } from "@/lib/types";
import { downloadTemplate, exportData, parseImportFile, importFromWorkbook } from "@/lib/spreadsheet";
import type { ImportPreview } from "@/lib/spreadsheet";
import type { WorkBook } from "xlsx";

const DEFAULT_BRANDS: BrandMargin[] = [
  { brand: "Natura", marginPercent: 30 },
  { brand: "Avon", marginPercent: 30 },
  { brand: "Casa & Estilo", marginPercent: 15 },
];

export default function SettingsPage({ user }: { user: User }) {
  const [brandMargins, setBrandMargins] = useState<BrandMargin[]>(DEFAULT_BRANDS);
  const [saving, setSaving] = useState(false);
  const [msg, setMsg] = useState<{ type: "ok" | "err"; text: string } | null>(null);

  // Nova marca
  const [newBrand, setNewBrand] = useState("");
  const [newMargin, setNewMargin] = useState("");

  // Senha
  const [currentPwd, setCurrentPwd] = useState("");
  const [newPwd, setNewPwd] = useState("");
  const [pwdMsg, setPwdMsg] = useState<{ type: "ok" | "err"; text: string } | null>(null);
  const [pwdSaving, setPwdSaving] = useState(false);

  // Importar/Exportar
  const [exporting, setExporting] = useState(false);
  const [importPreview, setImportPreview] = useState<ImportPreview | null>(null);
  const [importWb, setImportWb] = useState<WorkBook | null>(null);
  const [importing, setImporting] = useState(false);
  const [importMsg, setImportMsg] = useState<{ type: "ok" | "err"; text: string } | null>(null);

  useEffect(() => {
    async function load() {
      const snap = await getDoc(doc(db, "users", user.uid));
      if (snap.exists()) {
        const data = snap.data() as UserProfile;
        if (data.brandMargins && data.brandMargins.length > 0) {
          setBrandMargins(data.brandMargins);
        }
      }
    }
    load().catch(console.error);
  }, [user.uid]);

  async function saveMargins() {
    setSaving(true);
    setMsg(null);
    try {
      await updateDoc(doc(db, "users", user.uid), {
        brandMargins,
        updatedAt: serverTimestamp(),
      });
      setMsg({ type: "ok", text: "Margens salvas com sucesso!" });
    } catch (e) {
      setMsg({ type: "err", text: e instanceof Error ? e.message : "Erro ao salvar." });
    } finally {
      setSaving(false);
    }
  }

  function updateMargin(index: number, value: string) {
    const pct = Math.min(99, Math.max(0, Number(value) || 0));
    setBrandMargins(prev => prev.map((b, i) => i === index ? { ...b, marginPercent: pct } : b));
  }

  function removeBrand(index: number) {
    setBrandMargins(prev => prev.filter((_, i) => i !== index));
  }

  function addBrand() {
    const name = newBrand.trim();
    const pct = Math.min(99, Math.max(0, Number(newMargin) || 0));
    if (!name) return;
    if (brandMargins.some(b => b.brand.toLowerCase() === name.toLowerCase())) {
      setMsg({ type: "err", text: "Essa marca já existe." });
      return;
    }
    setBrandMargins(prev => [...prev, { brand: name, marginPercent: pct }]);
    setNewBrand("");
    setNewMargin("");
    setMsg(null);
  }

  async function handleExport() {
    setExporting(true);
    try { await exportData(user.uid); }
    catch { alert("Erro ao exportar dados."); }
    finally { setExporting(false); }
  }

  async function handleImportFile(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) return;
    setImportMsg(null); setImportPreview(null); setImportWb(null);
    try {
      const result = await parseImportFile(file);
      setImportPreview(result.preview);
      setImportWb(result.wb);
    } catch (ex) {
      setImportMsg({ type: "err", text: ex instanceof Error ? ex.message : "Erro ao ler planilha." });
    }
  }

  async function handleImport() {
    if (!importWb) return;
    setImporting(true); setImportMsg(null);
    try {
      const result = await importFromWorkbook(user.uid, importWb);
      setImportMsg({ type: "ok", text: `Importado: ${result.customers} clientes e ${result.products} produtos.` });
      setImportPreview(null); setImportWb(null);
    } catch (ex) {
      setImportMsg({ type: "err", text: ex instanceof Error ? ex.message : "Erro ao importar." });
    } finally { setImporting(false); }
  }

  async function changePassword(e: React.FormEvent) {
    e.preventDefault();
    if (newPwd.length < 6) {
      setPwdMsg({ type: "err", text: "A nova senha deve ter pelo menos 6 caracteres." });
      return;
    }
    setPwdSaving(true);
    setPwdMsg(null);
    try {
      const credential = EmailAuthProvider.credential(user.email!, currentPwd);
      await reauthenticateWithCredential(user, credential);
      await updatePassword(user, newPwd);
      setCurrentPwd("");
      setNewPwd("");
      setPwdMsg({ type: "ok", text: "Senha alterada com sucesso!" });
    } catch (e) {
      setPwdMsg({ type: "err", text: e instanceof Error ? e.message : "Erro ao alterar senha." });
    } finally {
      setPwdSaving(false);
    }
  }

  return (
    <DashboardLayout title="Configurações">
      <div className="space-y-6 max-w-2xl">

        {/* Perfil */}
        <div className="rounded-2xl bg-white border border-slate-100 shadow-sm p-5">
          <h2 className="text-base font-semibold text-gray-800 mb-3">Meu Perfil</h2>
          <div className="flex items-center gap-4">
            <div className="w-14 h-14 rounded-full bg-teal-100 flex items-center justify-center text-teal-700 font-bold text-2xl">
              {(user.email ?? "U").charAt(0).toUpperCase()}
            </div>
            <div>
              <div className="font-semibold text-gray-900">{user.displayName ?? "Usuário"}</div>
              <div className="text-sm text-gray-500">{user.email}</div>
            </div>
          </div>
        </div>

        {/* Margens por marca */}
        <div className="rounded-2xl bg-white border border-slate-100 shadow-sm p-5">
          <h2 className="text-base font-semibold text-gray-800 mb-1">Comissão por Marca</h2>
          <p className="text-xs text-gray-500 mb-4">
            Configure a porcentagem que você ganha de cada marca. Esses valores são usados na calculadora e nos relatórios.
          </p>

          <div className="space-y-2 mb-4">
            {brandMargins.map((b, i) => (
              <div key={i} className="flex items-center gap-3 p-3 rounded-xl bg-slate-50 border border-slate-100">
                <div className="w-9 h-9 rounded-lg bg-teal-100 flex items-center justify-center text-teal-700 font-bold text-sm flex-shrink-0">
                  {b.brand.charAt(0)}
                </div>
                <div className="flex-1 font-medium text-gray-800 text-sm">{b.brand}</div>
                <div className="flex items-center gap-1">
                  <input
                    type="number"
                    min="0"
                    max="99"
                    step="1"
                    value={b.marginPercent}
                    onChange={e => updateMargin(i, e.target.value)}
                    className="w-16 rounded-lg border border-slate-200 px-2 py-1.5 text-sm text-center font-semibold text-teal-700 focus:outline-none focus:ring-2 focus:ring-teal-400"
                  />
                  <span className="text-sm text-gray-500 font-medium">%</span>
                </div>
                <button
                  onClick={() => removeBrand(i)}
                  className="text-gray-300 hover:text-red-500 text-xl leading-none transition-colors"
                  title="Remover marca"
                >×</button>
              </div>
            ))}
          </div>

          {/* Adicionar nova marca */}
          <div className="flex gap-2 mb-4">
            <input
              type="text"
              placeholder="Nome da marca"
              value={newBrand}
              onChange={e => setNewBrand(e.target.value)}
              onKeyDown={e => e.key === "Enter" && addBrand()}
              className="flex-1 rounded-xl border border-slate-200 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-teal-400"
            />
            <div className="flex items-center gap-1">
              <input
                type="number"
                min="0"
                max="99"
                step="1"
                placeholder="0"
                value={newMargin}
                onChange={e => setNewMargin(e.target.value)}
                onKeyDown={e => e.key === "Enter" && addBrand()}
                className="w-16 rounded-xl border border-slate-200 px-2 py-2 text-sm text-center focus:outline-none focus:ring-2 focus:ring-teal-400"
              />
              <span className="text-sm text-gray-500">%</span>
            </div>
            <button
              onClick={addBrand}
              disabled={!newBrand.trim()}
              className="rounded-xl bg-slate-100 hover:bg-slate-200 text-gray-700 px-4 py-2 text-sm font-medium disabled:opacity-40 transition-colors"
            >
              + Adicionar
            </button>
          </div>

          {msg && (
            <p className={`text-xs mb-3 ${msg.type === "ok" ? "text-green-600" : "text-red-600"}`}>{msg.text}</p>
          )}

          <button
            onClick={saveMargins}
            disabled={saving}
            className="rounded-xl bg-teal-600 hover:bg-teal-700 text-white px-5 py-2.5 text-sm font-medium disabled:opacity-60 transition-colors"
          >
            {saving ? "Salvandoâ€¦" : "Salvar margens"}
          </button>
        </div>

        {/* Importar / Exportar */}
        <div className="rounded-2xl bg-white border border-slate-100 shadow-sm p-5">
          <h2 className="text-base font-semibold text-gray-800 mb-1">Importar / Exportar</h2>
          <p className="text-xs text-gray-500 mb-4">
            Importe clientes e produtos via planilha Excel, ou exporte seus dados atuais.
          </p>

          {/* Modelo */}
          <div className="rounded-xl bg-teal-50 border border-teal-100 p-4 flex items-center justify-between gap-4 mb-3">
            <div>
              <div className="text-sm font-medium text-teal-800">Modelo de planilha</div>
              <div className="text-xs text-teal-600 mt-0.5">Baixe, preencha e importe. Abas: Clientes e Produtos.</div>
            </div>
            <button
              onClick={downloadTemplate}
              className="flex-shrink-0 rounded-xl bg-teal-600 hover:bg-teal-700 text-white px-4 py-2.5 text-sm font-semibold transition-colors"
            >
              â¬‡ Baixar modelo
            </button>
          </div>

          {/* Exportar */}
          <div className="rounded-xl bg-slate-50 border border-slate-200 p-4 flex items-center justify-between gap-4 mb-3">
            <div>
              <div className="text-sm font-medium text-gray-800">Exportar meus dados</div>
              <div className="text-xs text-gray-500 mt-0.5">Baixa todos os clientes e produtos em Excel.</div>
            </div>
            <button
              onClick={handleExport}
              disabled={exporting}
              className="flex-shrink-0 rounded-xl border border-slate-300 bg-white hover:bg-slate-50 text-gray-700 px-4 py-2.5 text-sm font-medium disabled:opacity-50 transition-colors"
            >
              {exporting ? "Exportandoâ€¦" : "â¬‡ Exportar Excel"}
            </button>
          </div>

          {/* Importar */}
          <div className="space-y-3">
            <div>
              <label className="text-xs font-medium text-gray-600">Importar planilha preenchida (.xlsx)</label>
              <input
                type="file"
                accept=".xlsx,.xls,.csv"
                onChange={handleImportFile}
                className="mt-1 block w-full text-sm text-gray-600 file:mr-3 file:py-2 file:px-4 file:rounded-lg file:border-0 file:bg-teal-50 file:text-teal-700 file:font-medium hover:file:bg-teal-100 cursor-pointer"
              />
            </div>

            {importPreview && (
              <div className="rounded-xl border border-slate-200 p-3 space-y-2">
                <div className="text-xs font-medium text-gray-700">Preview:</div>
                <div className="grid grid-cols-2 gap-2">
                  <div className="rounded-lg bg-blue-50 p-2 text-center">
                    <div className="text-xl font-bold text-blue-700">{importPreview.customers}</div>
                    <div className="text-xs text-blue-600">clientes</div>
                  </div>
                  <div className="rounded-lg bg-green-50 p-2 text-center">
                    <div className="text-xl font-bold text-green-700">{importPreview.products}</div>
                    <div className="text-xs text-green-600">produtos</div>
                  </div>
                </div>
                {importPreview.errors.length > 0 && (
                  <div className="rounded-lg bg-red-50 border border-red-100 p-2">
                    <div className="text-xs font-medium text-red-700 mb-1">{importPreview.errors.length} erro(s):</div>
                    <ul className="text-xs text-red-600 space-y-0.5 list-disc list-inside">
                      {importPreview.errors.slice(0, 3).map((e, i) => <li key={i}>{e}</li>)}
                      {importPreview.errors.length > 3 && <li>...e mais {importPreview.errors.length - 3}</li>}
                    </ul>
                  </div>
                )}
                <button
                  onClick={handleImport}
                  disabled={importing || (importPreview.customers === 0 && importPreview.products === 0)}
                  className="w-full rounded-xl bg-teal-600 hover:bg-teal-700 text-white py-2.5 text-sm font-semibold disabled:opacity-50 transition-colors"
                >
                  {importing ? "Importandoâ€¦" : `Importar ${importPreview.customers + importPreview.products} registros`}
                </button>
              </div>
            )}

            {importMsg && (
              <div className={`text-xs p-2.5 rounded-lg ${importMsg.type === "ok" ? "bg-green-50 text-green-700" : "bg-red-50 text-red-700"}`}>
                {importMsg.text}
              </div>
            )}
          </div>
        </div>

        {/* Alterar senha */}
        <div className="rounded-2xl bg-white border border-slate-100 shadow-sm p-5">
          <h2 className="text-base font-semibold text-gray-800 mb-4">Alterar Senha</h2>
          <form onSubmit={changePassword} className="space-y-3">
            <div>
              <label className="text-xs font-medium text-gray-600">Senha atual</label>
              <input
                type="password"
                autoComplete="current-password"
                className="mt-1 w-full rounded-lg border px-3 py-2 text-sm"
                value={currentPwd}
                onChange={e => setCurrentPwd(e.target.value)}
                required
              />
            </div>
            <div>
              <label className="text-xs font-medium text-gray-600">Nova senha (mín. 6 caracteres)</label>
              <input
                type="password"
                autoComplete="new-password"
                className="mt-1 w-full rounded-lg border px-3 py-2 text-sm"
                value={newPwd}
                onChange={e => setNewPwd(e.target.value)}
                required
              />
            </div>
            {pwdMsg && (
              <p className={`text-xs ${pwdMsg.type === "ok" ? "text-green-600" : "text-red-600"}`}>{pwdMsg.text}</p>
            )}
            <button
              type="submit"
              disabled={pwdSaving}
              className="rounded-xl bg-gray-800 hover:bg-gray-900 text-white px-5 py-2.5 text-sm font-medium disabled:opacity-60 transition-colors"
            >
              {pwdSaving ? "Alterandoâ€¦" : "Alterar senha"}
            </button>
          </form>
        </div>

        {/* Info da conta */}
        <div className="rounded-2xl bg-slate-100 border border-slate-200 p-4 text-xs text-gray-500 space-y-1">
          <div><span className="font-medium">E-mail:</span> {user.email}</div>
          <div><span className="font-medium">Conta criada:</span> {user.metadata.creationTime}</div>
        </div>
      </div>
    </DashboardLayout>
  );
}

