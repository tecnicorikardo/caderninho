import { test, expect } from "@playwright/test";
import { login, snap } from "./helpers";

test.describe("Relatório Financeiro", () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
    await page.goto("/financial-report");
    await page.waitForLoadState("networkidle");
  });

  test("exibe os 4 cards de resumo", async ({ page }) => {
    await expect(page.locator("text=Receita Total")).toBeVisible();
    await expect(page.locator("text=Custo Total")).toBeVisible();
    await expect(page.locator("text=Lucro Bruto")).toBeVisible();
    await expect(page.locator("text=Fluxo de Caixa")).toBeVisible();
    await snap(page, "report-cards");
  });

  test("filtros de período funcionam", async ({ page }) => {
    await page.click("text=Trimestre");
    await page.waitForTimeout(1000);
    await expect(page.locator("text=Receita Total")).toBeVisible();

    await page.click("text=Tudo");
    await page.waitForTimeout(1000);
    await expect(page.locator("text=Receita Total")).toBeVisible();
    await snap(page, "report-period-filter");
  });

  test("seção de análise de rentabilidade aparece", async ({ page }) => {
    await expect(page.locator("text=Análise de Rentabilidade")).toBeVisible();
    await expect(page.locator("text=Margem de Lucro")).toBeVisible();
    await expect(page.locator("text=Ticket Médio")).toBeVisible();
  });
});
