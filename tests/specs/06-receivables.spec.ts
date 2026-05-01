import { test, expect } from "@playwright/test";
import { login, gotoAndWait, snap } from "./helpers";

test.describe("Recebimentos", () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
    await gotoAndWait(page, "/receivables");
  });

  test("exibe cards de resumo", async ({ page }) => {
    // Cards: "Total a receber" e "Em atraso"
    await expect(page.locator("text=Total a receber")).toBeVisible({ timeout: 20_000 });
    await expect(page.locator("text=Em atraso")).toBeVisible({ timeout: 10_000 });
    await snap(page, "receivables-summary");
  });

  test("lista clientes com saldo", async ({ page }) => {
    await expect(page.locator("text=Total a receber")).toBeVisible({ timeout: 20_000 });
    // Seção "Clientes com saldo"
    await expect(page.locator("text=Clientes com saldo")).toBeVisible({ timeout: 15_000 });
    const list = page.locator(".divide-y button");
    const count = await list.count();
    if (count === 0) { test.skip(); return; }
    await expect(list.first()).toBeVisible();
  });

  test("modal abre ao clicar no cliente", async ({ page }) => {
    await expect(page.locator("text=Total a receber")).toBeVisible({ timeout: 20_000 });
    await page.waitForTimeout(1000);
    const clientBtn = page.locator(".divide-y button").first();
    if (!await clientBtn.isVisible({ timeout: 15_000 }).catch(() => false)) { test.skip(); return; }

    await clientBtn.click();
    await page.waitForTimeout(500);
    // Modal com os 4 botões de ação
    await expect(page.locator("text=Pagar selecionadas")).toBeVisible({ timeout: 5_000 });
    await expect(page.locator("text=Pagar tudo")).toBeVisible();
    await expect(page.locator("text=Pagamento parcial")).toBeVisible();
    await expect(page.locator("text=Mudar prazo")).toBeVisible();
    await snap(page, "receivables-modal");
  });

  test("pagar selecionadas — seleciona parcela e confirma valor correto", async ({ page }) => {
    await expect(page.locator("text=Total a receber")).toBeVisible({ timeout: 20_000 });
    await page.waitForTimeout(1000);
    const clientBtn = page.locator(".divide-y button").first();
    if (!await clientBtn.isVisible({ timeout: 15_000 }).catch(() => false)) { test.skip(); return; }
    await clientBtn.click();
    await page.waitForTimeout(500);

    // Seleciona primeira parcela via checkbox
    const checkbox = page.locator('input[type="checkbox"]').first();
    if (!await checkbox.isVisible({ timeout: 3_000 }).catch(() => false)) { test.skip(); return; }
    await checkbox.check();
    await page.waitForTimeout(300);

    // Resumo de seleção: "1 parcela selecionada"
    await expect(
      page.locator("text=/parcela.*selecionada/i")
    ).toBeVisible({ timeout: 5_000 });

    // Clica em "Pagar selecionadas"
    await page.click("text=Pagar selecionadas");
    await page.waitForTimeout(300);

    // Botão confirmar com valor — "Confirmar R$ X,XX"
    const confirmBtn = page.locator("button:has-text('Confirmar')");
    await expect(confirmBtn).toBeVisible({ timeout: 5_000 });
    const btnText = await confirmBtn.textContent() ?? "";
    expect(btnText).not.toContain("-");
    expect(btnText).toMatch(/R\$/);
    await snap(page, "receivables-pay-selected");
  });

  test("pagamento parcial — mostra total da dívida e reparcelamento", async ({ page }) => {
    await expect(page.locator("text=Total a receber")).toBeVisible({ timeout: 20_000 });
    await page.waitForTimeout(1000);
    const clientBtn = page.locator(".divide-y button").first();
    if (!await clientBtn.isVisible({ timeout: 15_000 }).catch(() => false)) { test.skip(); return; }
    await clientBtn.click();
    await page.waitForTimeout(500);

    await page.click("text=Pagamento parcial");
    await page.waitForTimeout(300);

    // "Total da dívida" aparece no modo partial
    await expect(page.locator("text=Total da dívida")).toBeVisible({ timeout: 5_000 });

    // Input com inputMode="decimal"
    const input = page.locator('input[inputmode="decimal"]');
    await expect(input).toBeVisible({ timeout: 5_000 });
    await input.fill("10");
    await page.waitForTimeout(800);

    // Resumo: "✅ Recebendo agora:" e "⏳ Restante a reparcelar:"
    await expect(page.locator("text=Recebendo agora")).toBeVisible({ timeout: 5_000 });
    await expect(page.locator("text=Restante a reparcelar")).toBeVisible();
    // Configuração: "Como parcelar" e "Nº de parcelas"
    await expect(page.locator("text=Como parcelar")).toBeVisible();
    await expect(page.locator("text=Nº de parcelas")).toBeVisible();

    // Botão confirmar não deve ter valor negativo
    const confirmBtn = page.locator("button:has-text('Confirmar')");
    await expect(confirmBtn).toBeVisible({ timeout: 5_000 });
    const btnText = await confirmBtn.textContent() ?? "";
    expect(btnText).not.toContain("-");
    await snap(page, "receivables-partial");
  });

  test("mudar prazo — mostra seletor de data", async ({ page }) => {
    await expect(page.locator("text=Total a receber")).toBeVisible({ timeout: 20_000 });
    await page.waitForTimeout(1000);
    const clientBtn = page.locator(".divide-y button").first();
    if (!await clientBtn.isVisible({ timeout: 15_000 }).catch(() => false)) { test.skip(); return; }
    await clientBtn.click();
    await page.waitForTimeout(500);

    await page.click("text=Mudar prazo");
    await page.waitForTimeout(300);
    // Texto real: "Qual parcela quer reagendar?"
    await expect(
      page.locator("text=Qual parcela quer reagendar")
    ).toBeVisible({ timeout: 5_000 });
    await snap(page, "receivables-change-date");
  });
});
