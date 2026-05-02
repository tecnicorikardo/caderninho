/**
 * plan.ts — Limites do plano gratuito vs Pro
 *
 * Plano Grátis:
 *   - até 100 produtos no estoque
 *   - até 50 clientes
 *   - Relatório Financeiro bloqueado
 *
 * Plano Pro (R$ 29,90/mês):
 *   - tudo ilimitado
 */

export type PlanStatus = "free" | "pro";

export const PLAN_LIMITS = {
  free: {
    products: 100,
    customers: 50,
    financialReport: false,
  },
  pro: {
    products: Infinity,
    customers: Infinity,
    financialReport: true,
  },
} as const;

/** Retorna o plano do usuário — por enquanto todos são "free" até integrar MP */
export function getUserPlan(): PlanStatus {
  return "free";
}

/** Percentual de uso para mostrar barra de progresso */
export function usagePercent(current: number, limit: number): number {
  if (limit === Infinity) return 0;
  return Math.min(100, Math.round((current / limit) * 100));
}

/** Cor da barra de uso */
export function usageColor(pct: number): string {
  if (pct >= 100) return "bg-red-500";
  if (pct >= 80) return "bg-orange-400";
  return "bg-teal-500";
}
