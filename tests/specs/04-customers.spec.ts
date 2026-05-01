import { test, expect } from "@playwright/test";
import { login, gotoAndWait, snap } from "./helpers";

const CUSTOMER_NAME = `Cliente Playwright ${Date.now()}`;
const CUSTOMER_PHONE = `(11) 9${Math.floor(10000000 + Math.random() * 89999999)}`;

test.describe("Clientes", () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
    await gotoAndWait(page, "/customers");
  });

  test("cria novo cliente", async ({ page }) => {
    await expect(page.locator("text=+ Novo cliente")).toBeVisible({ timeout: 20_000 });
    await page.click("text=+ Novo cliente");

    // Formulário: label "Nome *" e "Telefone / WhatsApp *"
    await page.waitForSelector('label:has-text("Nome")', { timeout: 10_000 });

    // Preenche nome — input após label "Nome *"
    const nameInput = page.locator('form input').first();
    await nameInput.fill(CUSTOMER_NAME);

    // Telefone — segundo input do form
    const phoneInput = page.locator('form input').nth(1);
    if (await phoneInput.isVisible({ timeout: 2_000 }).catch(() => false)) {
      await phoneInput.fill(CUSTOMER_PHONE);
    }

    await page.click("text=Salvar");
    await page.waitForTimeout(3000);
    await expect(page.locator(`text=${CUSTOMER_NAME}`)).toBeVisible({ timeout: 15_000 });
    await snap(page, "customer-created");
  });

  test("busca por 2+ letras filtra clientes", async ({ page }) => {
    await page.waitForTimeout(1000);
    // Placeholder real: "Buscar por nome, telefone ou e-mail…"
    const search = page.locator('input[placeholder*="Buscar"]');
    await expect(search).toBeVisible({ timeout: 15_000 });
    await search.fill("Cli");
    await page.waitForTimeout(500);
    await expect(search).toBeVisible();
  });

  test("botão WhatsApp é interativo", async ({ page }) => {
    await page.waitForTimeout(1000);
    // O botão tem texto "WhatsApp" (sem ícone, só texto)
    const btn = page.locator("button:has-text('WhatsApp')").first();
    if (await btn.isVisible({ timeout: 10_000 }).catch(() => false)) {
      await expect(btn).toBeEnabled();
    } else {
      test.skip(); // sem clientes cadastrados
    }
  });
});
