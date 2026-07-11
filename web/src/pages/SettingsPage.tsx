import { useEffect, useState } from "react";
import type { AppUser } from "@/App";
import { databases, DATABASE_ID, COLLECTIONS, Query, account } from "@/lib/supabase";
import { nowISO } from "@/lib/timestamp";
import { applyTheme, cacheThemeColor, getCachedThemeColor, PRESET_COLORS, DEFAULT_COLOR } from "@/lib/theme";
import { updateUserProfile } from "@/lib/profile";
import DashboardLayout from "@/ui/DashboardLayout";
import type { BrandMargin } from "@/lib/types";
import { downloadTemplate, exportData, parseImportFile, importFromWorkbook } from "@/lib/spreadsheet";
import type { ImportPreview } from "@/lib/spreadsheet";
import type { WorkBook } from "xlsx";

const DEFAULT_BRANDS: BrandMargin[] = [
  { brand: "Natura", marginPercent: 30 },
  { brand: "Avon", marginPercent: 30 },
  { brand: "Casa & Estilo", marginPercent: 15 },
];

const WIPE_PAGE_SIZE = 10;
const WIPE_DELETE_DELAY_MS = 650;
const WIPE_PAGE_DELAY_MS = 1200;
const WIPE_RETRY_DELAYS_MS = [2500, 5000, 10000, 20000];

const sleep = (ms: number) => new Promise(resolve => setTimeout(resolve, ms));

function getServiceStatus(error: unknown) {
  return Number((error as any)?.code ?? (error as any)?.status ?? 0);
}

