import { describe, it, expect } from "vitest";
import { calculateBrandCommissionCents, calculateItemEarnings, calculateSaleEarnings } from "./profit";
import type { SaleItem, BrandMargin } from "./types";

describe("profit.ts - calculateBrandCommissionCents", () => {
  it("calcula comissao de 10% corretamente", () => {
    expect(calculateBrandCommissionCents(10000, 10)).toBe(1000);
  });

  it("calcula comissao de 30% corretamente", () => {
    expect(calculateBrandCommissionCents(6429, 30)).toBe(1929);
  });

  it("calcula comissao de 0% corretamente", () => {
    expect(calculateBrandCommissionCents(10000, 0)).toBe(0);
  });

  it("calcula comissao de 50% corretamente", () => {
    expect(calculateBrandCommissionCents(10000, 50)).toBe(5000);
  });

  it("retorna 0 para receita 0", () => {
    expect(calculateBrandCommissionCents(0, 30)).toBe(0);
  });
});

describe("profit.ts - calculateItemEarnings", () => {
  const mockBrandMargins: BrandMargin[] = [
    { brand: "Natura", marginPercent: 30 },
    { brand: "Avon", marginPercent: 25 },
  ];

  it("calcula lucro de um item corretamente", () => {
    const item: SaleItem = {
      productId: "prod1",
      productName: "Produto Teste",
      brand: "Natura",
      quantity: 2,
      unitPriceCents: 6429,  // R$ 64,29
      unitCostCents: 4500,   // R$ 45,00
    };

    const result = calculateItemEarnings(item, mockBrandMargins);

    // 2 unidades:
    // Receita: 2 * 6429 = 12858 centavos
    // Custo: 2 * 4500 = 9000 centavos
    // Lucro: 12858 - 9000 = 3858 centavos
    expect(result.revenueCents).toBe(12858);
    expect(result.costCents).toBe(9000);
    expect(result.grossProfitCents).toBe(3858);
    expect(result.commissionCents).toBe(3858); // comissao = lucro bruto
    expect(result.profitCents).toBe(3858);
  });

  it("calcula lucro zero quando preco = custo", () => {
    const item: SaleItem = {
      productId: "prod2",
      productName: "Produto Sem Lucro",
      brand: "Avon",
      quantity: 1,
      unitPriceCents: 5000,
      unitCostCents: 5000,
    };

    const result = calculateItemEarnings(item, mockBrandMargins);

    expect(result.revenueCents).toBe(5000);
    expect(result.costCents).toBe(5000);
    expect(result.grossProfitCents).toBe(0);
    expect(result.commissionCents).toBe(0);
    expect(result.profitCents).toBe(0);
  });

  it("calcula prejuizo quando preco < custo", () => {
    const item: SaleItem = {
      productId: "prod3",
      productName: "Produto com Prejuizo",
      brand: "Natura",
      quantity: 1,
      unitPriceCents: 4000,
      unitCostCents: 5000,
    };

    const result = calculateItemEarnings(item, mockBrandMargins);

    expect(result.revenueCents).toBe(4000);
    expect(result.costCents).toBe(5000);
    expect(result.grossProfitCents).toBe(-1000); // Prejuizo
    expect(result.commissionCents).toBe(-1000);
    expect(result.profitCents).toBe(-1000);
  });

  it("retorna 0 para item sem preco ou quantidade", () => {
    const item: SaleItem = {
      productId: "prod4",
      productName: "Produto Incompleto",
      brand: "Natura",
      quantity: 0,
      unitPriceCents: 6429,
      unitCostCents: 4500,
    };

    const result = calculateItemEarnings(item, mockBrandMargins);

    expect(result.revenueCents).toBe(0);
    expect(result.costCents).toBe(0);
    expect(result.grossProfitCents).toBe(0);
  });
});

describe("profit.ts - calculateSaleEarnings", () => {
  const mockBrandMargins: BrandMargin[] = [
    { brand: "Natura", marginPercent: 30 },
    { brand: "Avon", marginPercent: 25 },
  ];

  it("calcula lucro total de multiplos itens", () => {
    const items: SaleItem[] = [
      {
        productId: "prod1",
        productName: "Produto 1",
        brand: "Natura",
        quantity: 2,
        unitPriceCents: 6429,
        unitCostCents: 4500,
      },
      {
        productId: "prod2",
        productName: "Produto 2",
        brand: "Avon",
        quantity: 1,
        unitPriceCents: 8000,
        unitCostCents: 6000,
      },
    ];

    const result = calculateSaleEarnings(items, mockBrandMargins);

    // Item 1: receita = 12858, custo = 9000, lucro = 3858
    // Item 2: receita = 8000, custo = 6000, lucro = 2000
    // Total: receita = 20858, custo = 15000, lucro = 5858
    expect(result.revenueCents).toBe(20858);
    expect(result.costCents).toBe(15000);
    expect(result.grossProfitCents).toBe(5858);
    expect(result.commissionCents).toBe(5858);
    expect(result.profitCents).toBe(5858);
  });

  it("retorna 0 para array vazio", () => {
    const result = calculateSaleEarnings([], mockBrandMargins);

    expect(result.revenueCents).toBe(0);
    expect(result.costCents).toBe(0);
    expect(result.grossProfitCents).toBe(0);
    expect(result.commissionCents).toBe(0);
    expect(result.profitCents).toBe(0);
  });

  it("acumula corretamente itens com lucro e prejuizo", () => {
    const items: SaleItem[] = [
      {
        productId: "prod1",
        productName: "Produto com Lucro",
        brand: "Natura",
        quantity: 1,
        unitPriceCents: 10000,
        unitCostCents: 7000,
      },
      {
        productId: "prod2",
        productName: "Produto com Prejuizo",
        brand: "Avon",
        quantity: 1,
        unitPriceCents: 5000,
        unitCostCents: 6000,
      },
    ];

    const result = calculateSaleEarnings(items, mockBrandMargins);

    // Item 1: lucro = 3000
    // Item 2: prejuizo = -1000
    // Total: lucro liquido = 2000
    expect(result.revenueCents).toBe(15000);
    expect(result.costCents).toBe(13000);
    expect(result.grossProfitCents).toBe(2000);
    expect(result.commissionCents).toBe(2000);
    expect(result.profitCents).toBe(2000);
  });
});
