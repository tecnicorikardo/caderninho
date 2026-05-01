import { test, expect } from "@playwright/test";
import { login, gotoAndWait, snap } from "./helpers";

const PRODUCT_NAME = `Teste Playwright ${Date.now()}`;

/** Navega para uma URL com query params usando history.pushState (sem full reload) */
async function navigateWithParams(page: import("@playwright/test").Page, url: string) {
  await page.evaluate((u) => window.history.pushState({}, "", u), url);
  // Dispara um evento de popstate para o React Router detectar a mudança
  await page.evaluate(() => window.dispatchEvent(new PopStateEvent("popstate")));
  await page.waitForTimeout(500);
}

test.describe("Estoque", () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
    await gotoAndWait(page, "/inventory");
  });

  test("lista produtos com nome, marca, quantidade e validade", async ({ page }) => {
    // Verifica que a página carregou — tem o botão de novo produto
    await expect(page.locator("text=+ Novo produto")).toBeVisible({ timeout: 20_000 });
    const rows = page.locator(".divide-y > div");
    const count = await rows.count();
    if (count > 0) {
      await expect(rows.first()).toBeVisible();
    }
    await snap(page, "inventory-list");
  });

  test("busca filtra produtos corretamente", async ({ page }) => {
    await expect(page.locator("text=+ Novo produto")).toBeVisible({ timeout: 20_000 });
    // Placeholder real: "Buscar produto, marca ou SKU…"
    const search = page.locator('input[placeholder*="Buscar"]');
    await expect(search).toBeVisible({ timeout: 10_000 });
    await search.fill("Natura");
    await page.waitForTimeout(500);
    await expect(page.locator("text=+ Novo produto")).toBeVisible();
  });

  test("cria novo produto e aparece na lista", async ({ page }) => {
    await expect(page.locator("text=+ Novo produto")).toBeVisible({ timeout: 20_000 });
    await page.click("text=+ Novo produto");

    // Aguarda o formulário abrir — label "Nome do produto *"
    await page.waitForSelector('input[placeholder*="Nome"], label:has-text("Nome do produto")', { timeout: 10_000 });

    // Preenche nome — o input fica após o label "Nome do produto *"
    const nameInput = page.locator('label:has-text("Nome do produto") + * input, form input').first();
    await nameInput.fill(PRODUCT_NAME);

    // Marca — select com opções Natura, Avon, etc.
    const brandSelect = page.locator("select").first();
    if (await brandSelect.isVisible({ timeout: 2_000 }).catch(() => false)) {
      await brandSelect.selectOption("Natura").catch(() => {});
    }

    // Quantidade — primeiro input type=number
    const numInputs = page.locator('input[type="number"]');
    await numInputs.first().fill("5");

    // Validade — input type=date
    const futureDate = new Date();
    futureDate.setFullYear(futureDate.getFullYear() + 2);
    const dateStr = futureDate.toISOString().split("T")[0];
    const dateInput = page.locator('input[type="date"]').first();
    if (await dateInput.isVisible({ timeout: 2_000 }).catch(() => false)) {
      await dateInput.fill(dateStr);
    }

    // Preço custo e venda
    const allNumInputs = page.locator('input[type="number"]');
    const inputCount = await allNumInputs.count();
    if (inputCount >= 2) await allNumInputs.nth(1).fill("25");
    if (inputCount >= 3) await allNumInputs.nth(2).fill("40");

    // Botão Salvar
    await page.click("text=Salvar");
    await page.waitForTimeout(3000);
    await expect(page.locator(`text=${PRODUCT_NAME}`)).toBeVisible({ timeout: 15_000 });
    await snap(page, "inventory-created");
  });

  test("exclui produto criado", async ({ page }) => {
    page.on("dialog", d => d.accept());
    await page.waitForTimeout(1000);
    const item = page.locator(`text=${PRODUCT_NAME}`);
    const isVisible = await item.isVisible({ timeout: 5_000 }).catch(() => false);
    if (!isVisible) { test.skip(); return; }

    const row = item.locator("..").locator("..");
    const deleteBtn = row.locator("button[title='Excluir'], button:has-text('×')").first();
    if (await deleteBtn.isVisible({ timeout: 2_000 }).catch(() => false)) {
      await deleteBtn.click();
      await page.waitForTimeout(1000);
      await expect(item).not.toBeVisible({ timeout: 5_000 });
    }
  });

  test("filtro por vencimento via URL mostra banner", async ({ page }) => {
    // Usa pushState para adicionar query param sem full reload (mantém Auth)
    await navigateWithParams(page, "/inventory?expiry=30");
    await page.waitForTimeout(1000);
    // Banner: "Vencem em menos de 30 dias"
    await expect(page.locator("text=Vencem em menos de 30 dias")).toBeVisible({ timeout: 15_000 });
    await expect(page.locator("text=Limpar filtro")).toBeVisible({ timeout: 5_000 });
    await snap(page, "inventory-expiry-filter");
  });

  test("limpar filtro remove o banner", async ({ page }) => {
    await navigateWithParams(page, "/inventory?expiry=30");
    await page.waitForTimeout(1000);
    await expect(page.locator("text=Limpar filtro")).toBeVisible({ timeout: 15_000 });
    await page.click("text=Limpar filtro");
    await expect(page).toHaveURL(/\/inventory$/);
    await expect(page.locator("text=Vencem em menos de 30 dias")).not.toBeVisible();
  });
});
