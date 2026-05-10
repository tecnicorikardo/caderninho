import { Suspense, lazy, useState } from "react";
import type { AppUser } from "@/App";
import { markOnboarded } from "@/lib/profile";
import { downloadWorkbookTemplate } from "@/lib/templates";

const ImportWizard = lazy(() => import("@/pages/components/ImportWizard"));

export default function OnboardingPage({ user, onDone }: { user: AppUser; onDone: () => void }) {
  const [mode, setMode] = useState<"choose" | "import" | "zero">("choose");
  const [busy, setBusy] = useState(false);

  async function startZero() {
    setBusy(true);
    try {
      await markOnboarded(user.uid);
      onDone();
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="min-h-screen p-6 max-w-4xl mx-auto">
      <h1 className="text-2xl font-semibold">Bem-vindo</h1>
      <p className="text-gray-700 mt-1">
        Você prefere importar sua base (clientes/produtos/estoque) ou começar do zero?
      </p>

      <div className="mt-4 flex flex-wrap gap-3">
        <button className="rounded-lg bg-white border px-4 py-3 min-h-12" onClick={() => downloadWorkbookTemplate("full")}>
          Baixar modelo completo (Excel/Sheets)
        </button>
        <button className="rounded-lg bg-white border px-4 py-3 min-h-12" onClick={() => downloadWorkbookTemplate("simple")}>
          Baixar modelo simples
        </button>
      </div>

      {mode === "choose" ? (
        <div className="mt-6 grid gap-4 md:grid-cols-2">
          <button className="text-left rounded-xl bg-white border p-5 hover:shadow-sm min-h-12" onClick={() => setMode("import")}>
            <div className="font-semibold">Importar agora</div>
            <div className="text-sm text-gray-600 mt-1">Use a planilha modelo e envie de volta aqui.</div>
          </button>

          <button
            className="text-left rounded-xl bg-white border p-5 hover:shadow-sm min-h-12 disabled:opacity-60"
            onClick={() => setMode("zero")}
            disabled={busy}
          >
            <div className="font-semibold">Começar do zero</div>
            <div className="text-sm text-gray-600 mt-1">Você poderá cadastrar tudo manualmente depois.</div>
          </button>
        </div>
      ) : null}

      {mode === "import" ? (
        <div className="mt-6">
          <Suspense fallback={<div className="text-sm text-gray-600">Carregando importação…</div>}>
            <ImportWizard
              uid={user.uid}
              onDone={async () => {
                await markOnboarded(user.uid);
                onDone();
              }}
              onBack={() => setMode("choose")}
            />
          </Suspense>
        </div>
      ) : null}

      {mode === "zero" ? (
        <div className="mt-6 rounded-xl bg-white border p-5">
          <p className="text-sm text-gray-700">Confirma começar do zero? Você ainda poderá importar depois.</p>
          <div className="mt-4 flex gap-3">
            <button className="rounded-lg border px-4 py-3 min-h-12" onClick={() => setMode("choose")}>
              Voltar
            </button>
            <button className="rounded-lg bg-gray-900 text-white px-4 py-3 min-h-12 disabled:opacity-60" onClick={startZero} disabled={busy}>
              Confirmar
            </button>
          </div>
        </div>
      ) : null}
    </div>
  );
}
