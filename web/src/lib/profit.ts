/**
 * profit.ts — Calculo de lucro e comissao para revendedoras
 *
 * LOGICA DE NEGOCIO:
 * A revendedora compra produtos da marca a um preco de custo
 * e vende ao cliente a um preco maior. O lucro dela e a diferenca.
 *
 * Exemplo Natura com 30% de margem:
 *   Custo: R$ 45,00
 *   Preco sugerido de venda: R$ 64,29 (custo / (1 - 0.30))
 *   Lucro (comissao): R$ 19,29 (30% do preco de venda)
 *
 * O campo "comissao" = lucro bruto = preco de venda - custo
 * Nao ha comissao adicional da marca — o lucro JA E a comissao.
 */

import { getConfiguredMargin } from "@/lib/margins";
import type { BrandMargin, SaleItem } from "@/lib/types";

export type EarningsBreakdown = {
  revenueCents: number;
  costCents: number;
  grossProfitCents: number;   // venda - custo = lucro = comissao
  commissionCents: number;    // alias de grossProfitCents (para compatibilidade)
  profitCents: number;        // igual a grossProfitCents
};

/**
 * Calcula a comissao esperada sobre uma receita com base na margem configurada.
 * comissao = receita * marginPct / 100
 * Usado apenas para exibir o percentual esperado, nao para calculo real do lucro.
 */
export function calculateBrandCommissionCents(revenueCents: number, marginPct: number): number {
  return Math.round(revenueCents * (marginPct / 100));
}

/**
 * Calcula o lucro real de um item:
 * lucro = (preco de venda - custo) * quantidade
 */
export function calculateItemEarnings(item: SaleItem, brandMargins: BrandMargin[]): EarningsBreakdown {
  const revenueCents     = (item.unitPriceCents ?? 0) * (item.quantity ?? 0);
  const costCents        = (item.unitCostCents ?? 0)  * (item.quantity ?? 0);
  const grossProfitCents = revenueCents - costCents;   // lucro real = comissao real

  return {
    revenueCents,
    costCents,
    grossProfitCents,
    commissionCents: grossProfitCents,  // comissao = lucro bruto
    profitCents: grossProfitCents,
  };
}

export function calculateSaleEarnings(items: SaleItem[], brandMargins: BrandMargin[]): EarningsBreakdown {
  return items.reduce<EarningsBreakdown>((totals, item) => {
    const e = calculateItemEarnings(item, brandMargins);
    return {
      revenueCents:     totals.revenueCents     + e.revenueCents,
      costCents:        totals.costCents        + e.costCents,
      grossProfitCents: totals.grossProfitCents + e.grossProfitCents,
      commissionCents:  totals.commissionCents  + e.commissionCents,
      profitCents:      totals.profitCents      + e.profitCents,
    };
  }, { revenueCents: 0, costCents: 0, grossProfitCents: 0, commissionCents: 0, profitCents: 0 });
}
