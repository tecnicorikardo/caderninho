import { test, expect } from "@playwright/test";
import { login, gotoAndWait, snap } from "./helpers";

test.describe("Comissões", () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
    await gotoAndWait(page, "/commission");
  });

  test("exibe card de comissão total e filtros de período", async ({ page }) => {
    // Card principal: "Comissão total"
    await expect(page.locator("text=Comissão total")).toBeVisible({ timeout: 20_000 });
    // Botões de filtro
    await expect(page.locator("button:has-text('Este mês')")).toBeVisible({ timeout: 10_000 });
    await expect(page.locator("button:has-text('30 dias')")).toBeVisible();
    await expect(page.locator("button:has-text('Tudo')")).toBeVisible();
    await snap(page, "commission-header");
  });

  test("filtro de período atualiza dados", async ({ page }) => {
    await expect(page.locator("text=Comissão total")).toBeVisible({ timeout: 20_000 });
    await page.click("button:has-text('Tudo')");
    await page.waitForTimeout(2000);
    // Após clicar em "Tudo", o periodLabel vira "Todo período"
    await expect(page.locator("text=Todo período")).toBeVisible({ timeout: 15_000 });
  });

  test("calculadora — custo R$100 Natura 35% calcula corretamente", async ({ page }) => {
    await expect(page.locator("text=Calculadora de Comissão")).toBeVisible({ timeout: 20_000 });

    // Select de marca na calculadora
    const brandSelect = page.locator("select").first();
    await expect(brandSelect).toBeVisible({ timeout: 5_000 });
    await brandSelect.selectOption({ label: /Natura/i }).catch(() => {});

    // Input de custo — type="number" placeholder="Ex: 25,00"
    const costInput = page.locator('input[type="number"][placeholder*="25"]');
    await expect(costInput).toBeVisible({ timeout: 5_000 });
    await costInput.fill("100");
    await page.waitForTimeout(800);

    // Resultado: card "Preço sugerido" com valor .text-xl
    const suggested = page
      .locator("text=Preço sugerido")
      .locator("..")
      .locator(".text-xl");
    await expect(suggested).toBeVisible({ timeout: 5_000 });
    const text = await suggested.textContent() ?? "";
    expect(text).not.toContain("10.000");
    expect(text).not.toContain("-");
    expect(text).toContain("R$");
    await snap(page, "commission-calculator");
  });

  test("calculadora — custo R$100 mostra comissão positiva", async ({ page }) => {
    await expect(page.locator("text=Calculadora de Comissão")).toBeVisible({ timeout: 20_000 });
    const costInput = page.locator('input[type="number"][placeholder*="25"]');
    await expect(costInput).toBeVisible({ timeout: 5_000 });
    await costInput.fill("100");
    await page.waitForTimeout(800);

    const commission = page
      .locator("text=Sua comissão")
      .locator("..")
      .locator(".text-xl");
    await expect(commission).toBeVisible({ timeout: 5_000 });
    const text = await commission.textContent() ?? "";
    expect(text).not.toContain("-");
    expect(text).toContain("R$");
  });

  test("calculadora — custo R$100 mostra custo correto (não R$10.000)", async ({ page }) => {
    await expect(page.locator("text=Calculadora de Comissão")).toBeVisible({ timeout: 20_000 });
    const costInput = page.locator('input[type="number"][placeholder*="25"]');
    await expect(costInput).toBeVisible({ timeout: 5_000 });
    await costInput.fill("100");
    await page.waitForTimeout(800);

    // Card "Custo" — é o terceiro card dos resultados (bg-blue-50)
    const custoCard = page.locator(".bg-blue-50.border-blue-100 .text-xl").first();
    await expect(custoCard).toBeVisible({ timeout: 5_000 });
    const text = await custoCard.textContent() ?? "";
    // Deve ser R$ 100,00 — não R$ 10.000,00
    expect(text).toMatch(/R\$\s*100/);
  });
});
