/**
 * plan.ts — Limites e lógica de plano
 *
 * Plano Grátis (trial 30 dias ou sem pagamento):
 *   - Somente visualização de relatório e exportação
 *   - Sem cadastro de vendas, clientes, produtos
 *
 * Plano Pro:
 *   - Mensal: R$ 29,90/mês
 *   - Anual: R$ 299,90/ano (12 meses)
 *   - Tudo ilimitado
 */

import type { UserProfile } from "@/lib/types";

export type PlanStatus = "free" | "pro" | "trial";

export const PLAN_PRICES = {
  monthly: { amountCents: 2990, label: "Mensal", description: "R$ 29,90/mês", months: 1 },
  yearly:  { amountCents: 29990, label: "Anual", description: "R$ 299,90/ano", months: 12, savings: "Economize R$ 58,80" },
} as const;

export const PLAN_LIMITS = {
  free: { products: 100, customers: 50 },
  pro:  { products: Infinity, customers: Infinity },
} as const;

// Período de trial gratuito em dias
export const TRIAL_DAYS = 30;

/**
 * Retorna o status real do plano baseado no perfil do usuário.
 * - Se conta tem menos de 30 dias → trial (acesso completo)
 * - Se planStatus === "pro" e não expirou → pro
 * - Caso contrário → free (somente leitura)
 */
export function getEffectivePlan(profile: UserProfile): PlanStatus {
  const now = new Date();

  // Verificar trial (30 dias desde criação da conta)
  if (profile.createdAt) {
    const createdAt = typeof profile.createdAt === "string"
      ? new Date(profile.createdAt)
      : new Date((profile.createdAt as any).seconds * 1000);
    const diffDays = (now.getTime() - createdAt.getTime()) / (1000 * 60 * 60 * 24);
    if (diffDays < TRIAL_DAYS) return "trial";
  }

  // Verificar plano pro ativo
  if (profile.planStatus === "pro") {
    if (!profile.planExpiresAt) return "pro"; // sem expiração = vitalício
    const expiresAt = typeof profile.planExpiresAt === "string"
      ? new Date(profile.planExpiresAt)
      : new Date((profile.planExpiresAt as any).seconds * 1000);
    if (expiresAt > now) return "pro";
  }

  return "free";
}

/** Dias restantes no trial */
export function trialDaysLeft(profile: UserProfile): number {
  if (!profile.createdAt) return 0;
  const createdAt = typeof profile.createdAt === "string"
    ? new Date(profile.createdAt)
    : new Date((profile.createdAt as any).seconds * 1000);
  const diffDays = (new Date().getTime() - createdAt.getTime()) / (1000 * 60 * 60 * 24);
  return Math.max(0, Math.ceil(TRIAL_DAYS - diffDays));
}

/** Verifica se o usuário pode usar funcionalidades de escrita */
export function canWrite(plan: PlanStatus): boolean {
  return plan === "pro" || plan === "trial";
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
