# Guia de Testes - Bloquinho Digital

Este guia detalha como executar e configurar os testes E2E (Playwright) e unitários (Vitest) do projeto.

## 📋 Índice

1. [Testes E2E com Playwright](#testes-e2e-com-playwright)
2. [Testes Unitários com Vitest](#testes-unitários-com-vitest)
3. [CI/CD](#cicd)
4. [Solução de Problemas](#solução-de-problemas)

---

## 🎭 Testes E2E com Playwright

### Pré-requisitos

- Node.js 18+ instalado
- Conta de teste no Firebase Authentication
- Aplicação deployada em `https://bloquinhodigital.web.app`

### Instalação

```bash
cd tests
npm install
npx playwright install chromium
```

### Configuração

1. **Configure as credenciais de teste** no arquivo `tests/.env.test`:

```env
TEST_EMAIL=seu_email_teste@exemplo.com
TEST_PASSWORD=sua_senha_teste_123
```

> ⚠️ **IMPORTANTE**: Use uma conta de teste dedicada, não sua conta pessoal!

2. **Crie a conta de teste**:
   - Acesse: https://bloquinhodigital.web.app
   - Registre uma nova conta com o email e senha acima
   - Complete o onboarding inicial

### Executar os Testes

#### Todos os testes (headless)
```bash
cd tests
npm test
```

#### Com navegador visível (debugging)
```bash
npm run test:headed
```

#### Interface interativa (melhor para desenvolvimento)
```bash
npm run test:ui
```

#### Teste específico
```bash
npx playwright test specs/05-sales.spec.ts --headed
```

#### Apenas mobile
```bash
npx playwright test --project=mobile --headed
```

#### Apenas desktop
```bash
npx playwright test --project=desktop
```

### Ver Relatório

Após executar os testes, veja o relatório HTML:

```bash
npm run report
```

### Estrutura dos Testes

| Arquivo | Funcionalidade Testada | Tempo Aprox. |
|---------|------------------------|--------------|
| `01-auth.spec.ts` | Login, logout, credenciais inválidas | 30s |
| `02-dashboard.spec.ts` | Cards de métricas, filtros de vencimento | 45s |
| `03-inventory.spec.ts` | CRUD de produtos, busca, filtros | 60s |
| `04-customers.spec.ts` | CRUD de clientes, busca | 45s |
| `05-sales.spec.ts` | Carrinho, autocomplete, fiado, parcelado | 90s |
| `06-receivables.spec.ts` | Pagamento de recebíveis, parcial | 60s |
| `07-commission.spec.ts` | Calculadora de comissões | 30s |
| `08-financial-report.spec.ts` | Relatório financeiro, filtros | 45s |
| `09-settings.spec.ts` | Margens, importar/exportar, senha | 60s |
| `10-mobile-nav.spec.ts` | Navegação mobile, bottom nav, drawer | 30s |

**Tempo total estimado**: ~8 minutos (desktop + mobile)

### Screenshots e Vídeos

- **Screenshots**: Gerados automaticamente em falhas → `test-results/screenshots/`
- **Vídeos**: Desabilitados por padrão (para habilitar, edite `playwright.config.ts`)

### Cobertura de Testes

✅ **Testado**:
- Autenticação (login/logout)
- Dashboard e métricas
- CRUD completo (produtos, clientes)
- Fluxo de vendas (à vista, fiado, parcelado)
- Recebimentos e pagamentos
- Calculadora de comissões
- Relatório financeiro
- Configurações e importação/exportação
- Navegação mobile

❌ **Não testado** (escopo futuro):
- Integração com Pix (edge function)
- Migração de dados
- Performance sob carga
- Acessibilidade (WCAG)

---

## 🧪 Testes Unitários com Vitest

> 📝 **Status**: Configuração pendente

### Instalação

```bash
cd web
npm install -D vitest @vitest/ui @testing-library/react @testing-library/jest-dom jsdom
```

### Configuração

1. **Atualizar `vite.config.ts`**:

```typescript
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { fileURLToPath } from "node:url";

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      "@": fileURLToPath(new URL("./src", import.meta.url)),
    },
  },
  build: {
    outDir: "dist",
  },
  server: {
    port: 5173,
  },
  test: {
    globals: true,
    environment: "jsdom",
    setupFiles: "./src/tests/setup.ts",
    coverage: {
      provider: "v8",
      reporter: ["text", "json", "html"],
    },
  },
});
```

2. **Criar arquivo de setup** em `web/src/tests/setup.ts`:

```typescript
import "@testing-library/jest-dom";
```

3. **Adicionar scripts no `package.json`**:

```json
{
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview",
    "typecheck": "tsc -p tsconfig.json --noEmit",
    "test": "vitest",
    "test:ui": "vitest --ui",
    "test:coverage": "vitest --coverage"
  }
}
```

### Estrutura de Testes

Crie testes próximos aos componentes:

```
web/src/
├── components/
│   ├── Button.tsx
│   └── Button.test.tsx
├── lib/
│   ├── calculations.ts
│   └── calculations.test.ts
└── tests/
    └── setup.ts
```

### Exemplo de Teste

**`web/src/lib/calculations.test.ts`**:

```typescript
import { describe, it, expect } from "vitest";
import { calculateCommission, calculateInstallments } from "./calculations";

describe("calculateCommission", () => {
  it("calcula comissão de 10% corretamente", () => {
    expect(calculateCommission(1000, 10)).toBe(100);
  });

  it("retorna 0 para valores inválidos", () => {
    expect(calculateCommission(0, 10)).toBe(0);
    expect(calculateCommission(-100, 10)).toBe(0);
  });
});

describe("calculateInstallments", () => {
  it("divide valor em parcelas iguais", () => {
    const result = calculateInstallments(1000, 3);
    expect(result).toHaveLength(3);
    expect(result.every(v => v === 333.33)).toBe(true);
  });
});
```

### Executar Testes

```bash
cd web
npm test          # Watch mode
npm run test:ui   # Interface gráfica
npm run test:coverage  # Com cobertura
```

---

## 🚀 CI/CD

### GitHub Actions

Crie `.github/workflows/test.yml`:

```yaml
name: Tests

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  e2e:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 18
      
      - name: Install dependencies
        working-directory: tests
        run: npm ci
      
      - name: Install Playwright browsers
        working-directory: tests
        run: npx playwright install chromium
      
      - name: Run E2E tests
        working-directory: tests
        run: npm test
        env:
          TEST_EMAIL: ${{ secrets.TEST_EMAIL }}
          TEST_PASSWORD: ${{ secrets.TEST_PASSWORD }}
      
      - name: Upload test results
        if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: playwright-report
          path: tests/playwright-report/

  unit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 18
      
      - name: Install dependencies
        working-directory: web
        run: npm ci
      
      - name: Run unit tests
        working-directory: web
        run: npm test -- --run
      
      - name: Run type check
        working-directory: web
        run: npm run typecheck
```

### Configurar Secrets

No GitHub, vá em **Settings → Secrets → Actions** e adicione:

- `TEST_EMAIL`: Email da conta de teste
- `TEST_PASSWORD`: Senha da conta de teste

---

## 🔧 Solução de Problemas

### Playwright não encontra elementos

**Problema**: Teste falha com `TimeoutError: Waiting for selector...`

**Soluções**:
1. Aumente o timeout: `await page.waitForSelector("...", { timeout: 30_000 })`
2. Use `--headed` para ver o que está acontecendo
3. Verifique se a aplicação está deployada e acessível
4. Confirme que as credenciais estão corretas no `.env.test`

### Testes passam localmente mas falham no CI

**Problema**: CI não tem as credenciais configuradas

**Solução**: Configure os secrets `TEST_EMAIL` e `TEST_PASSWORD` no GitHub Actions

### Erro "Auth state lost"

**Problema**: Firebase Auth perde a sessão entre navegações

**Solução**: Use `gotoAndWait()` do `helpers.ts` em vez de `page.goto()` direto

### Vitest não encontra módulos

**Problema**: `Cannot find module '@/...'`

**Solução**: Configure o `alias` no `vite.config.ts` e `tsconfig.json`:

```json
{
  "compilerOptions": {
    "paths": {
      "@/*": ["./src/*"]
    }
  }
}
```

---

## 📊 Relatórios e Métricas

### Playwright HTML Report

Após executar os testes:
```bash
cd tests
npm run report
```

O relatório mostra:
- ✅ Testes passados/falhados
- ⏱️ Tempo de execução
- 📸 Screenshots de falhas
- 📝 Traces para debugging

### Vitest Coverage Report

Após executar com cobertura:
```bash
cd web
npm run test:coverage
```

Abra `web/coverage/index.html` no navegador.

---

## 🎯 Próximos Passos

1. [ ] Configurar Vitest e criar testes unitários
2. [ ] Adicionar testes de integração para Supabase Edge Functions
3. [ ] Implementar testes de acessibilidade (axe-core)
4. [ ] Configurar CI/CD no GitHub Actions
5. [ ] Adicionar testes de performance (Lighthouse CI)

---

## 📚 Recursos

- [Playwright Docs](https://playwright.dev)
- [Vitest Docs](https://vitest.dev)
- [Testing Library](https://testing-library.com/docs/react-testing-library/intro)
- [GitHub Actions](https://docs.github.com/en/actions)

