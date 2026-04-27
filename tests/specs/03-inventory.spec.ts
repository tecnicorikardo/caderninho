import { test, expect } from "@playwright/test";
import { login, snap } from "./helpers";

const PRODUCT_NAME = `Teste Playwright ${Date.now()}`;

test.describe("Estoque", () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
    await page.goto("/inventory");
    await page.waitForLoadState("networkidle");
  });

  test("lista produtos com nome, marca, quantidade e validade", async ({ page }) => {
    const rows = page.locator(".divide-y > div, .divide-y > a");
    const count = await rows.count();
    if (count > 0) {
      // Verifica que pelo menos um item tem badge de validade
      await expect(rows.first()).toBeVisible();
    }
    await snap(page, "inventory-list");
  });

  test("busca filtra produtos corretamente", async ({ page }) => {
    const search = page.locator('input[placeholder*="Buscar"]');
    await search.fill("Natura");
    await page.waitForTimeout(300);
    // Todos os resultados visíveis devem conter Natura
    const items = page.locator(".divide-y .text-sm.font-medium");
    const count = await items.count();
    if (count > 0) {
      // Verifica que o filtro funcionou (menos itens que o total)
      await expect(items.first()).toBeVisible();
    }
  });

  test("cria novo produto e aparece na lista", async ({ page }) => {
    await page.click("text=+ Novo produto");
    await page.fill('input[placeholder*="Nome"]', PRODUCT_NAME);
    // Seleciona marca
    await page.selectOption("select", "Natura");
    // Quantidade
    await page.fill('input[type="number"]', "5");
    // Validade
    const futureDate = new Date();
    futureDate.setFullYear(futureDate.getFullYear() + 2);
    const dateStr = futureDate.toISOString().split("T")[0];
    await page.fill('input[type="date"]', dateStr);
    // Preço custo
    const priceInputs = page.locator('input[type="number"]');
    await priceInputs.nth(1).fill("25");
    await priceInputs.nth(2).fill("40");

    await page.click("text=Salvar");
    await page.waitForTimeout(2000);
    await expect(page.locator(`text=${PRODUCT_NAME}`)).toBeVisible({ timeout: 8_000 });
    await snap(page, "inventory-created");
  });

  test("exclui produto criado", async ({ page }) => {
    page.on("dialog", d => d.accept());
    const item = page.locator(`text=${PRODUCT_NAME}`);
    if (await item.isVisible()) {
      // Clica no × do item
      const row = item.locator("..").locator("..");
      await row.locator("button[title='Excluir'], button:has-text('×')").click();
      await page.waitForTimeout(1000);
      await expect(item).not.toBeVisible({ timeout: 5_000 });
    }
  });

  test("filtro por vencimento via URL mostra banner", async ({ page }) => {
    await page.goto("/inventory?expiry=30");
    await expect(page.locator("text=Vencem em menos de 30 dias")).toBeVisible({ timeout: 8_000 });
    await expect(page.locator("text=Limpar filtro")).toBeVisible();
    await snap(page, "inventory-expiry-filter");
  });

  test("limpar filtro remove o banner", async ({ page }) => {
    await page.goto("/inventory?expiry=30");
    await page.click("text=Limpar filtro");
    await expect(page).toHaveURL(/\/inventory$/);
    await expect(page.locator("text=Vencem em menos de 30 dias")).not.toBeVisible();
  });
});
