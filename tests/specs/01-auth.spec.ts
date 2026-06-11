import { test, expect } from "@playwright/test";
import { login, EMAIL, PASSWORD } from "./helpers";

test.describe("Autenticação", () => {
  test("login com credenciais inválidas mostra erro", async ({ page }) => {
    await page.goto("/");
    await page.waitForSelector('input[type="email"]', { timeout: 15_000 });
    await page.fill('input[type="email"]', "invalido@teste.com");
    await page.fill('input[type="password"]', "senhaerrada");
    await page.click('button[type="submit"]');
    // Deve aparecer mensagem de erro específica do Supabase
    await expect(page.locator("text=/E-mail ou senha incorretos|Invalid credentials|erro/i").first()).toBeVisible({ timeout: 10_000 });
  });

  test("login com credenciais válidas redireciona para dashboard", async ({ page }) => {
    await login(page);
    await expect(page).toHaveURL(/dashboard/);
    await expect(page.locator("text=Dashboard").first()).toBeVisible();
  });

  test("botão Sair desloga o usuário", async ({ page }) => {
    await login(page);
    page.on("dialog", d => d.accept()); // confirma o confirm()
    await page.click("text=Sair");
    await page.waitForURL("**/", { timeout: 8_000 });
    await expect(page.locator('input[type="email"]')).toBeVisible();
  });
});
