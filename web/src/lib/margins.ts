import type { Brand, BrandMargin, GrowthLevel } from "@/lib/types";

const defaultMarginTable: Record<string, Record<GrowthLevel, number>> = {
  Natura: { Semente: 20, Ouro: 32, Diamante: 35 },
  Avon: { Semente: 20, Ouro: 38, Diamante: 40 },
  "Casa & Estilo": { Semente: 15, Ouro: 15, Diamante: 20 },
};

export function getMarginPercent(brand: Brand | string, level: GrowthLevel): number {
  const normalized = brand in defaultMarginTable ? (brand as keyof typeof defaultMarginTable) : "Natura";
  return defaultMarginTable[normalized][level] ?? 20;
}

/**
 * Retorna a margem configurada pelo usuário para uma marca.
 * Se não encontrar, usa o fallback da tabela padrão com o nível.
 */
export function getConfiguredMargin(brand: string, brandMargins: BrandMargin[], fallbackLevel: GrowthLevel = "Semente"): number {
  const found = brandMargins.find(b => b.brand.toLowerCase() === brand.toLowerCase());
  if (found) return found.marginPercent;
  return getMarginPercent(brand, fallbackLevel);
}

// Preço de venda = custo / (1 - margem)
export function calculateDynamicMargin(costPriceCents: number, userLevel: GrowthLevel, brand: Brand | string): number {
  const marginPct = getMarginPercent(brand, userLevel);
  const denom = 1 - marginPct / 100;
  if (denom <= 0) return costPriceCents;
  return Math.round(costPriceCents / denom);
}

/**
 * Calcula o preço de venda usando as margens configuradas pelo usuário.
 */
export function calculatePriceFromConfigured(costPriceCents: number, brand: string, brandMargins: BrandMargin[]): number {
  const marginPct = getConfiguredMargin(brand, brandMargins);
  const denom = 1 - marginPct / 100;
  if (denom <= 0) return costPriceCents;
  return Math.round(costPriceCents / denom);
}

