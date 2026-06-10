import { useState } from "react";
import type { AppUser } from "@/App";
import type { PlanStatus } from "@/lib/plan";
import { supabase } from "@/lib/supabase";
import DashboardLayout from "@/ui/DashboardLayout";

const PRICE_PER_MONTH = 29.90;

const MONTH_OPTIONS = [1, 2, 3, 6, 12];

type Props = {
  user: AppUser;
  currentPlan: PlanStatus;
  planExpiresAt?: string | null;
  trialDaysLeft?: number;
};

type PixData = {
  txid: string;
  pixCopiaECola: string;
  qrCodeImage: string | null;
  expiresIn: number;
};

type CreateChargeResponse = PixData & {
  error?: string;
};

export default function PlansPage({ user, currentPlan, planExpiresAt, trialDaysLeft = 0 }: Props) {
  const [months, setMonths] = useState(1);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [pixData, setPixData] = useState<PixData | null>(null);
  const [copied, setCopied] = useState(false);
  const [showForm, setShowForm] = useState(false);

  const [customerName, setCustomerName] = useState("");
  const [customerCpf, setCustomerCpf]   = useState("");
  const [customerEmail, setCustomerEmail] = useState(user.email || "");

  const isPro   = currentPlan === "pro";
  const isTrial = currentPlan === "trial";
  const total   = (PRICE_PER_MONTH * months).toFixed(2).replace(".", ",");

  function formatCpf(v: string) {
    return v.replace(/\D/g, "").slice(0, 11)
      .replace(/(\d{3})(\d)/, "$1.$2")
      .replace(/(\d{3})(\d)/, "$1.$2")
      .replace(/(\d{3})(\d{1,2})$/, "$1-$2");
  }

  async function handleSubscribe() {
    if (!customerName.trim()) { setError("Informe seu nome completo."); return; }
    const cpfClean = customerCpf.replace(/\D/g, "");
    if (cpfClean.length !== 11) { setError("Informe um CPF valido (11 digitos)."); return; }

    setLoading(true);
    setError(null);
    setPixData(null);
    try {
      console.log("[PlansPage] chamando mp-payment", { months });
      const { data, error: invokeError } = await supabase.functions.invoke<CreateChargeResponse>(
        "mp-payment",
        {
          body: {
            action: "create-charge",
            userId: user.uid,
            months,
            customerName: customerName.trim(),
            customerCpf: cpfClean,
            customerEmail: customerEmail.trim(),
          },
        },
      );

      console.log("[PlansPage] resposta mp-payment", data);
      if (invokeError) throw new Error(invokeError.message || "Erro ao criar cobranca");
      if (!data) throw new Error("Resposta vazia ao criar cobranca");
      if (data.error) throw new Error(data.error);
      setPixData(data);
    } catch (e) {
      console.error("[PlansPage] erro create-charge", e);
      setError(e instanceof Error ? e.message : "Erro ao iniciar pagamento");
    } finally {
      setLoading(false);
    }
  }

  async function handleCopy() {
    if (!pixData) return;
    await navigator.clipboard.writeText(pixData.pixCopiaECola);
    setCopied(true);
    setTimeout(() => setCopied(false), 3000);
  }

  return (
    <DashboardLayout title="Planos">
      <div className="max-w-lg mx-auto space-y-6">

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

        {/* Plano Pro */}
        {!isPro && !pixData && (
          <>
            <div className="rounded-2xl bg-white border-2 border-teal-500 p-6 space-y-5">
              <div>
                <div className="text-xs font-bold text-teal-600 uppercase tracking-wider mb-1">Plano Pro</div>
                <div className="flex items-baseline gap-1">
                  <span className="text-4xl font-bold text-gray-900">R$ 29,90</span>
                  <span className="text-sm text-gray-500">/ mes</span>
                </div>
                <ul className="space-y-1.5 text-sm text-gray-600 mt-3">
                  <li>✅ Clientes e produtos ilimitados</li>
                  <li>✅ Registro de vendas e fiado</li>
                  <li>✅ Relatorio financeiro</li>
                  <li>✅ Importar/exportar planilha</li>
                </ul>
              </div>

              {/* Seletor de meses */}
              <div>
                <label className="text-sm font-semibold text-gray-700 block mb-2">
                  Quantos meses deseja pagar?
                </label>
                <div className="flex gap-2 flex-wrap">
                  {MONTH_OPTIONS.map(m => (
                    <button
                      key={m}
                      onClick={() => setMonths(m)}
                      className={`px-4 py-2 rounded-xl text-sm font-semibold border-2 transition-all ${
                        months === m
                          ? "border-teal-500 bg-teal-500 text-white"
                          : "border-slate-200 bg-white text-gray-700 hover:border-teal-300"
                      }`}
                    >
                      {m === 1 ? "1 mes" : `${m} meses`}
                    </button>
                  ))}
                </div>
              </div>

              {/* Resumo do valor */}
              <div className="rounded-xl bg-teal-50 border border-teal-200 p-3 flex items-center justify-between">
                <span className="text-sm text-teal-700">
                  {months === 1 ? "1 mes" : `${months} meses`} de acesso Pro
                </span>
                <span className="text-lg font-bold text-teal-800">R$ {total}</span>
              </div>

              <button
                onClick={() => setShowForm(true)}
                className="w-full rounded-xl bg-teal-600 hover:bg-teal-700 text-white py-3 text-sm font-semibold transition-colors"
              >
                Assinar agora — R$ {total}
              </button>
            </div>

            {/* Formulario */}
            {showForm && (
              <div className="rounded-2xl bg-white border border-slate-200 p-5 space-y-4">
                <h3 className="text-sm font-semibold text-gray-800">Dados para o Pix</h3>

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
                  onClick={handleSubscribe}
                  disabled={loading}
                  className="w-full rounded-xl bg-teal-600 hover:bg-teal-700 text-white py-3 text-sm font-semibold disabled:opacity-50 transition-colors"
                >
                  {loading ? "Gerando Pix..." : `Gerar Pix — R$ ${total}`}
                </button>

                <button
                  onClick={() => { setShowForm(false); setError(null); }}
                  className="w-full text-xs text-gray-400 underline"
                >
                  Voltar
                </button>
              </div>
            )}
          </>
        )}

        {/* QR Code Pix */}
        {pixData && (
          <div className="rounded-2xl bg-white border border-teal-200 p-5 space-y-4 text-center">
            <div className="text-3xl">📱</div>
            <h3 className="text-base font-semibold text-gray-800">Pague com Pix</h3>
            <p className="text-sm text-gray-500">
              Escaneie o QR Code ou copie o codigo abaixo. O plano sera ativado automaticamente apos o pagamento.
            </p>

            {pixData.qrCodeImage && (
              <div className="flex justify-center">
                <img
                  src={pixData.qrCodeImage}
                  alt="QR Code Pix"
                  className="w-52 h-52 rounded-xl border border-slate-200"
                />
              </div>
            )}

            <div className="rounded-xl bg-slate-50 border border-slate-200 p-3 text-xs text-gray-600 break-all font-mono text-left">
              {pixData.pixCopiaECola}
            </div>

            <button
              onClick={handleCopy}
              className="w-full rounded-xl bg-teal-600 hover:bg-teal-700 text-white py-3 text-sm font-semibold transition-colors"
            >
              {copied ? "✅ Copiado!" : "Copiar codigo Pix"}
            </button>

            <p className="text-xs text-gray-400">
              Codigo expira em 30 minutos. Apos o pagamento, aguarde alguns segundos.
            </p>

            <button
              onClick={() => { setPixData(null); setShowForm(false); setError(null); }}
              className="text-xs text-gray-400 underline"
            >
              Cancelar e voltar
            </button>
          </div>
        )}

        <div className="rounded-xl bg-slate-50 border border-slate-200 p-4 text-xs text-gray-500 space-y-1">
          <div>💚 Pagamento seguro via Pix — instantaneo e sem taxas extras</div>
          <div>🔒 Seus dados estao protegidos</div>
          <div>📅 1 mes gratuito para novos usuarios</div>
        </div>

      </div>
    </DashboardLayout>
  );
}
