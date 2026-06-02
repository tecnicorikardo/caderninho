import { getConfiguredMargin } from "@/lib/margins";
import type { BrandMargin, SaleItem } from "@/lib/types";

export type EarningsBreakdown = {
  revenueCents: number;
  costCents: number;
  grossProfitCents: number;
  commissionCents: number;
  profitCents: number;
};

export function calculateBrandCommissionCents(revenueCents: number, marginPct: number) {
  return Math.round(revenueCents * (marginPct / 100));
}

export function calculateItemEarnings(item: SaleItem, brandMargins: BrandMargin[]): EarningsBreakdown {
  const revenueCents = (item.unitPriceCents ?? 0) * (item.quantity ?? 0);
  const costCents = (item.unitCostCents ?? 0) * (item.quantity ?? 0);
  const grossProfitCents = revenueCents - costCents;
  const commissionPct = getConfiguredMargin(item.brand || "Outra", brandMargins);
  const commissionCents = calculateBrandCommissionCents(revenueCents, commissionPct);

  return {
    revenueCents,
    costCents,
    grossProfitCents,
    commissionCents,
    profitCents: grossProfitCents + commissionCents,
  };
}

export function calculateSaleEarnings(items: SaleItem[], brandMargins: BrandMargin[]): EarningsBreakdown {
  return items.reduce<EarningsBreakdown>((totals, item) => {
    const itemEarnings = calculateItemEarnings(item, brandMargins);
    return {
      revenueCents: totals.revenueCents + itemEarnings.revenueCents,
      costCents: totals.costCents + itemEarnings.costCents,
      grossProfitCents: totals.grossProfitCents + itemEarnings.grossProfitCents,
      commissionCents: totals.commissionCents + itemEarnings.commissionCents,
      profitCents: totals.profitCents + itemEarnings.profitCents,
    };
  }, {
    revenueCents: 0,
    costCents: 0,
    grossProfitCents: 0,
    commissionCents: 0,
    profitCents: 0,
  });
}
