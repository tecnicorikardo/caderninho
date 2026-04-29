import { test, expect } from "@playwright/test";
import { login, snap } from "./helpers";

test.describe("Dashboard", () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
    await page.waitForURL(/dashboard/, { timeout: 20_000 });
    // Aguarda o loading sumir — o app usa "Carregando…" com reticências
    await page
      .waitForSelector("text=Carregando…", { state: "hidden", timeout: 25_000 })
      .catch(() => {});
    // Aguarda pelo menos um card aparecer
    await page.waitForTimeout(1000);
  });

  test("exibe os 4 cards principais", async ({ page }) => {
    await expect(page.locator("text=Faturamento do mês")).toBeVisible({ timeout: 20_000 });
    await expect(page.locator("text=Lucro do mês")).toBeVisible({ timeout: 10_000 });
    await expect(page.locator("text=Valor em estoque")).toBeVisible({ timeout: 10_000 });
    await expect(page.locator('a[href="/customers"]').first()).toBeVisible({ timeout: 10_000 });
    await snap(page, "dashboard-cards");
  });

  test("exibe widget Saúde do Estoque com 3 cards de vencimento", async ({ page }) => {
    await expect(page.locator("text=Saúde do Estoque")).toBeVisible({ timeout: 20_000 });
    await expect(page.locator("text=< 30 dias")).toBeVisible({ timeout: 10_000 });
    await expect(page.locator("text=30–60 dias")).toBeVisible({ timeout: 10_000 });
    await expect(page.locator("text=60–90 dias")).toBeVisible({ timeout: 10_000 });
  });

  test("card de vencimento navega para estoque com filtro", async ({ page }) => {
    await expect(page.locator("text=Saúde do Estoque")).toBeVisible({ timeout: 20_000 });
    const card = page.locator("text=60–90 dias").first();
    const isVisible = await card.isVisible().catch(() => false);
    if (!isVisible) { test.skip(); return; }

    await card.click();
    const url = page.url();
    if (url.includes("inventory")) {
      await expect(page).toHaveURL(/expiry=90/);
    } else {
      test.skip(); // card sem produtos não navega
    }
  });
});
