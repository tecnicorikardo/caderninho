import { Page } from "@playwright/test";
import * as fs from "fs";
import * as path from "path";

export const EMAIL = process.env.TEST_EMAIL ?? "";
export const PASSWORD = process.env.TEST_PASSWORD ?? "";

if (!EMAIL || !PASSWORD) {
  console.warn("⚠️  TEST_EMAIL e TEST_PASSWORD não configurados no .env.test");
}

/** Faz login e aguarda o dashboard */
export async function login(page: Page) {
  await page.goto("/");
  await page.waitForLoadState("domcontentloaded");

  // Se já está no dashboard (sessão ativa), aguarda os dados carregarem
  if (page.url().includes("dashboard")) {
    await waitForDashboardData(page);
    return;
  }

  // Aguarda campo de email aparecer
  await page.waitForSelector('input[type="email"]', { timeout: 25_000 });
  await page.fill('input[type="email"]', EMAIL);
  await page.fill('input[type="password"]', PASSWORD);
  await page.click('button[type="submit"]');

  // Aguarda redirecionar — pode ir para onboarding ou dashboard
  await page.waitForURL(/dashboard|onboarding/, { timeout: 25_000 });

  // Se foi para onboarding, clica em "Começar do zero"
  if (page.url().includes("onboarding")) {
    const skipBtn = page.locator("text=/começar|pular|skip/i").first();
    if (await skipBtn.isVisible({ timeout: 3_000 }).catch(() => false)) {
      await skipBtn.click();
      await page.waitForURL("**/dashboard", { timeout: 10_000 });
    }
  }

  // Aguarda os dados do dashboard carregarem (confirma que Auth está pronto)
  await waitForDashboardData(page);
}

/** Aguarda os dados do dashboard aparecerem */
async function waitForDashboardData(page: Page) {
  // Aguarda o loading sumir OU algum card aparecer
  await page
    .waitForSelector("text=Faturamento do mês", { timeout: 20_000 })
    .catch(() => {});
}

/**
 * Navega para uma rota protegida usando navegação SPA (clique no link)
 * para evitar que o Supabase Auth perca a sessão.
 */
export async function gotoAndWait(page: Page, route: string) {
  // Garante que está no dashboard com Auth pronto
  const currentUrl = page.url();
  if (!currentUrl.includes("bloquinhodigital.web.app") || currentUrl.endsWith("/")) {
    await page.goto("/dashboard");
    await page.waitForURL(/dashboard/, { timeout: 20_000 });
    await waitForDashboardData(page);
  }

  // Usa navegação SPA via link do nav (evita full reload que perde o Auth)
  const routeMap: Record<string, string> = {
    "/inventory": "Estoque",
    "/customers": "Clientes",
    "/sales": "Vendas",
    "/receivables": "Recebimentos",
    "/commission": "Comissões",
    "/financial-report": "Relatório",
    "/settings": "Configurações",
    "/dashboard": "Dashboard",
  };

  const linkLabel = routeMap[route];
  if (linkLabel) {
    // Clica no link do nav desktop (header)
    const navLink = page.locator(`nav a:has-text("${linkLabel}"), header a:has-text("${linkLabel}")`).first();
    const isNavVisible = await navLink.isVisible({ timeout: 3_000 }).catch(() => false);

    if (isNavVisible) {
      await navLink.click();
    } else {
      // Fallback: usa page.goto mas aguarda o Supabase Auth reinicializar
      await page.goto(route);
      // Aguarda a URL ser a correta (pode redirecionar para dashboard e voltar)
      await page.waitForTimeout(2000);
      // Se redirecionou para dashboard, navega de novo via link
      if (!page.url().includes(route.replace("/", ""))) {
        await waitForDashboardData(page);
        const navLink2 = page.locator(`nav a:has-text("${linkLabel}"), header a:has-text("${linkLabel}")`).first();
        if (await navLink2.isVisible({ timeout: 3_000 }).catch(() => false)) {
          await navLink2.click();
        }
      }
    }
  } else {
    // Rota sem mapeamento — usa goto direto
    await page.goto(route);
  }

  // Aguarda a URL mudar para a rota desejada
  await page.waitForURL(`**${route}**`, { timeout: 15_000 }).catch(() => {});
  await page.waitForLoadState("domcontentloaded");

  // Aguarda o loading sumir (se existir)
  const loadingVisible = await page
    .locator("text=Carregando…")
    .isVisible({ timeout: 1_000 })
    .catch(() => false);
  if (loadingVisible) {
    await page
      .waitForSelector("text=Carregando…", { state: "hidden", timeout: 20_000 })
      .catch(() => {});
  }

  // Aguarda o spinner "Calculando" sumir (relatório financeiro)
  const calcVisible = await page
    .locator("text=Calculando")
    .isVisible({ timeout: 1_000 })
    .catch(() => false);
  if (calcVisible) {
    await page
      .waitForSelector("text=Calculando", { state: "hidden", timeout: 25_000 })
      .catch(() => {});
  }
}

/** Tira screenshot com nome descritivo */
export async function snap(page: Page, name: string) {
  const dir = "test-results/screenshots";
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  await page.screenshot({
    path: path.join(dir, `${name}.png`),
    fullPage: false,
  });
}
