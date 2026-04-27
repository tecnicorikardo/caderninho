import { Page } from "@playwright/test";

export const EMAIL = process.env.TEST_EMAIL ?? "";
export const PASSWORD = process.env.TEST_PASSWORD ?? "";

if (!EMAIL || !PASSWORD) {
  console.warn("⚠️  TEST_EMAIL e TEST_PASSWORD não configurados no .env.test");
}

/** Faz login e aguarda o dashboard */
export async function login(page: Page) {
  await page.goto("/");

  // Aguarda a página carregar completamente
  await page.waitForLoadState("networkidle");

  // Pode estar no dashboard já (sessão ativa) ou na tela de login
  if (page.url().includes("dashboard")) return;

  // Aguarda campo de email
  await page.waitForSelector('input[type="email"]', { timeout: 20_000 });
  await page.fill('input[type="email"]', EMAIL);
  await page.fill('input[type="password"]', PASSWORD);
  await page.click('button[type="submit"]');

  // Aguarda redirecionar — pode ir para onboarding ou dashboard
  await page.waitForURL(/dashboard|onboarding/, { timeout: 20_000 });

  // Se foi para onboarding, clica em "Começar do zero"
  if (page.url().includes("onboarding")) {
    const skipBtn = page.locator("text=/começar|pular|skip/i").first();
    if (await skipBtn.isVisible({ timeout: 3_000 }).catch(() => false)) {
      await skipBtn.click();
      await page.waitForURL("**/dashboard", { timeout: 10_000 });
    }
  }
}

/** Tira screenshot com nome descritivo */
export async function snap(page: Page, name: string) {
  await page.screenshot({
    path: `test-results/screenshots/${name}.png`,
    fullPage: false,
  });
}