export default function SettingsPage({ user }: { user: AppUser }) {
  const [brandMargins, setBrandMargins] = useState<BrandMargin[]>(DEFAULT_BRANDS);
  const [saving, setSaving] = useState(false);
  const [msg, setMsg] = useState<{ type: "ok" | "err"; text: string } | null>(null);

  // Tema / cor
  const [themeColor, setThemeColor] = useState(() => getCachedThemeColor() ?? DEFAULT_COLOR);
  const [themeSaving, setThemeSaving] = useState(false);
  const [themeMsg, setThemeMsg] = useState<{ type: "ok" | "err"; text: string } | null>(null);

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

  // Apagar tudo
  const [wiping, setWiping] = useState(false);
  const [wipeConfirm, setWipeConfirm] = useState("");
  const [showWipe, setShowWipe] = useState(false);
  const [wipeProgress, setWipeProgress] = useState<{ label: string; current: number; total: number } | null>(null);
  const [importProgress, setImportProgress] = useState<{ label: string; current: number; total: number } | null>(null);

  // ID do documento de perfil no Supabase
  const [profileDocId, setProfileDocId] = useState<string | null>(null);

  useEffect(() => {
    async function load() {
      const res = await databases.listDocuments(DATABASE_ID, COLLECTIONS.PROFILES, [
        Query.equal("userId", user.uid),
        Query.limit(1),
      ]);
      if (res.documents.length > 0) {
        const doc = res.documents[0];
        setProfileDocId(doc.$id);
        // brandMargins vem como string JSON do Supabase
        try {
          const raw = doc.brandMargins;
          let parsed: unknown = raw;
          if (typeof raw === "string" && raw.trim().startsWith("[")) {
            parsed = JSON.parse(raw);
          }
          if (Array.isArray(parsed) && parsed.length > 0) {
            setBrandMargins(parsed as BrandMargin[]);
          }
        } catch { /* mantém DEFAULT_BRANDS */ }

        // Cor do tema
        if (doc.themeColor) {
          setThemeColor(doc.themeColor as string);
        }
      }
    }
    load().catch(console.error);
  }, [user.uid]);

  // ── Tema ──────────────────────────────────────────────────────────────────

  function handleColorChange(color: string) {
    setThemeColor(color);
    applyTheme(color); // preview em tempo real
  }

  async function saveTheme() {
    setThemeSaving(true);
    setThemeMsg(null);
    try {
      await updateUserProfile(user.uid, { themeColor });
      cacheThemeColor(themeColor);
      setThemeMsg({ type: "ok", text: "Cor salva com sucesso!" });
    } catch (e) {
      setThemeMsg({ type: "err", text: e instanceof Error ? e.message : "Erro ao salvar." });
    } finally {
      setThemeSaving(false);
    }
  }

  // ── Margens ───────────────────────────────────────────────────────────────

  async function saveMargins() {
    setSaving(true);
    setMsg(null);
    try {
      if (profileDocId) {
        await databases.updateDocument(DATABASE_ID, COLLECTIONS.PROFILES, profileDocId, {
          brandMargins: JSON.stringify(brandMargins),
          updatedAt: nowISO(),
        });
      }
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
    setNewBrand(""); setNewMargin(""); setMsg(null);
  }

  // ── Importar / Exportar ───────────────────────────────────────────────────

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
    setImporting(true); setImportMsg(null); setImportProgress(null);
    try {
      const result = await importFromWorkbook(user.uid, importWb, (label, current, total) => {
        setImportProgress({ label, current, total });
      });
      setImportMsg({ type: "ok", text: `Importado: ${result.customers} clientes e ${result.products} produtos.` });
      setImportPreview(null); setImportWb(null);
    } catch (ex) {
      setImportMsg({ type: "err", text: ex instanceof Error ? ex.message : "Erro ao importar." });
    } finally { setImporting(false); setImportProgress(null); }
  }

  // ── Alterar senha ─────────────────────────────────────────────────────────

  async function changePassword(e: React.FormEvent) {
    e.preventDefault();
    if (newPwd.length < 6) {
      setPwdMsg({ type: "err", text: "A nova senha deve ter pelo menos 6 caracteres." });
      return;
    }
    setPwdSaving(true); setPwdMsg(null);
    try {
      await account.createEmailPasswordSession(user.email, currentPwd);
      await account.updatePassword(newPwd, currentPwd);
      setCurrentPwd(""); setNewPwd("");
      setPwdMsg({ type: "ok", text: "Senha alterada com sucesso!" });
    } catch (e) {
      setPwdMsg({ type: "err", text: e instanceof Error ? e.message : "Erro ao alterar senha." });
    } finally { setPwdSaving(false); }
  }

  // ── Apagar tudo ───────────────────────────────────────────────────────────

  async function handleWipeAll() {
    if (wipeConfirm !== "APAGAR") return;
    setWiping(true);
    setWipeProgress(null);
    try {
      const deleteDocumentWithRetry = async (collectionId: string, documentId: string, label: string, current: number, total: number) => {
        for (let attempt = 0; attempt <= WIPE_RETRY_DELAYS_MS.length; attempt++) {
          try {
            await databases.deleteDocument(DATABASE_ID, collectionId, documentId);
            return;
          } catch (err) {
            if (getServiceStatus(err) !== 429 || attempt === WIPE_RETRY_DELAYS_MS.length) {
              throw err;
            }

            const waitMs = WIPE_RETRY_DELAYS_MS[attempt];
            setWipeProgress({ label: `${label} aguardando limite...`, current, total });
            await sleep(waitMs);
          }
        }
      };

      const deleteAll = async (collectionId: string, label: string) => {
        // Primeiro conta quantos existem
        const countRes = await databases.listDocuments(DATABASE_ID, collectionId, [
          Query.equal("userId", user.uid), Query.limit(1),
        ]);
        // A camada de dados retorna o total no campo total
        let deleted = 0;
        const total = (countRes as any).total ?? 0;
        if (total === 0) return;

        setWipeProgress({ label, current: 0, total });

        while (true) {
          const res = await databases.listDocuments(DATABASE_ID, collectionId, [
            Query.equal("userId", user.uid), Query.limit(WIPE_PAGE_SIZE),
          ]);
          if (res.documents.length === 0) break;

          for (const doc of res.documents) {
            await deleteDocumentWithRetry(collectionId, doc.$id, label, deleted, total);
            deleted++;
            setWipeProgress({ label, current: deleted, total });
            await sleep(WIPE_DELETE_DELAY_MS);
          }
          if (res.documents.length < WIPE_PAGE_SIZE) break;
          await sleep(WIPE_PAGE_DELAY_MS);
        }
      };

      await deleteAll(COLLECTIONS.SALES, "Apagando vendas…");
      await deleteAll(COLLECTIONS.RECEIVABLES, "Apagando recebíveis…");
      await deleteAll(COLLECTIONS.MOVEMENTS, "Apagando movimentações…");
      await deleteAll(COLLECTIONS.INVENTORY, "Apagando estoque…");
      await deleteAll(COLLECTIONS.CUSTOMERS, "Apagando clientes…");

      setShowWipe(false);
      setWipeConfirm("");
      setWipeProgress(null);
      alert("✅ Todos os dados foram apagados com sucesso!");
    } catch (e) {
      alert("Erro ao apagar dados: " + (e instanceof Error ? e.message : String(e)));
    } finally {
      setWiping(false);
      setWipeProgress(null);
    }
  }

  // ── Render ────────────────────────────────────────────────────────────────

  return (
    <DashboardLayout title="Configurações">
      <div className="space-y-6 max-w-2xl">

        {/* Perfil */}
        <div className="card-brand p-5">
          <h2 className="text-base font-semibold text-gray-800 mb-3">Meu Perfil</h2>
          <div className="flex items-center gap-4">
            <div className="w-14 h-14 rounded-full flex items-center justify-center text-white font-bold text-2xl" style={{ backgroundColor: themeColor }}>
              {(user.email ?? "U").charAt(0).toUpperCase()}
            </div>
            <div>
              <div className="font-semibold text-gray-900">{user.email}</div>
              <div className="text-sm text-gray-500">Conta ativa</div>
            </div>
          </div>
        </div>

        {/* ── Personalização de Cores ── */}
        <div className="card-brand p-5">
          <h2 className="text-base font-semibold text-gray-800 mb-1">🎨 Cor do Sistema</h2>
          <p className="text-xs text-gray-500 mb-4">
            Escolha a cor principal do app. Afeta o header, botões e bordas dos cards.
          </p>

          {/* Presets */}
          <div className="flex flex-wrap gap-2 mb-4">
            {PRESET_COLORS.map(c => (
              <button
                key={c.value}
                onClick={() => handleColorChange(c.value)}
                title={c.label}
                className="w-9 h-9 rounded-xl border-2 transition-all hover:scale-110"
                style={{
                  backgroundColor: c.value,
                  borderColor: themeColor === c.value ? "#111827" : "transparent",
                  boxShadow: themeColor === c.value ? "0 0 0 2px white, 0 0 0 4px #111827" : "none",
                }}
              />
            ))}
          </div>

          {/* Cor customizada */}
          <div className="flex items-center gap-3 mb-4">
            <label className="text-xs font-medium text-gray-600">Cor personalizada:</label>
            <input
              type="color"
              value={themeColor}
              onChange={e => handleColorChange(e.target.value)}
              className="w-10 h-10 rounded-lg border-2 border-slate-200 cursor-pointer p-0.5"
            />
            <span className="text-xs font-mono text-gray-500">{themeColor}</span>
          </div>

          {/* Preview */}
          <div className="rounded-xl p-3 mb-4 flex items-center gap-3" style={{ backgroundColor: themeColor + "15", border: `2px solid ${themeColor}40` }}>
            <div className="w-8 h-8 rounded-lg flex items-center justify-center text-white text-sm font-bold" style={{ backgroundColor: themeColor }}>B</div>
            <span className="text-sm font-medium" style={{ color: themeColor }}>Preview da cor selecionada</span>
          </div>

          {themeMsg && (
            <p className={`text-xs mb-3 ${themeMsg.type === "ok" ? "text-green-600" : "text-red-600"}`}>{themeMsg.text}</p>
          )}

          <button
            onClick={saveTheme}
            disabled={themeSaving}
            className="rounded-xl text-white px-5 py-2.5 text-sm font-medium disabled:opacity-60 transition-colors btn-brand"
          >
            {themeSaving ? "Salvando…" : "Salvar cor"}
          </button>
        </div>

        {/* ── Comissão por Marca ── */}
        <div className="card-brand p-5">
          <h2 className="text-base font-semibold text-gray-800 mb-1">Comissão por Marca</h2>
          <p className="text-xs text-gray-500 mb-4">
            Configure a porcentagem que você ganha de cada marca.
          </p>

          <div className="space-y-2 mb-4">
            {(Array.isArray(brandMargins) ? brandMargins : []).map((b, i) => (
              <div key={i} className="flex items-center gap-3 p-3 rounded-xl bg-slate-50 border border-slate-100">
                <div className="w-9 h-9 rounded-lg flex items-center justify-center text-white font-bold text-sm flex-shrink-0" style={{ backgroundColor: themeColor }}>
                  {b.brand.charAt(0)}
                </div>
                <div className="flex-1 font-medium text-gray-800 text-sm">{b.brand}</div>
                <div className="flex items-center gap-1">
                  <input
                    type="number" min="0" max="99" step="1"
                    value={b.marginPercent}
                    onChange={e => updateMargin(i, e.target.value)}
                    className="w-16 rounded-lg border-2 border-slate-300 bg-slate-50 px-2 py-1.5 text-sm text-center font-semibold focus:outline-none focus:border-teal-500"
                    style={{ color: themeColor }}
                  />
                  <span className="text-sm text-gray-500 font-medium">%</span>
                </div>
                <button onClick={() => removeBrand(i)} className="text-gray-300 hover:text-red-500 text-xl leading-none transition-colors" title="Remover">×</button>
              </div>
            ))}
          </div>

          <div className="flex gap-2 mb-4">
            <input type="text" placeholder="Nome da marca" value={newBrand} onChange={e => setNewBrand(e.target.value)} onKeyDown={e => e.key === "Enter" && addBrand()} className="inp flex-1" />
            <div className="flex items-center gap-1">
              <input type="number" min="0" max="99" step="1" placeholder="0" value={newMargin} onChange={e => setNewMargin(e.target.value)} onKeyDown={e => e.key === "Enter" && addBrand()} className="w-16 rounded-xl border-2 border-slate-300 bg-slate-50 px-2 py-2.5 text-sm text-center focus:outline-none focus:border-teal-500" />
              <span className="text-sm text-gray-500">%</span>
            </div>
            <button onClick={addBrand} disabled={!newBrand.trim()} className="rounded-xl bg-slate-100 hover:bg-slate-200 text-gray-700 px-4 py-2 text-sm font-medium disabled:opacity-40 transition-colors">+ Adicionar</button>
          </div>

          {msg && <p className={`text-xs mb-3 ${msg.type === "ok" ? "text-green-600" : "text-red-600"}`}>{msg.text}</p>}

          <button onClick={saveMargins} disabled={saving} className="rounded-xl text-white px-5 py-2.5 text-sm font-medium disabled:opacity-60 transition-colors btn-brand">
            {saving ? "Salvando…" : "Salvar margens"}
          </button>
        </div>

        {/* ── Importar / Exportar ── */}
        <div className="card-brand p-5">
          <h2 className="text-base font-semibold text-gray-800 mb-1">Importar / Exportar</h2>
          <p className="text-xs text-gray-500 mb-4">Importe clientes e produtos via planilha Excel, ou exporte seus dados.</p>

          <div className="rounded-xl p-4 flex items-center justify-between gap-4 mb-3" style={{ backgroundColor: themeColor + "10", border: `1px solid ${themeColor}30` }}>
            <div>
              <div className="text-sm font-medium" style={{ color: themeColor }}>Modelo de planilha</div>
              <div className="text-xs text-gray-500 mt-0.5">Baixe, preencha e importe. Abas: Clientes e Produtos.</div>
            </div>
            <button onClick={downloadTemplate} className="flex-shrink-0 rounded-xl text-white px-4 py-2.5 text-sm font-semibold transition-colors btn-brand">⬇ Baixar modelo</button>
          </div>

          <div className="rounded-xl bg-slate-50 border border-slate-200 p-4 flex items-center justify-between gap-4 mb-3">
            <div>
              <div className="text-sm font-medium text-gray-800">Exportar meus dados</div>
              <div className="text-xs text-gray-500 mt-0.5">Baixa todos os clientes e produtos em Excel.</div>
            </div>
            <button onClick={handleExport} disabled={exporting} className="flex-shrink-0 rounded-xl border border-slate-300 bg-white hover:bg-slate-50 text-gray-700 px-4 py-2.5 text-sm font-medium disabled:opacity-50 transition-colors">
              {exporting ? "Exportando…" : "⬇ Exportar Excel"}
            </button>
          </div>

          <div className="space-y-3">
            <div>
              <label className="text-xs font-medium text-gray-600">Importar planilha preenchida (.xlsx)</label>
              <input type="file" accept=".xlsx,.xls,.csv" onChange={handleImportFile} className="mt-1 block w-full text-sm text-gray-600 file:mr-3 file:py-2 file:px-4 file:rounded-lg file:border-0 file:bg-teal-50 file:text-teal-700 file:font-medium hover:file:bg-teal-100 cursor-pointer" />
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
                <button onClick={handleImport} disabled={importing || (importPreview.customers === 0 && importPreview.products === 0)} className="w-full rounded-xl text-white py-2.5 text-sm font-semibold disabled:opacity-50 transition-colors btn-brand">
                  {importing ? "Importando…" : `Importar ${importPreview.customers + importPreview.products} registros`}
                </button>
              </div>
            )}
            {importing && importProgress && (
              <div className="rounded-xl border border-slate-200 p-3 space-y-2">
                <div className="flex items-center justify-between text-xs text-gray-600">
                  <span className="font-medium">{importProgress.label}</span>
                  <span>{importProgress.current} / {importProgress.total}</span>
                </div>
                <div className="w-full bg-slate-100 rounded-full h-2">
                  <div className="h-2 rounded-full transition-all duration-200 btn-brand" style={{ width: `${Math.round((importProgress.current / importProgress.total) * 100)}%`, backgroundColor: themeColor }} />
                </div>
                <p className="text-xs text-gray-400">Não feche esta página durante a importação.</p>
              </div>
            )}
            {importMsg && (
              <div className={`text-xs p-2.5 rounded-lg ${importMsg.type === "ok" ? "bg-green-50 text-green-700" : "bg-red-50 text-red-700"}`}>{importMsg.text}</div>
            )}
          </div>
        </div>

        {/* ── Alterar Senha ── */}
        <div className="card-brand p-5">
          <h2 className="text-base font-semibold text-gray-800 mb-4">Alterar Senha</h2>
          <form onSubmit={changePassword} className="space-y-3">
            <div>
              <label className="inp-label">Senha atual</label>
              <input type="password" autoComplete="current-password" className="inp" value={currentPwd} onChange={e => setCurrentPwd(e.target.value)} required />
            </div>
            <div>
              <label className="inp-label">Nova senha (mín. 6 caracteres)</label>
              <input type="password" autoComplete="new-password" className="inp" value={newPwd} onChange={e => setNewPwd(e.target.value)} required />
            </div>
            {pwdMsg && <p className={`text-xs ${pwdMsg.type === "ok" ? "text-green-600" : "text-red-600"}`}>{pwdMsg.text}</p>}
            <button type="submit" disabled={pwdSaving} className="rounded-xl bg-gray-800 hover:bg-gray-900 text-white px-5 py-2.5 text-sm font-medium disabled:opacity-60 transition-colors">
              {pwdSaving ? "Alterando…" : "Alterar senha"}
            </button>
          </form>
        </div>

        {/* ── Zona de Perigo — Apagar Tudo ── */}
        <div className="rounded-2xl bg-white border-2 border-red-200 p-5">
          <h2 className="text-base font-semibold text-red-700 mb-1">⚠️ Zona de Perigo</h2>
          <p className="text-xs text-gray-500 mb-4">
            Apaga permanentemente todos os seus dados: clientes, produtos, vendas, recebíveis e movimentações. <strong>Essa ação não pode ser desfeita.</strong>
          </p>

          {!showWipe ? (
            <button
              onClick={() => setShowWipe(true)}
              className="rounded-xl bg-red-50 hover:bg-red-100 text-red-700 border border-red-200 px-5 py-2.5 text-sm font-medium transition-colors"
            >
              🗑️ Apagar todos os dados
            </button>
          ) : (
            <div className="space-y-3">
              <div className="rounded-xl bg-red-50 border border-red-200 p-3">
                <p className="text-xs text-red-700 font-medium mb-2">
                  Para confirmar, digite <strong>APAGAR</strong> no campo abaixo:
                </p>
                <input
                  type="text"
                  value={wipeConfirm}
                  onChange={e => setWipeConfirm(e.target.value)}
                  placeholder="Digite APAGAR"
                  className="inp border-red-300 focus:border-red-500"
                />
              </div>
              <div className="flex gap-2">
                <button
                  onClick={() => { setShowWipe(false); setWipeConfirm(""); }}
                  className="rounded-xl border border-slate-300 bg-white px-4 py-2.5 text-sm text-gray-600 hover:bg-slate-50 transition-colors"
                >
                  Cancelar
                </button>
                <button
                  onClick={handleWipeAll}
                  disabled={wipeConfirm !== "APAGAR" || wiping}
                  className="rounded-xl bg-red-600 hover:bg-red-700 text-white px-5 py-2.5 text-sm font-semibold disabled:opacity-40 transition-colors"
                >
                  {wiping ? "Apagando…" : "Confirmar — Apagar tudo"}
                </button>
              </div>
              {wiping && wipeProgress && (
                <div className="rounded-xl border border-red-100 bg-red-50 p-3 space-y-2">
                  <div className="flex items-center justify-between text-xs text-red-700">
                    <span className="font-medium">{wipeProgress.label}</span>
                    <span>{wipeProgress.current} / {wipeProgress.total}</span>
                  </div>
                  <div className="w-full bg-red-100 rounded-full h-2">
                    <div className="h-2 rounded-full bg-red-500 transition-all duration-200"
                      style={{ width: `${Math.round((wipeProgress.current / wipeProgress.total) * 100)}%` }} />
                  </div>
                  <p className="text-xs text-red-400">Não feche esta página.</p>
                </div>
              )}
            </div>
          )}
        </div>

        {/* Info da conta */}
        <div className="rounded-2xl bg-slate-100 border border-slate-200 p-4 text-xs text-gray-500 space-y-1">
          <div><span className="font-medium">E-mail:</span> {user.email}</div>
        </div>

        {/* Suporte */}
        <div className="rounded-2xl bg-white border border-slate-200 p-5 space-y-3">
          <h2 className="text-sm font-semibold text-gray-800">Suporte e Contato</h2>
          <p className="text-xs text-gray-500">
            Precisa de ajuda ou encontrou algum problema? Entre em contato com o suporte.
          </p>
          <div className="space-y-2">
            <a
              href="mailto:tecnicorikardo@gmail.com"
              className="flex items-center gap-3 rounded-xl bg-slate-50 border border-slate-200 px-4 py-3 hover:bg-teal-50 hover:border-teal-200 transition-colors"
            >
              <span className="text-lg">✉️</span>
              <div>
                <div className="text-xs font-medium text-gray-700">E-mail</div>
                <div className="text-xs text-teal-600">tecnicorikardo@gmail.com</div>
              </div>
            </a>
            <a
              href="https://wa.me/5521970902074"
              target="_blank"
              rel="noopener noreferrer"
              className="flex items-center gap-3 rounded-xl bg-slate-50 border border-slate-200 px-4 py-3 hover:bg-green-50 hover:border-green-200 transition-colors"
            >
              <span className="text-lg">💬</span>
              <div>
                <div className="text-xs font-medium text-gray-700">WhatsApp</div>
                <div className="text-xs text-green-600">(21) 97090-2074</div>
              </div>
            </a>
          </div>
          <p className="text-xs text-gray-400 text-center pt-1">
            Bloquinho Digital v1.0 — Desenvolvido por Ricardo Martins
          </p>
        </div>

      </div>
    </DashboardLayout>
  );
}
