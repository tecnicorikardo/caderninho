import { test, expect } from "@playwright/test";
import { login, snap } from "./helpers";

test.describe("Dashboard", () => {
  test.beforeEach(async ({ page }) => { await login(page); });

  test("exibe os 4 cards principais", async ({ page }) => {
    await expect(page.locator("text=Faturamento do mês")).toBeVisible();
    await expect(page.locator("text=Lucro do mês")).toBeVisible();
    await expect(page.locator("text=Valor em estoque")).toBeVisible();
    await expect(page.locator("text=Clientes")).toBeVisible();
    await snap(page, "dashboard-cards");
  });

  test("exibe widget Saúde do Estoque com 3 cards de vencimento", async ({ page }) => {
    await expect(page.locator("text=Saúde do Estoque")).toBeVisible();
    await expect(page.locator("text=< 30 dias")).toBeVisible();
    await expect(page.locator("text=30–60 dias")).toBeVisible();
    await expect(page.locator("text=60–90 dias")).toBeVisible();
  });

  test("card de vencimento navega para estoque com filtro", async ({ page }) => {
    // Clica no card 60-90 dias (se tiver produtos)
    const card = page.locator("text=60–90 dias").first();
    const count = await card.locator("..").locator("..").locator("button").count();
    if (count > 0) {
      await page.locator("text=60–90 dias").locator("..").locator("..").click();
      await page.waitForURL("**/inventory**");
      await expect(page).toHaveURL(/expiry=90/);
    } else {
      test.skip(); // sem produtos nessa faixa
    }
  });
});
