import { useEffect, useState } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";
import { databases, DATABASE_ID, COLLECTIONS, Query } from "@/lib/supabase";
import type { AppUser } from "@/App";

export default function PaymentSuccessPage({ user }: { user: AppUser }) {
  const [params] = useSearchParams();
  const navigate = useNavigate();
  const [status, setStatus] = useState<"checking" | "ok" | "pending">("checking");

  useEffect(() => {
    async function verify() {
      // Aguarda 3s para o webhook processar
      await new Promise(r => setTimeout(r, 3000));

      try {
        const res = await databases.listDocuments(DATABASE_ID, COLLECTIONS.PROFILES, [
          Query.equal("userId", user.uid),
          Query.limit(1),
        ]);
        const doc = res.documents[0];
        if (doc?.planStatus === "pro") {
          setStatus("ok");
          setTimeout(() => navigate("/dashboard"), 3000);
        } else {
          setStatus("pending");
        }
      } catch {
        setStatus("pending");
      }
    }
    verify();
  }, [user.uid, navigate]);

  return (
    <div className="min-h-screen flex items-center justify-center p-6 bg-gradient-to-br from-teal-50 to-slate-100">
      <div className="bg-white rounded-2xl shadow-sm border border-slate-100 p-8 max-w-sm w-full text-center space-y-4">
        {status === "checking" && (
          <>
            <div className="text-4xl animate-pulse">⏳</div>
            <div className="text-lg font-semibold text-gray-800">Confirmando pagamento…</div>
            <div className="text-sm text-gray-500">Aguarde alguns instantes.</div>
          </>
        )}
        {status === "ok" && (
          <>
            <div className="text-5xl">🎉</div>
            <div className="text-lg font-semibold text-green-700">Pagamento confirmado!</div>
            <div className="text-sm text-gray-500">Seu plano Pro está ativo. Redirecionando…</div>
          </>
        )}
        {status === "pending" && (
          <>
            <div className="text-4xl">⏳</div>
            <div className="text-lg font-semibold text-orange-700">Pagamento em processamento</div>
            <div className="text-sm text-gray-500 mb-4">
              Seu pagamento está sendo processado. Pode levar alguns minutos.
              Quando aprovado, seu plano será ativado automaticamente.
            </div>
            <button
              onClick={() => navigate("/dashboard")}
              className="w-full rounded-xl bg-teal-600 hover:bg-teal-700 text-white py-3 text-sm font-semibold"
            >
              Voltar ao Dashboard
            </button>
          </>
        )}
      </div>
    </div>
  );
}
