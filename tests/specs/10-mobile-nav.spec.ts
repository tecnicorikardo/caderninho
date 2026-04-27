import { test, expect, devices } from "@playwright/test";
import { login, snap } from "./helpers";

// Estes testes rodam especificamente em viewport mobile
test.use({ ...devices["Pixel 5"] });

test.describe("Navegação Mobile", () => {
  test.beforeEach(async ({ page }) => { await login(page); });

  test("bottom navigation aparece com 4 tabs", async ({ page }) => {
    // A nav inferior só aparece em mobile (md:hidden = esconde em >= 768px)
    const bottomNav = page.locator("nav.fixed.bottom-0");
    await expect(bottomNav).toBeVisible();

    await expect(page.locator("text=Dashboard").last()).toBeVisible();
    await expect(page.locator("text=Nova Venda")).toBeVisible();
    await expect(page.locator("text=Recebimentos").last()).toBeVisible();
    await expect(page.locator("text=Menu")).toBeVisible();
    await snap(page, "mobile-bottom-nav");
  });

  test("tab Menu abre o drawer", async ({ page }) => {
    await page.locator("nav.fixed.bottom-0").locator("text=Menu").click();
    await page.waitForTimeout(400);
    // Drawer deve aparecer com os itens
    await expect(page.locator("text=Estoque")).toBeVisible();
    await expect(page.locator("text=Clientes")).toBeVisible();
    await expect(page.locator("text=Comissões")).toBeVisible();
    await expect(page.locator("text=Relatório")).toBeVisible();
    await expect(page.locator("text=Configurações")).toBeVisible();
    await snap(page, "mobile-drawer-open");
  });

  test("drawer fecha ao clicar em Fechar", async ({ page }) => {
    await page.locator("nav.fixed.bottom-0").locator("text=Menu").click();
    await page.waitForTimeout(400);
    await page.click("text=Fechar");
    await page.waitForTimeout(400);
    await expect(page.locator("text=Fechar")).not.toBeVisible();
  });

  test("drawer fecha ao clicar fora (backdrop)", async ({ page }) => {
    await page.locator("nav.fixed.bottom-0").locator("text=Menu").click();
    await page.waitForTimeout(400);
    // Clica no backdrop (fora do drawer)
    await page.locator(".fixed.inset-0.bg-black\\/40").click({ position: { x: 10, y: 10 } });
    await page.waitForTimeout(400);
    await expect(page.locator("text=Fechar")).not.toBeVisible();
  });

  test("navega para Estoque pelo drawer", async ({ page }) => {
    await page.locator("nav.fixed.bottom-0").locator("text=Menu").click();
    await page.waitForTimeout(400);
    await page.click("text=Estoque");
    await page.waitForURL("**/inventory");
    await expect(page).toHaveURL(/inventory/);
  });

  test("tab Nova Venda navega para vendas", async ({ page }) => {
    await page.locator("nav.fixed.bottom-0").locator("text=Nova Venda").click();
    await page.waitForURL("**/sales");
    await expect(page).toHaveURL(/sales/);
  });

  test("tab Recebimentos navega para recebimentos", async ({ page }) => {
    await page.locator("nav.fixed.bottom-0").locator("text=Recebimentos").click();
    await page.waitForURL("**/receivables");
    await expect(page).toHaveURL(/receivables/);
  });
});
