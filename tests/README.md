# Testes E2E — Bloquinho Digital

Testes automatizados com [Playwright](https://playwright.dev) que rodam no browser real.

## Instalação

```bash
cd tests
npm install
npx playwright install chromium
```

## Configurar credenciais

Edite o arquivo `.env.test`:
```
TEST_EMAIL=seu_email@teste.com
TEST_PASSWORD=sua_senha_aqui
```

Ou exporte as variáveis antes de rodar:
```bash
# Windows PowerShell
$env:TEST_EMAIL="seu@email.com"
$env:TEST_PASSWORD="suasenha"

# Linux/Mac
export TEST_EMAIL="seu@email.com"
export TEST_PASSWORD="suasenha"
```

## Rodar os testes

```bash
# Todos os testes (headless — sem abrir browser)
npm test

# Com browser visível (bom para depurar)
npm run test:headed

# Interface visual interativa
npm run test:ui

# Só um arquivo específico
npx playwright test specs/07-commission.spec.ts --headed

# Só mobile
npx playwright test --project=mobile --headed
```

## Ver relatório

```bash
npm run report
```

## Estrutura

| Arquivo | O que testa |
|---|---|
| `01-auth.spec.ts` | Login, logout, credenciais inválidas |
| `02-dashboard.spec.ts` | Cards, Saúde do Estoque, filtro de vencimento |
| `03-inventory.spec.ts` | CRUD de produtos, busca, filtro por URL |
| `04-customers.spec.ts` | CRUD de clientes, busca |
| `05-sales.spec.ts` | Carrinho, autocomplete, fiado, parcelado |
| `06-receivables.spec.ts` | Modal, pagar selecionadas, pagamento parcial |
| `07-commission.spec.ts` | Calculadora (verifica valores corretos) |
| `08-financial-report.spec.ts` | Cards, filtros de período |
| `09-settings.spec.ts` | Margens, importar/exportar, senha |
| `10-mobile-nav.spec.ts` | Bottom nav, drawer, navegação mobile |

## Screenshots

Falhas geram screenshots automaticamente em `test-results/screenshots/`.
