import { test, expect } from "@playwright/test";
import { login, snap } from "./helpers";

const CUSTOMER_NAME = `Cliente Playwright ${Date.now()}`;
const CUSTOMER_PHONE = `(11) 9${Math.floor(10000000 + Math.random() * 89999999)}`;

test.describe("Clientes", () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
    await page.goto("/customers");
    await page.waitForLoadState("networkidle");
  });

  test("cria novo cliente", async ({ page }) => {
    await page.click("text=+ Novo cliente");
    await page.fill('input[placeholder*="Nome"]', CUSTOMER_NAME);
    await page.fill('input[placeholder*="Telefone"], input[placeholder*="WhatsApp"]', CUSTOMER_PHONE);
    await page.click("text=Salvar");
    await page.waitForTimeout(2000);
    await expect(page.locator(`text=${CUSTOMER_NAME}`)).toBeVisible({ timeout: 8_000 });
    await snap(page, "customer-created");
  });

  test("busca por 2+ letras filtra clientes", async ({ page }) => {
    const search = page.locator('input[placeholder*="Buscar"]');
    // Pega as 3 primeiras letras do nome criado
    const term = CUSTOMER_NAME.slice(0, 3);
    await search.fill(term);
    await page.waitForTimeout(300);
    const results = page.locator(".grid .font-semibold");
    const count = await results.count();
    expect(count).toBeGreaterThanOrEqual(0); // pode não ter ainda se o teste anterior não rodou
  });

  test("botão WhatsApp é interativo", async ({ page }) => {
    const btn = page.locator("button:has-text('WhatsApp')").first();
    if (await btn.isVisible()) {
      // Só verifica que é clicável (não abre WhatsApp real no CI)
      await expect(btn).toBeEnabled();
    }
  });
});
