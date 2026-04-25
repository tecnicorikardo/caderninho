import type { Brand, GrowthLevel } from "@/lib/types";

const marginTable: Record<string, Record<GrowthLevel, number>> = {
  Natura: { Semente: 20, Bronze: 30, Prata: 30, Ouro: 32, Diamante: 35 },
  Avon: { Semente: 20, Bronze: 30, Prata: 35, Ouro: 38, Diamante: 40 },
  "Casa & Estilo": { Semente: 15, Bronze: 15, Prata: 15, Ouro: 15, Diamante: 20 },
};

export function getMarginPercent(brand: Brand | string, level: GrowthLevel): number {
  const normalized = brand in marginTable ? (brand as keyof typeof marginTable) : "Natura";
  return marginTable[normalized][level] ?? 20;
}

// Preço de venda = custo / (1 - margem)
export function calculateDynamicMargin(costPriceCents: number, userLevel: GrowthLevel, brand: Brand | string): number {
  const marginPct = getMarginPercent(brand, userLevel);
  const denom = 1 - marginPct / 100;
  if (denom <= 0) return costPriceCents;
  return Math.round(costPriceCents / denom);
}

