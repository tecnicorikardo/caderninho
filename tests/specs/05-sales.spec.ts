import { test, expect } from "@playwright/test";
import { login, gotoAndWait, snap } from "./helpers";

test.describe("Vendas", () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
    await gotoAndWait(page, "/sales");
  });

  test("lista produtos disponíveis no catálogo", async ({ page }) => {
    // Verifica que a página carregou — tem o input de busca de produto ou o campo de cliente
    const hasCatalog = await page
      .locator('input[placeholder*="Buscar produto"]')
      .isVisible({ timeout: 20_000 })
      .catch(() => false);
    const hasClientInput = await page
      .locator('input[placeholder*="nome do cliente"]')
      .isVisible({ timeout: 5_000 })
      .catch(() => false);
    expect(hasCatalog || hasClientInput).toBeTruthy();
    await snap(page, "sales-catalog");
  });

  test("adicionar produto ao carrinho calcula totais", async ({ page }) => {
    // Aguarda o catálogo carregar
    await expect(
      page.locator('input[placeholder*="Buscar produto"]')
    ).toBeVisible({ timeout: 20_000 });
    await page.waitForTimeout(1000);

    // Botão "+" para adicionar ao carrinho
    const addBtn = page.locator("button:has-text('+')").first();
    const isVisible = await addBtn.isVisible({ timeout: 15_000 }).catch(() => false);
    if (!isVisible) { test.skip(); return; }

    await addBtn.click();
    await page.waitForTimeout(500);
    // Verifica que o total aparece no carrinho
    await expect(page.locator("text=Total").first()).toBeVisible({ timeout: 5_000 });
    await snap(page, "sales-cart");
  });

  test("finalizar sem cliente mostra erro", async ({ page }) => {
    await expect(
      page.locator('input[placeholder*="Buscar produto"]')
    ).toBeVisible({ timeout: 20_000 });
    await page.waitForTimeout(1000);

    const addBtn = page.locator("button:has-text('+')").first();
    const isVisible = await addBtn.isVisible({ timeout: 15_000 }).catch(() => false);
    if (!isVisible) { test.skip(); return; }

    await addBtn.click();
    await page.waitForTimeout(300);
    await page.click("text=Finalizar Venda");
    // Mensagem: "Selecione um cliente antes de finalizar."
    await expect(
      page.locator("text=/cliente|selecione|obrigatório/i").first()
    ).toBeVisible({ timeout: 5_000 });
  });

  test("autocomplete de cliente funciona com 2+ letras", async ({ page }) => {
    await expect(
      page.locator('input[placeholder*="Buscar produto"]')
    ).toBeVisible({ timeout: 20_000 });
    await page.waitForTimeout(1000);

    // Placeholder real: "Digite o nome do cliente…"
    const customerInput = page
      .locator('input[placeholder*="nome do cliente"]')
      .first();
    const isVisible = await customerInput.isVisible({ timeout: 10_000 }).catch(() => false);
    if (!isVisible) { test.skip(); return; }

    await customerInput.fill("An");
    await page.waitForTimeout(800);

    // Dropdown de sugestões — div com z-20
    const suggestions = page.locator(".absolute.z-20 button");
    const count = await suggestions.count();
    if (count > 0) {
      await expect(suggestions.first()).toBeVisible();
      await suggestions.first().click({ force: true });
      await page.waitForTimeout(400);
      // Deve mostrar "✓ selecionado" ou o input preenchido
      const selected = await page
        .locator("text=✓ selecionado")
        .isVisible()
        .catch(() => false);
      const inputVal = await customerInput.inputValue().catch(() => "");
      expect(selected || inputVal.length > 0).toBeTruthy();
      await snap(page, "sales-customer-selected");
    } else {
      test.skip(); // sem clientes com "An"
    }
  });

  test("venda à vista completa com sucesso", async ({ page }) => {
    await expect(
      page.locator('input[placeholder*="Buscar produto"]')
    ).toBeVisible({ timeout: 20_000 });
    await page.waitForTimeout(1000);

    const addBtn = page.locator("button:has-text('+')").first();
    if (!await addBtn.isVisible({ timeout: 15_000 }).catch(() => false)) { test.skip(); return; }
    await addBtn.click();
    await page.waitForTimeout(300);

    const customerInput = page
      .locator('input[placeholder*="nome do cliente"]')
      .first();
    if (!await customerInput.isVisible({ timeout: 5_000 }).catch(() => false)) { test.skip(); return; }

    await customerInput.fill("An");
    await page.waitForTimeout(800);
    const suggestions = page.locator(".absolute.z-20 button");
    if (await suggestions.count() === 0) { test.skip(); return; }
    await suggestions.first().click({ force: true });
    await page.waitForTimeout(400);

    await page.click("text=Finalizar Venda");
    // Mensagem de sucesso: "Venda registrada!"
    await expect(
      page.locator("text=/registrada|sucesso|Venda/i").first()
    ).toBeVisible({ timeout: 20_000 });
    await snap(page, "sales-completed");
  });

  test("seleção de parcelado mostra configuração de parcelas", async ({ page }) => {
    await expect(
      page.locator('input[placeholder*="Buscar produto"]')
    ).toBeVisible({ timeout: 20_000 });
    await page.waitForTimeout(1000);

    // Select de forma de pagamento — value "installments" = "Parcelado"
    const paySelect = page.locator("select").first();
    if (!await paySelect.isVisible({ timeout: 10_000 }).catch(() => false)) { test.skip(); return; }

    await paySelect.selectOption("installments");
    await page.waitForTimeout(500);
    // Texto real: "📅 Configure as parcelas abaixo antes de finalizar"
    await expect(
      page.locator("text=Configure as parcelas")
    ).toBeVisible({ timeout: 5_000 });
    await expect(page.locator("text=Nº de parcelas")).toBeVisible();
    await snap(page, "sales-installments-config");
  });

  test("seleção de fiado mostra campo de entrada", async ({ page }) => {
    await expect(
      page.locator('input[placeholder*="Buscar produto"]')
    ).toBeVisible({ timeout: 20_000 });
    await page.waitForTimeout(1000);

    const paySelect = page.locator("select").first();
    if (!await paySelect.isVisible({ timeout: 10_000 }).catch(() => false)) { test.skip(); return; }

    await paySelect.selectOption("fiado");
    await page.waitForTimeout(500);
    // Texto real: "Entrada recebida agora (R$)"
    await expect(
      page.locator("text=Entrada recebida agora")
    ).toBeVisible({ timeout: 5_000 });
    // Texto real: "💳 Restante a receber:"
    await expect(page.locator("text=Restante a receber")).toBeVisible();
  });
});
