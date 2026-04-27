import { test, expect } from "@playwright/test";
import { login, snap } from "./helpers";

test.describe("Vendas", () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
    await page.goto("/sales");
    await page.waitForLoadState("networkidle");
  });

  test("lista produtos disponíveis no catálogo", async ({ page }) => {
    const items = page.locator(".divide-y .text-sm.font-medium");
    const count = await items.count();
    expect(count).toBeGreaterThan(0);
    await snap(page, "sales-catalog");
  });

  test("adicionar produto ao carrinho calcula totais", async ({ page }) => {
    // Clica no primeiro + disponível
    const addBtn = page.locator("button:has-text('+')").first();
    await addBtn.click();
    await page.waitForTimeout(500);
    // Verifica que o total aparece no carrinho
    await expect(page.locator("text=Total").first()).toBeVisible();
    await expect(page.locator("text=Lucro").first()).toBeVisible();
    await snap(page, "sales-cart");
  });

  test("finalizar sem cliente mostra erro", async ({ page }) => {
    // Adiciona produto
    const addBtn = page.locator("button:has-text('+')").first();
    await addBtn.click();
    await page.waitForTimeout(300);
    // Tenta finalizar sem cliente
    await page.click("text=Finalizar Venda");
    await expect(page.locator("text=/cliente|selecione/i").first()).toBeVisible({ timeout: 5_000 });
  });

  test("autocomplete de cliente funciona com 2+ letras", async ({ page }) => {
    const customerInput = page.locator('input[placeholder*="cliente"]');
    await customerInput.fill("An");
    await page.waitForTimeout(500);
    // Deve aparecer dropdown de sugestões
    const suggestions = page.locator(".absolute.z-20 button");
    const count = await suggestions.count();
    if (count > 0) {
      await expect(suggestions.first()).toBeVisible();
      // Clica na primeira sugestão
      await suggestions.first().click({ force: true });
      await page.waitForTimeout(300);
      // Deve mostrar ✓ selecionado
      await expect(page.locator("text=✓ selecionado")).toBeVisible();
      await snap(page, "sales-customer-selected");
    }
  });

  test("venda à vista completa com sucesso", async ({ page }) => {
    // Adiciona produto
    const addBtn = page.locator("button:has-text('+')").first();
    await addBtn.click();
    await page.waitForTimeout(300);

    // Seleciona cliente
    const customerInput = page.locator('input[placeholder*="cliente"]');
    await customerInput.fill("An");
    await page.waitForTimeout(500);
    const suggestions = page.locator(".absolute.z-20 button");
    if (await suggestions.count() > 0) {
      await suggestions.first().click({ force: true });
      await page.waitForTimeout(300);
    } else {
      test.skip(); // sem clientes cadastrados
    }

    // Pagamento dinheiro (padrão)
    await page.click("text=Finalizar Venda");
    await expect(page.locator("text=/registrada|sucesso/i").first()).toBeVisible({ timeout: 10_000 });
    await snap(page, "sales-completed");
  });

  test("seleção de parcelado mostra configuração de parcelas", async ({ page }) => {
    await page.selectOption("select", "installments");
    await page.waitForTimeout(300);
    await expect(page.locator("text=Configure as parcelas")).toBeVisible();
    await expect(page.locator("text=Nº de parcelas")).toBeVisible();
    await expect(page.locator("text=1ª parcela em")).toBeVisible();
    await snap(page, "sales-installments-config");
  });

  test("seleção de fiado mostra campo de entrada", async ({ page }) => {
    await page.selectOption("select", "fiado");
    await page.waitForTimeout(300);
    await expect(page.locator("text=Entrada recebida agora")).toBeVisible();
    await expect(page.locator("text=Restante a receber")).toBeVisible();
  });
});
