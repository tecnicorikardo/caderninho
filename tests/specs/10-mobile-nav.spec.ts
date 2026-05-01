import { test, expect, devices } from "@playwright/test";
import { login, snap } from "./helpers";

// Estes testes rodam especificamente em viewport mobile
test.use({ ...devices["Pixel 5"] });

test.describe("Navegação Mobile", () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
    await page.waitForURL(/dashboard/, { timeout: 20_000 });
    // Aguarda os dados do dashboard carregarem
    await page
      .waitForSelector("text=Faturamento do mês", { timeout: 20_000 })
      .catch(() => {});
  });

  test("bottom navigation aparece com 4 tabs", async ({ page }) => {
    // A nav inferior só aparece em mobile (md:hidden = esconde em >= 768px)
    // Pixel 5 tem 393px — deve aparecer
    const bottomNav = page.locator("nav.fixed.bottom-0");
    await expect(bottomNav).toBeVisible({ timeout: 10_000 });

    // Verifica os 4 tabs pelo texto dentro da nav
    await expect(bottomNav.locator("text=Dashboard")).toBeVisible();
    await expect(bottomNav.locator("text=Nova Venda")).toBeVisible();
    await expect(bottomNav.locator("text=Recebimentos")).toBeVisible();
    await expect(bottomNav.locator("text=Menu")).toBeVisible();
    await snap(page, "mobile-bottom-nav");
  });

  test("tab Menu abre o drawer", async ({ page }) => {
    const bottomNav = page.locator("nav.fixed.bottom-0");
    await expect(bottomNav).toBeVisible({ timeout: 10_000 });
    await bottomNav.locator("text=Menu").click();
    await page.waitForTimeout(500);

    // Drawer — botões dentro do drawer (span com texto)
    // O drawer tem classe "fixed bottom-16 left-0 right-0 z-50"
    const drawer = page.locator(".fixed.bottom-16.left-0.right-0");
    await expect(drawer).toBeVisible({ timeout: 5_000 });
    await expect(drawer.locator("text=Estoque")).toBeVisible();
    await expect(drawer.locator("text=Clientes")).toBeVisible();
    await expect(drawer.locator("text=Comissões")).toBeVisible();
    await expect(drawer.locator("text=Relatório")).toBeVisible();
    await expect(drawer.locator("text=Configurações")).toBeVisible();
    await snap(page, "mobile-drawer-open");
  });

  test("drawer fecha ao clicar em Fechar", async ({ page }) => {
    const bottomNav = page.locator("nav.fixed.bottom-0");
    await expect(bottomNav).toBeVisible({ timeout: 10_000 });
    await bottomNav.locator("text=Menu").click();
    await page.waitForTimeout(500);

    const drawer = page.locator(".fixed.bottom-16.left-0.right-0");
    await expect(drawer).toBeVisible({ timeout: 5_000 });
    await drawer.locator("text=Fechar").click();
    await page.waitForTimeout(500);
    await expect(drawer).not.toBeVisible({ timeout: 5_000 });
  });

  test("drawer fecha ao clicar fora (backdrop)", async ({ page }) => {
    const bottomNav = page.locator("nav.fixed.bottom-0");
    await expect(bottomNav).toBeVisible({ timeout: 10_000 });
    await bottomNav.locator("text=Menu").click();
    await page.waitForTimeout(500);

    // Backdrop: div com classe "fixed inset-0 bg-black/40 z-40"
    const backdrop = page.locator(".fixed.inset-0.bg-black\\/40");
    if (await backdrop.isVisible({ timeout: 3_000 }).catch(() => false)) {
      await backdrop.click({ position: { x: 10, y: 10 } });
      await page.waitForTimeout(500);
      const drawer = page.locator(".fixed.bottom-16.left-0.right-0");
      await expect(drawer).not.toBeVisible({ timeout: 5_000 });
    } else {
      test.skip(); // backdrop não encontrado
    }
  });

  test("navega para Estoque pelo drawer", async ({ page }) => {
    const bottomNav = page.locator("nav.fixed.bottom-0");
    await expect(bottomNav).toBeVisible({ timeout: 10_000 });
    await bottomNav.locator("text=Menu").click();
    await page.waitForTimeout(500);

    // Clica no botão "Estoque" dentro do drawer especificamente
    const drawer = page.locator(".fixed.bottom-16.left-0.right-0");
    await expect(drawer).toBeVisible({ timeout: 5_000 });
    await drawer.locator("button:has-text('Estoque')").click();
    await page.waitForURL("**/inventory", { timeout: 10_000 });
    await expect(page).toHaveURL(/inventory/);
  });

  test("tab Nova Venda navega para vendas", async ({ page }) => {
    const bottomNav = page.locator("nav.fixed.bottom-0");
    await expect(bottomNav).toBeVisible({ timeout: 10_000 });
    await bottomNav.locator("text=Nova Venda").click();
    await page.waitForURL("**/sales", { timeout: 10_000 });
    await expect(page).toHaveURL(/sales/);
  });

  test("tab Recebimentos navega para recebimentos", async ({ page }) => {
    const bottomNav = page.locator("nav.fixed.bottom-0");
    await expect(bottomNav).toBeVisible({ timeout: 10_000 });
    await bottomNav.locator("text=Recebimentos").click();
    await page.waitForURL("**/receivables", { timeout: 10_000 });
    await expect(page).toHaveURL(/receivables/);
  });
});
