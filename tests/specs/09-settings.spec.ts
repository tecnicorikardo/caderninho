import { test, expect } from "@playwright/test";
import { login, snap } from "./helpers";

test.describe("Configurações", () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
    await page.goto("/settings");
    await page.waitForLoadState("networkidle");
  });

  test("exibe seção de margens por marca", async ({ page }) => {
    await expect(page.locator("text=Comissão por Marca")).toBeVisible();
    await expect(page.locator("text=Natura")).toBeVisible();
    await snap(page, "settings-margins");
  });

  test("altera margem da Natura e salva", async ({ page }) => {
    const inputs = page.locator('input[type="number"]');
    const first = inputs.first();
    await first.click({ clickCount: 3 }); // seleciona tudo
    await first.fill("32");
    await page.click("text=Salvar margens");
    await expect(page.locator("text=Margens salvas")).toBeVisible({ timeout: 8_000 });
    await snap(page, "settings-saved");
  });

  test("adiciona nova marca", async ({ page }) => {
    await page.fill('input[placeholder="Nome da marca"]', "Boticário");
    await page.fill('input[placeholder="0"]', "25");
    await page.click("text=+ Adicionar");
    await expect(page.locator("text=Boticário")).toBeVisible({ timeout: 5_000 });
  });

  test("remove marca adicionada", async ({ page }) => {
    const boticario = page.locator("text=Boticário");
    if (await boticario.isVisible()) {
      // Clica no × da linha do Boticário
      const row = boticario.locator("..").locator("..");
      await row.locator("button:has-text('×')").click();
      await expect(boticario).not.toBeVisible({ timeout: 3_000 });
    }
  });

  test("botão baixar modelo está presente", async ({ page }) => {
    await expect(page.locator("text=Baixar modelo")).toBeVisible();
    await expect(page.locator("text=Exportar Excel")).toBeVisible();
  });

  test("input de importação aceita arquivo xlsx", async ({ page }) => {
    const fileInput = page.locator('input[type="file"]');
    await expect(fileInput).toBeVisible();
    const accept = await fileInput.getAttribute("accept");
    expect(accept).toContain(".xlsx");
  });

  test("campos de senha têm autocomplete correto", async ({ page }) => {
    const currentPwd = page.locator('input[autocomplete="current-password"]');
    const newPwd = page.locator('input[autocomplete="new-password"]');
    await expect(currentPwd).toBeVisible();
    await expect(newPwd).toBeVisible();
  });
});
