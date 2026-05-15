/**
 * PlanGate — bloqueia acesso a funcionalidades para usuários free
 * Usuários em trial ou pro têm acesso completo.
 */
import { useNavigate } from "react-router-dom";
import type { PlanStatus } from "@/lib/plan";
import { canWrite, trialDaysLeft } from "@/lib/plan";
import type { UserProfile } from "@/lib/types";

type Props = {
  plan: PlanStatus;
  profile?: UserProfile;
  children: React.ReactNode;
};

export default function PlanGate({ plan, profile, children }: Props) {
  const navigate = useNavigate();

  if (canWrite(plan)) {
    return (
      <>
        {plan === "trial" && profile && (
          <TrialBanner daysLeft={trialDaysLeft(profile)} onUpgrade={() => navigate("/plans")} />
        )}
        {children}
      </>
    );
  }

  // Usuário free — mostra bloqueio
  return (
    <div className="min-h-[60vh] flex items-center justify-center p-6">
      <div className="bg-white rounded-2xl border-2 border-slate-200 p-8 max-w-sm w-full text-center space-y-4">
        <div className="text-5xl">🔒</div>
        <div className="text-lg font-semibold text-gray-800">Recurso exclusivo do Plano Pro</div>
        <div className="text-sm text-gray-500">
          Assine o plano Pro para ter acesso completo ao Bloquinho Digital.
          Cadastre clientes, produtos, registre vendas e muito mais.
        </div>
        <button
          onClick={() => navigate("/plans")}
          className="w-full rounded-xl bg-teal-600 hover:bg-teal-700 text-white py-3 text-sm font-semibold transition-colors"
        >
          Ver planos — a partir de R$ 29,90/mês
        </button>
        <button
          onClick={() => navigate("/dashboard")}
          className="w-full rounded-xl border border-slate-200 text-gray-600 py-2.5 text-sm hover:bg-slate-50 transition-colors"
        >
          Voltar ao Dashboard
        </button>
      </div>
    </div>
  );
}

function TrialBanner({ daysLeft, onUpgrade }: { daysLeft: number; onUpgrade: () => void }) {
  if (daysLeft > 7) return null; // só mostra quando faltam 7 dias ou menos

  return (
    <div className="rounded-xl bg-orange-50 border border-orange-200 px-4 py-3 flex items-center justify-between gap-3 mb-4">
      <div className="text-sm text-orange-700">
        <span className="font-semibold">⏳ Trial:</span>{" "}
        {daysLeft > 0
          ? `${daysLeft} dia${daysLeft !== 1 ? "s" : ""} restante${daysLeft !== 1 ? "s" : ""} de acesso gratuito`
          : "Seu período gratuito encerrou hoje"}
      </div>
      <button
        onClick={onUpgrade}
        className="flex-shrink-0 rounded-xl bg-orange-500 hover:bg-orange-600 text-white px-3 py-1.5 text-xs font-bold transition-colors"
      >
        Assinar
      </button>
    </div>
  );
}
