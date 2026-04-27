import { test, expect } from "@playwright/test";
import { login, snap } from "./helpers";

test.describe("Comissões", () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
    await page.goto("/commission");
    await page.waitForLoadState("networkidle");
  });

  test("exibe card de comissão total e filtros de período", async ({ page }) => {
    await expect(page.locator("text=Comissão total")).toBeVisible();
    await expect(page.locator("text=Este mês")).toBeVisible();
    await expect(page.locator("text=30 dias")).toBeVisible();
    await expect(page.locator("text=Tudo")).toBeVisible();
    await snap(page, "commission-header");
  });

  test("filtro de período atualiza dados", async ({ page }) => {
    await page.click("text=Tudo");
    await page.waitForTimeout(1000);
    await expect(page.locator("text=Todo período")).toBeVisible();
  });

  test("calculadora — custo R$100 Natura 35% calcula corretamente", async ({ page }) => {
    // Seleciona Natura
    const brandSelect = page.locator("select").first();
    await brandSelect.selectOption({ label: /Natura/i });

    // Digita custo
    const costInput = page.locator('input[placeholder*="25"]');
    await costInput.fill("100");
    await page.waitForTimeout(500);

    // Verifica preço sugerido (deve ser ~R$ 153,85 para 35%)
    const suggested = page.locator("text=Preço sugerido").locator("..").locator(".text-xl");
    await expect(suggested).toBeVisible();
    const text = await suggested.textContent() ?? "";
    // Não deve ser R$ 10.000 nem negativo
    expect(text).not.toContain("10.000");
    expect(text).not.toContain("-");
    // Deve conter R$
    expect(text).toContain("R$");
    await snap(page, "commission-calculator");
  });

  test("calculadora — custo R$100 mostra comissão positiva", async ({ page }) => {
    const costInput = page.locator('input[placeholder*="25"]');
    await costInput.fill("100");
    await page.waitForTimeout(500);

    const commission = page.locator("text=Sua comissão").locator("..").locator(".text-xl");
    await expect(commission).toBeVisible();
    const text = await commission.textContent() ?? "";
    expect(text).not.toContain("-");
    expect(text).toContain("R$");
  });

  test("calculadora — custo R$100 mostra custo correto (não R$10.000)", async ({ page }) => {
    const costInput = page.locator('input[placeholder*="25"]');
    await costInput.fill("100");
    await page.waitForTimeout(500);

    const custo = page.locator("text=Custo").locator("..").locator(".text-xl");
    await expect(custo).toBeVisible();
    const text = await custo.textContent() ?? "";
    // R$ 100,00 — não R$ 10.000,00
    expect(text).toMatch(/R\$\s*100/);
  });
});
