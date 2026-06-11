# 🧪 Executar Testes - Guia Rápido

## ✅ Pré-requisitos Completos

- [x] Node.js instalado
- [x] Playwright instalado (v1.59.1)
- [x] Navegador Chromium instalado
- [x] **Supabase configurado** (variáveis em `web/.env.local`) ✅
- [ ] **Credenciais de teste configuradas** ⚠️

## 🔑 Configurar Credenciais (OBRIGATÓRIO)

Antes de rodar os testes, você precisa configurar uma conta de teste:

### Passo 1: Criar conta de teste

1. Acesse: https://bloquinhodigital.web.app
2. Clique em "Criar conta" ou "Registrar"
3. Use um email de teste, por exemplo:
   - `teste@bloquinhodigital.com`
   - `seu_email+teste@gmail.com` (Gmail suporta alias com +)
4. Crie uma senha forte, por exemplo: `Teste123456!`
5. Complete o processo de onboarding (se houver)

### Passo 2: Configurar no .env.test

Edite o arquivo `tests/.env.test` e coloque as credenciais:

```env
TEST_EMAIL=teste@bloquinhodigital.com
TEST_PASSWORD=Teste123456!
```

> 💡 **Dica**: Use uma conta dedicada para testes, não sua conta pessoal!

---

## 🚀 Executar os Testes

### Opção 1: Todos os testes (modo headless - sem abrir navegador)

```bash
cd tests
npm test
```

**Quando usar**: CI/CD, execução rápida

### Opção 2: Com navegador visível (modo headed)

```bash
cd tests
npm run test:headed
```

**Quando usar**: Debugging, ver o que está acontecendo

### Opção 3: Interface interativa (recomendado para desenvolvimento)

```bash
cd tests
npm run test:ui
```

**Quando usar**: Desenvolvimento, depuração detalhada, ver cada passo

### Opção 4: Teste específico

```bash
cd tests
npx playwright test specs/01-auth.spec.ts --headed
```

**Quando usar**: Testar uma funcionalidade específica

### Opção 5: Apenas mobile

```bash
cd tests
npx playwright test --project=mobile --headed
```

**Quando usar**: Testar responsividade mobile

---

## 📊 Ver Relatório

Após executar os testes, veja o relatório HTML:

```bash
cd tests
npm run report
```

O relatório abrirá no navegador e mostrará:
- ✅ Testes passados
- ❌ Testes falhados
- ⏱️ Tempo de execução
- 📸 Screenshots de falhas
- 🔍 Traces para debugging

---

## 🎯 Ordem Recomendada de Execução

### 1. Teste de Autenticação (rápido - 30s)

```bash
cd tests
npx playwright test specs/01-auth.spec.ts --headed
```

**Valida**: Login, logout, credenciais inválidas

### 2. Teste do Dashboard (rápido - 45s)

```bash
npx playwright test specs/02-dashboard.spec.ts --headed
```

**Valida**: Métricas, cards, filtros

### 3. Teste de Vendas (importante - 90s)

```bash
npx playwright test specs/05-sales.spec.ts --headed
```

**Valida**: Fluxo completo de vendas (à vista, fiado, parcelado)

### 4. Todos os testes (completo - 8min)

```bash
npm test
```

**Valida**: Todas as funcionalidades do sistema

---

## 🔍 Estrutura dos Testes

### Testes Rápidos (< 1min)
- `01-auth.spec.ts` - Autenticação (30s)
- `07-commission.spec.ts` - Comissões (30s)
- `10-mobile-nav.spec.ts` - Navegação mobile (30s)

### Testes Médios (1-2min)
- `02-dashboard.spec.ts` - Dashboard (45s)
- `04-customers.spec.ts` - Clientes (45s)
- `08-financial-report.spec.ts` - Relatório (45s)

### Testes Longos (> 1min)
- `03-inventory.spec.ts` - Estoque (60s)
- `05-sales.spec.ts` - Vendas (90s)
- `06-receivables.spec.ts` - Recebimentos (60s)
- `09-settings.spec.ts` - Configurações (60s)

**Tempo total**: ~8 minutos (desktop + mobile)

---

## 🐛 Solução de Problemas

### ❌ Erro: "TEST_EMAIL e TEST_PASSWORD não configurados"

**Causa**: Arquivo `.env.test` não configurado

**Solução**: Configure as credenciais conforme seção "Configurar Credenciais" acima

### ❌ Erro: "TimeoutError: Waiting for selector"

**Causa**: Elemento não encontrado ou aplicação offline

**Solução**:
1. Verifique se https://bloquinhodigital.web.app está acessível
2. Execute com `--headed` para ver o navegador
3. Verifique se as credenciais estão corretas

### ❌ Erro: "login com credenciais válidas redireciona para dashboard" falha

**Causa**: Credenciais inválidas ou conta não existe

**Solução**:
1. Confirme que criou a conta com as credenciais do `.env.test`
2. Tente fazer login manualmente no navegador primeiro
3. Verifique se completou o onboarding

### ❌ Erro: "Auth state lost"

**Causa**: Firebase Auth perde sessão entre navegações

**Solução**: Já corrigido nos testes com `gotoAndWait()` helper

---

## 📈 Cobertura Atual

### ✅ Funcionalidades Testadas

- **Autenticação**: Login, logout, erro de credenciais
- **Dashboard**: Cards de métricas, filtros de vencimento
- **Estoque**: CRUD completo, busca, filtros
- **Clientes**: CRUD completo, busca
- **Vendas**: À vista, fiado, parcelado, autocomplete
- **Recebimentos**: Pagamento individual, parcial, múltiplo
- **Comissões**: Calculadora de comissões
- **Relatório Financeiro**: Cards, filtros de período
- **Configurações**: Margens, importar/exportar, alterar senha
- **Mobile**: Navegação, bottom nav, drawer

### ❌ Não Testado (escopo futuro)

- Integração com Pix (edge function)
- Upload de imagens de produtos
- Migração de dados Firebase → Supabase
- Performance sob alta carga
- Acessibilidade (WCAG)

---

## 🎓 Comandos Úteis

```bash
# Listar todos os testes disponíveis
npx playwright test --list

# Executar apenas testes que falharam
npx playwright test --last-failed

# Executar com debug verbose
DEBUG=pw:api npx playwright test

# Gerar relatório sem executar testes
npm run report

# Atualizar snapshots (se houver testes visuais)
npx playwright test --update-snapshots

# Executar em modo debug (pausa antes de cada ação)
npx playwright test --debug
```

---

## 🚀 Próximos Passos

1. **Configurar credenciais** no `tests/.env.test`
2. **Executar teste rápido**: `cd tests && npx playwright test specs/01-auth.spec.ts --headed`
3. **Executar todos os testes**: `npm test`
4. **Ver relatório**: `npm run report`
5. **Configurar Vitest** para testes unitários (ver `GUIA_TESTES.md`)

---

## 📞 Suporte

Se tiver problemas:
1. Verifique a seção "Solução de Problemas" acima
2. Consulte o `GUIA_TESTES.md` para informações detalhadas
3. Execute com `--headed` para ver o navegador
4. Verifique se a aplicação está acessível: https://bloquinhodigital.web.app

