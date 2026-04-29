import { test, expect } from "@playwright/test";
import { login, gotoAndWait, snap } from "./helpers";

test.describe("Configurações", () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
    await gotoAndWait(page, "/settings");
  });

  test("exibe seção de margens por marca", async ({ page }) => {
    // Título real: "Comissão por Marca"
    await expect(page.locator("text=Comissão por Marca")).toBeVisible({ timeout: 20_000 });
    await expect(page.locator("text=Natura")).toBeVisible({ timeout: 10_000 });
    await snap(page, "settings-margins");
  });

  test("altera margem da Natura e salva", async ({ page }) => {
    await expect(page.locator("text=Comissão por Marca")).toBeVisible({ timeout: 20_000 });
    const inputs = page.locator('input[type="number"]');
    await expect(inputs.first()).toBeVisible({ timeout: 10_000 });
    const first = inputs.first();
    await first.click({ clickCount: 3 });
    await first.fill("32");
    // Botão real: "Salvar margens"
    await page.click("text=Salvar margens");
    // Mensagem de sucesso: "Margens salvas com sucesso!"
    await expect(page.locator("text=Margens salvas com sucesso")).toBeVisible({ timeout: 10_000 });
    await snap(page, "settings-saved");
  });

  test("adiciona nova marca", async ({ page }) => {
    await expect(page.locator("text=Comissão por Marca")).toBeVisible({ timeout: 20_000 });
    // Input placeholder="Nome da marca"
    await page.fill('input[placeholder="Nome da marca"]', "Boticário");
    // Input placeholder="0" para a margem
    await page.fill('input[placeholder="0"]', "25");
    await page.click("text=+ Adicionar");
    await expect(page.locator("text=Boticário")).toBeVisible({ timeout: 5_000 });
  });

  test("remove marca adicionada", async ({ page }) => {
    await expect(page.locator("text=Comissão por Marca")).toBeVisible({ timeout: 20_000 });
    const boticario = page.locator("text=Boticário");
    if (await boticario.isVisible({ timeout: 3_000 }).catch(() => false)) {
      const row = boticario.locator("..").locator("..");
      await row.locator("button:has-text('×')").click();
      await expect(boticario).not.toBeVisible({ timeout: 3_000 });
    } else {
      test.skip(); // Boticário não existe ainda
    }
  });

  test("botão baixar modelo está presente", async ({ page }) => {
    await expect(page.locator("text=Comissão por Marca")).toBeVisible({ timeout: 20_000 });
    // Botão real: "⬇ Baixar modelo"
    await expect(page.locator("text=Baixar modelo")).toBeVisible({ timeout: 10_000 });
    // Botão real: "⬇ Exportar Excel"
    await expect(page.locator("text=Exportar Excel")).toBeVisible({ timeout: 5_000 });
  });

  test("input de importação aceita arquivo xlsx", async ({ page }) => {
    await expect(page.locator("text=Comissão por Marca")).toBeVisible({ timeout: 20_000 });
    // Input file com accept=".xlsx,.xls,.csv"
    const fileInput = page.locator('input[type="file"]');
    await expect(fileInput).toBeAttached({ timeout: 10_000 });
    const accept = await fileInput.getAttribute("accept");
    expect(accept).toContain(".xlsx");
  });

  test("campos de senha têm autocomplete correto", async ({ page }) => {
    // Seção "Alterar Senha" — usa o heading h2 para evitar conflito com o botão
    await expect(page.locator("h2:has-text('Alterar Senha')")).toBeVisible({ timeout: 20_000 });
    const currentPwd = page.locator('input[autocomplete="current-password"]');
    const newPwd = page.locator('input[autocomplete="new-password"]');
    await expect(currentPwd).toBeVisible({ timeout: 5_000 });
    await expect(newPwd).toBeVisible();
  });
});
