import { useState } from "react";
import type { AppUser } from "@/App";
import type { PlanStatus } from "@/lib/plan";
import DashboardLayout from "@/ui/DashboardLayout";

const FUNCTION_URL = import.meta.env.VITE_APPWRITE_FUNCTION_URL as string;

type Props = {
  user: AppUser;
  currentPlan: PlanStatus;
  planExpiresAt?: string | null;
  trialDaysLeft?: number;
};

export default function PlansPage({ user, currentPlan, planExpiresAt, trialDaysLeft = 0 }: Props) {
  const [loading, setLoading] = useState<"monthly" | "yearly" | null>(null);
  const [error, setError] = useState<string | null>(null);

  // Dados do cliente para a cobrança
  const [customerName, setCustomerName] = useState("");
  const [customerCpf, setCustomerCpf]   = useState("");
  const [customerEmail, setCustomerEmail] = useState(user.email || "");
  const [selectedPlan, setSelectedPlan] = useState<"monthly" | "yearly" | null>(null);

  const isPro   = currentPlan === "pro";
  const isTrial = currentPlan === "trial";

  function formatCpf(v: string) {
    return v.replace(/\D/g, "").slice(0, 11)
      .replace(/(\d{3})(\d)/, "$1.$2")
      .replace(/(\d{3})(\d)/, "$1.$2")
      .replace(/(\d{3})(\d{1,2})$/, "$1-$2");
  }

  async function handleSubscribe(plan: "monthly" | "yearly") {
    if (!customerName.trim()) { setError("Informe seu nome completo."); return; }
    const cpfClean = customerCpf.replace(/\D/g, "");
    if (cpfClean.length !== 11) { setError("Informe um CPF valido (11 digitos)."); return; }

    setLoading(plan);
    setError(null);
    try {
      const res = await fetch(`${FUNCTION_URL}/create-charge`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          userId: user.uid,
          plan,
          customerName: customerName.trim(),
          customerCpf: cpfClean,
          customerEmail: customerEmail.trim(),
        }),
      });
      const data = await res.json();
      if (!res.ok || data.error) throw new Error(data.error || "Erro ao criar cobranca");

      // Redireciona para o link de pagamento EFI
      window.location.href = data.paymentUrl;
    } catch (e) {
      setError(e instanceof Error ? e.message : "Erro ao iniciar pagamento");
      setLoading(null);
    }
  }

  return (
    <DashboardLayout title="Planos">
      <div className="max-w-2xl mx-auto space-y-6">

        {/* Status atual */}
        {isTrial && (
          <div className="rounded-2xl bg-teal-50 border border-teal-200 p-4 flex items-center gap-3">
            <div className="text-2xl">🎉</div>
            <div>
              <div className="font-semibold text-teal-800">Voce esta no periodo gratuito</div>
              <div className="text-sm text-teal-600">
                {trialDaysLeft > 0
                  ? `Restam ${trialDaysLeft} dia${trialDaysLeft !== 1 ? "s" : ""} de acesso completo gratuito.`
                  : "Seu periodo gratuito esta encerrando. Assine para continuar."}
              </div>
            </div>
          </div>
        )}

        {isPro && planExpiresAt && (
          <div className="rounded-2xl bg-green-50 border border-green-200 p-4 flex items-center gap-3">
            <div className="text-2xl">✅</div>
            <div>
              <div className="font-semibold text-green-800">Plano Pro ativo</div>
              <div className="text-sm text-green-600">
                Valido ate {new Date(planExpiresAt).toLocaleDateString("pt-BR")}
              </div>
            </div>
          </div>
        )}

        {currentPlan === "free" && (
          <div className="rounded-2xl bg-red-50 border border-red-200 p-4 flex items-center gap-3">
            <div className="text-2xl">🔒</div>
            <div>
              <div className="font-semibold text-red-800">Acesso limitado</div>
              <div className="text-sm text-red-600">
                Assine o plano Pro para cadastrar vendas, clientes e produtos.
              </div>
            </div>
          </div>
        )}

        {/* Planos */}
        {!isPro && (
          <>
            <h2 className="text-lg font-semibold text-gray-800">Escolha seu plano</h2>

            <div className="grid gap-4 md:grid-cols-2">
              {/* Mensal */}
              <button
                onClick={() => setSelectedPlan(selectedPlan === "monthly" ? null : "monthly")}
                className={`rounded-2xl border-2 p-6 text-left transition-all ${selectedPlan === "monthly" ? "border-teal-500 bg-teal-50" : "border-slate-200 bg-white hover:border-teal-300"}`}
              >
                <div className="text-xs font-bold text-teal-600 uppercase tracking-wider mb-1">Mensal</div>
                <div className="text-3xl font-bold text-gray-900">R$ 29,90</div>
                <div className="text-sm text-gray-500">por mes</div>
                <ul className="space-y-1.5 text-sm text-gray-600 mt-4">
                  <li>✅ Clientes e produtos ilimitados</li>
                  <li>✅ Registro de vendas e fiado</li>
                  <li>✅ Relatorio financeiro</li>
                  <li>✅ Importar/exportar planilha</li>
                </ul>
              </button>

              {/* Anual */}
              <button
                onClick={() => setSelectedPlan(selectedPlan === "yearly" ? null : "yearly")}
                className={`rounded-2xl border-2 p-6 text-left relative transition-all ${selectedPlan === "yearly" ? "border-teal-500 bg-teal-50" : "border-teal-400 bg-white hover:border-teal-500"}`}
              >
                <div className="absolute -top-3 left-1/2 -translate-x-1/2 bg-teal-500 text-white text-xs font-bold px-3 py-1 rounded-full">
                  MELHOR VALOR
                </div>
                <div className="text-xs font-bold text-teal-600 uppercase tracking-wider mb-1">Anual</div>
                <div className="text-3xl font-bold text-gray-900">R$ 299,90</div>
                <div className="text-sm text-gray-500">por ano <span className="text-green-600 font-medium">(economize R$ 58,80)</span></div>
                <ul className="space-y-1.5 text-sm text-gray-600 mt-4">
                  <li>✅ Tudo do plano mensal</li>
                  <li>✅ 12 meses de acesso</li>
                  <li>✅ Equivale a R$ 24,99/mes</li>
                </ul>
              </button>
            </div>

            {/* Formulario de dados para cobrança */}
            {selectedPlan && (
              <div className="rounded-2xl bg-white border border-slate-200 p-5 space-y-4">
                <h3 className="text-sm font-semibold text-gray-800">Dados para a cobranca</h3>

                <div>
                  <label className="inp-label">Nome completo *</label>
                  <input
                    type="text"
                    className="inp"
                    placeholder="Seu nome completo"
                    value={customerName}
                    onChange={e => setCustomerName(e.target.value)}
                  />
                </div>

                <div>
                  <label className="inp-label">CPF *</label>
                  <input
                    type="text"
                    className="inp"
                    placeholder="000.000.000-00"
                    value={customerCpf}
                    onChange={e => setCustomerCpf(formatCpf(e.target.value))}
                    maxLength={14}
                  />
                </div>

                <div>
                  <label className="inp-label">E-mail</label>
                  <input
                    type="email"
                    className="inp"
                    placeholder="seu@email.com"
                    value={customerEmail}
                    onChange={e => setCustomerEmail(e.target.value)}
                  />
                </div>

                {error && (
                  <div className="rounded-xl bg-red-50 border border-red-200 p-3 text-sm text-red-700">
                    {error}
                  </div>
                )}

                <button
                  onClick={() => handleSubscribe(selectedPlan)}
                  disabled={loading !== null}
                  className="w-full rounded-xl bg-teal-600 hover:bg-teal-700 text-white py-3 text-sm font-semibold disabled:opacity-50 transition-colors"
                >
                  {loading
                    ? "Gerando cobranca..."
                    : selectedPlan === "monthly"
                      ? "Assinar por R$ 29,90/mes"
                      : "Assinar por R$ 299,90/ano"}
                </button>

                <p className="text-xs text-gray-400 text-center">
                  Voce sera redirecionado para a pagina de pagamento seguro (Pix, boleto ou cartao)
                </p>
              </div>
            )}
          </>
        )}

        <div className="rounded-xl bg-slate-50 border border-slate-200 p-4 text-xs text-gray-500 space-y-1">
          <div>💳 Pagamento seguro via EFI Bank — Pix, boleto ou cartao</div>
          <div>🔒 Seus dados estao protegidos</div>
          <div>📅 1 mes gratuito para novos usuarios</div>
        </div>

      </div>
    </DashboardLayout>
  );
}
