import { test, expect } from "@playwright/test";
import { login, snap } from "./helpers";

test.describe("Recebimentos", () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
    await page.goto("/receivables");
    await page.waitForLoadState("networkidle");
  });

  test("exibe cards de resumo", async ({ page }) => {
    await expect(page.locator("text=Total a receber")).toBeVisible();
    await expect(page.locator("text=Em atraso")).toBeVisible();
    await snap(page, "receivables-summary");
  });

  test("lista clientes com saldo", async ({ page }) => {
    const list = page.locator(".divide-y button");
    const count = await list.count();
    if (count === 0) {
      test.skip(); // sem recebíveis cadastrados
    }
    await expect(list.first()).toBeVisible();
  });

  test("modal abre ao clicar no cliente", async ({ page }) => {
    const clientBtn = page.locator(".divide-y button").first();
    if (!await clientBtn.isVisible()) { test.skip(); }

    await clientBtn.click();
    await page.waitForTimeout(500);
    // Modal deve aparecer com os 4 botões
    await expect(page.locator("text=Pagar selecionadas")).toBeVisible();
    await expect(page.locator("text=Pagar tudo")).toBeVisible();
    await expect(page.locator("text=Pagamento parcial")).toBeVisible();
    await expect(page.locator("text=Mudar prazo")).toBeVisible();
    await snap(page, "receivables-modal");
  });

  test("pagar selecionadas — seleciona parcela e confirma valor correto", async ({ page }) => {
    const clientBtn = page.locator(".divide-y button").first();
    if (!await clientBtn.isVisible()) { test.skip(); }
    await clientBtn.click();
    await page.waitForTimeout(500);

    // Seleciona primeira parcela
    const checkbox = page.locator('input[type="checkbox"]').first();
    if (!await checkbox.isVisible()) { test.skip(); }
    await checkbox.check();
    await page.waitForTimeout(300);

    // Verifica que o total aparece no resumo
    await expect(page.locator("text=/parcela.*selecionada/i")).toBeVisible();

    // Clica em pagar selecionadas
    await page.click("text=Pagar selecionadas");
    await page.waitForTimeout(300);

    // Verifica que o botão de confirmar mostra o valor (não negativo)
    const confirmBtn = page.locator("button:has-text('Confirmar')");
    const btnText = await confirmBtn.textContent();
    expect(btnText).not.toContain("-");
    expect(btnText).toMatch(/R\$/);
    await snap(page, "receivables-pay-selected");
  });

  test("pagamento parcial — mostra total da dívida e reparcelamento", async ({ page }) => {
    const clientBtn = page.locator(".divide-y button").first();
    if (!await clientBtn.isVisible()) { test.skip(); }
    await clientBtn.click();
    await page.waitForTimeout(500);

    await page.click("text=Pagamento parcial");
    await page.waitForTimeout(300);

    // Deve mostrar total da dívida
    await expect(page.locator("text=Total da dívida")).toBeVisible();

    // Digita um valor parcial
    const input = page.locator('input[inputmode="decimal"]');
    await input.fill("10");
    await page.waitForTimeout(500);

    // Deve aparecer resumo e configurador de reparcelamento
    await expect(page.locator("text=Recebendo agora")).toBeVisible();
    await expect(page.locator("text=Restante a reparcelar")).toBeVisible();
    await expect(page.locator("text=Como parcelar")).toBeVisible();
    await expect(page.locator("text=Nº de parcelas")).toBeVisible();

    // Verifica que o botão confirmar NÃO tem valor negativo
    const confirmBtn = page.locator("button:has-text('Confirmar')");
    const btnText = await confirmBtn.textContent() ?? "";
    expect(btnText).not.toContain("-");
    await snap(page, "receivables-partial");
  });

  test("mudar prazo — mostra seletor de data", async ({ page }) => {
    const clientBtn = page.locator(".divide-y button").first();
    if (!await clientBtn.isVisible()) { test.skip(); }
    await clientBtn.click();
    await page.waitForTimeout(500);

    await page.click("text=Mudar prazo");
    await page.waitForTimeout(300);
    await expect(page.locator("text=Qual parcela quer reagendar")).toBeVisible();
    await snap(page, "receivables-change-date");
  });
});
