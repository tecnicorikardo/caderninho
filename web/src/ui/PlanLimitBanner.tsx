/**
 * PlanLimitBanner — mostra uso atual vs limite do plano grátis
 * Aparece quando o usuário está acima de 80% do limite.
 */
import { usageColor, usagePercent } from "@/lib/plan";

type Props = {
  current: number;
  limit: number;
  label: string; // ex: "produtos", "clientes"
};

export default function PlanLimitBanner({ current, limit, label }: Props) {
  if (limit === Infinity) return null;

  const pct = usagePercent(current, limit);
  if (pct < 80) return null; // só mostra quando está perto do limite

  const atLimit = current >= limit;

  return (
    <div className={`rounded-xl border px-4 py-3 flex items-center justify-between gap-3 ${
      atLimit
        ? "bg-red-50 border-red-200"
        : "bg-orange-50 border-orange-200"
    }`}>
      <div className="flex-1 min-w-0">
        <div className={`text-sm font-bold ${atLimit ? "text-red-700" : "text-orange-700"}`}>
          {atLimit
            ? `🚫 Limite de ${label} atingido (${current}/${limit})`
            : `⚠️ Quase no limite de ${label} (${current}/${limit})`
          }
        </div>
        <div className="mt-1.5 h-1.5 w-full bg-slate-200 rounded-full overflow-hidden">
          <div
            className={`h-full rounded-full transition-all ${usageColor(pct)}`}
            style={{ width: `${pct}%` }}
          />
        </div>
        {atLimit && (
          <div className="text-xs text-red-600 mt-1">
            Assine o plano Pro para adicionar mais {label}.
          </div>
        )}
      </div>
      <a
        href="/settings#plano"
        className={`flex-shrink-0 rounded-xl px-3 py-2 text-xs font-bold transition-colors ${
          atLimit
            ? "bg-red-600 hover:bg-red-700 text-white"
            : "bg-orange-500 hover:bg-orange-600 text-white"
        }`}
      >
        Ver planos
      </a>
    </div>
  );
}
