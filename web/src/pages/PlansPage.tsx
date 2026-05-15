import { useState } from "react";
import type { AppUser } from "@/App";
import { PLAN_PRICES } from "@/lib/plan";
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

  async function handleSubscribe(plan: "monthly" | "yearly") {
    setLoading(plan);
    setError(null);
    try {
      const res = await fetch(`${FUNCTION_URL}/create-preference`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ userId: user.uid, plan }),
      });
      const data = await res.json();
      if (!res.ok || data.error) throw new Error(data.error || "Erro ao criar pagamento");

      // Redireciona para o Mercado Pago
      window.location.href = data.initPoint;
    } catch (e) {
      setError(e instanceof Error ? e.message : "Erro ao iniciar pagamento");
      setLoading(null);
    }
  }

  const isPro = currentPlan === "pro";
  const isTrial = currentPlan === "trial";

  return (
    <DashboardLayout title="Planos">
      <div className="max-w-2xl mx-auto space-y-6">

        {/* Status atual */}
        {isTrial && (
          <div className="rounded-2xl bg-teal-50 border border-teal-200 p-4 flex items-center gap-3">
            <div className="text-2xl">🎉</div>
            <div>
              <div className="font-semibold text-teal-800">Você está no período gratuito</div>
              <div className="text-sm text-teal-600">
                {trialDaysLeft > 0
                  ? `Restam ${trialDaysLeft} dia${trialDaysLeft !== 1 ? "s" : ""} de acesso completo gratuito.`
                  : "Seu período gratuito está encerrando. Assine para continuar."}
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
                Válido até {new Date(planExpiresAt).toLocaleDateString("pt-BR")}
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

        <h2 className="text-lg font-semibold text-gray-800">Escolha seu plano</h2>

        <div className="grid gap-4 md:grid-cols-2">

          {/* Plano Mensal */}
          <div className="rounded-2xl bg-white border-2 border-slate-200 p-6 flex flex-col gap-4 hover:border-teal-400 transition-colors">
            <div>
              <div className="text-xs font-bold text-teal-600 uppercase tracking-wider mb-1">Mensal</div>
              <div className="text-3xl font-bold text-gray-900">R$ 29,90</div>
              <div className="text-sm text-gray-500">por mês</div>
            </div>
            <ul className="space-y-2 text-sm text-gray-600 flex-1">
              <li className="flex items-center gap-2">✅ Clientes ilimitados</li>
              <li className="flex items-center gap-2">✅ Produtos ilimitados</li>
              <li className="flex items-center gap-2">✅ Registro de vendas</li>
              <li className="flex items-center gap-2">✅ Controle de fiado</li>
              <li className="flex items-center gap-2">✅ Relatório financeiro</li>
              <li className="flex items-center gap-2">✅ Importar/exportar planilha</li>
            </ul>
            <button
              onClick={() => handleSubscribe("monthly")}
              disabled={loading !== null || isPro}
              className="w-full rounded-xl bg-teal-600 hover:bg-teal-700 text-white py-3 text-sm font-semibold disabled:opacity-50 transition-colors"
            >
              {loading === "monthly" ? "Aguarde…" : isPro ? "Plano ativo" : "Assinar mensal"}
            </button>
          </div>

          {/* Plano Anual */}
          <div className="rounded-2xl bg-white border-2 border-teal-500 p-6 flex flex-col gap-4 relative">
            <div className="absolute -top-3 left-1/2 -translate-x-1/2 bg-teal-500 text-white text-xs font-bold px-3 py-1 rounded-full">
              MELHOR VALOR
            </div>
            <div>
              <div className="text-xs font-bold text-teal-600 uppercase tracking-wider mb-1">Anual</div>
              <div className="text-3xl font-bold text-gray-900">R$ 299,90</div>
              <div className="text-sm text-gray-500">por ano <span className="text-green-600 font-medium">(economize R$ 58,80)</span></div>
            </div>
            <ul className="space-y-2 text-sm text-gray-600 flex-1">
              <li className="flex items-center gap-2">✅ Tudo do plano mensal</li>
              <li className="flex items-center gap-2">✅ 12 meses de acesso</li>
              <li className="flex items-center gap-2">✅ Equivale a R$ 24,99/mês</li>
              <li className="flex items-center gap-2">✅ Suporte prioritário</li>
            </ul>
            <button
              onClick={() => handleSubscribe("yearly")}
              disabled={loading !== null || isPro}
              className="w-full rounded-xl bg-teal-600 hover:bg-teal-700 text-white py-3 text-sm font-semibold disabled:opacity-50 transition-colors"
            >
              {loading === "yearly" ? "Aguarde…" : isPro ? "Plano ativo" : "Assinar anual"}
            </button>
          </div>
        </div>

        {error && (
          <div className="rounded-xl bg-red-50 border border-red-200 p-3 text-sm text-red-700">
            {error}
          </div>
        )}

        <div className="rounded-xl bg-slate-50 border border-slate-200 p-4 text-xs text-gray-500 space-y-1">
          <div>💳 Pagamento seguro via Mercado Pago — cartão, Pix ou boleto</div>
          <div>🔒 Seus dados estão protegidos</div>
          <div>📧 Dúvidas? Entre em contato pelo suporte</div>
        </div>

      </div>
    </DashboardLayout>
  );
}
