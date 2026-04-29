import { test, expect } from "@playwright/test";
import { login, gotoAndWait, snap } from "./helpers";

test.describe("Relatório Financeiro", () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
    await gotoAndWait(page, "/financial-report");
    // Aguarda o spinner "Calculando relatório…" sumir
    await page
      .waitForSelector("text=Calculando relatório", { state: "hidden", timeout: 30_000 })
      .catch(() => {});
    await page.waitForTimeout(500);
  });

  test("exibe os 4 cards de resumo", async ({ page }) => {
    await expect(page.locator("text=Receita Total")).toBeVisible({ timeout: 20_000 });
    await expect(page.locator("text=Custo Total")).toBeVisible({ timeout: 10_000 });
    await expect(page.locator("text=Lucro Bruto")).toBeVisible({ timeout: 10_000 });
    await expect(page.locator("text=Fluxo de Caixa")).toBeVisible({ timeout: 10_000 });
    await snap(page, "report-cards");
  });

  test("filtros de período funcionam", async ({ page }) => {
    await expect(page.locator("text=Receita Total")).toBeVisible({ timeout: 20_000 });

    // Clica em "Trimestre"
    await page.click("button:has-text('Trimestre')");
    await page
      .waitForSelector("text=Calculando relatório", { state: "hidden", timeout: 20_000 })
      .catch(() => {});
    await expect(page.locator("text=Receita Total")).toBeVisible({ timeout: 15_000 });

    // Clica em "Tudo"
    await page.click("button:has-text('Tudo')");
    await page
      .waitForSelector("text=Calculando relatório", { state: "hidden", timeout: 20_000 })
      .catch(() => {});
    await expect(page.locator("text=Receita Total")).toBeVisible({ timeout: 15_000 });
    await snap(page, "report-period-filter");
  });

  test("seção de análise de rentabilidade aparece", async ({ page }) => {
    await expect(page.locator("text=Análise de Rentabilidade")).toBeVisible({ timeout: 20_000 });
    await expect(page.locator("text=Margem de Lucro")).toBeVisible({ timeout: 10_000 });
    await expect(page.locator("text=Ticket Médio")).toBeVisible({ timeout: 10_000 });
  });
});
