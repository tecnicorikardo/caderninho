# Bloquinho Digital — Guia Completo para Novo Computador

## 1. PRÉ-REQUISITOS

Instale antes de tudo:

- [Node.js 20+](https://nodejs.org) — baixe a versão LTS
- [Git](https://git-scm.com/download/win)
- [Firebase CLI](https://firebase.google.com/docs/cli)
- [VS Code](https://code.visualstudio.com) (recomendado)

Verifique as instalações:
```powershell
node --version    # deve mostrar v20+
npm --version     # deve mostrar 10+
git --version
firebase --version
```

---

## 2. CLONAR O PROJETO

```powershell
git clone https://github.com/tecnicorikardo/caderninhopreciso.git
cd caderninhopreciso
```

---

## 3. CONFIGURAR O FRONTEND (web/)

### 3.1 Instalar dependências
```powershell
cd web
npm install
```

### 3.2 Criar o arquivo de variáveis de ambiente
Crie o arquivo `web/.env.local` com o conteúdo abaixo:

```env
VITE_FIREBASE_API_KEY=AIzaSyAbYh9oAV4H5EPZJytRZq4HM4DG7q0iYIc
VITE_FIREBASE_AUTH_DOMAIN=bloquinhodigital.firebaseapp.com
VITE_FIREBASE_PROJECT_ID=bloquinhodigital
VITE_FIREBASE_STORAGE_BUCKET=bloquinhodigital.firebasestorage.app
VITE_FIREBASE_MESSAGING_SENDER_ID=16911555826
VITE_FIREBASE_APP_ID=1:16911555826:web:addd018a6120ee67ef846b
```

### 3.3 Rodar em desenvolvimento local
```powershell
cd web
npm run dev
```
Acesse: http://localhost:5173

### 3.4 Build para produção
```powershell
cd web
npm run build
```

---

## 4. CONFIGURAR O FIREBASE

### 4.1 Login no Firebase
```powershell
firebase login
```
Vai abrir o browser para autenticar com a conta Google do projeto.

### 4.2 Verificar o projeto ativo
```powershell
firebase projects:list
# Deve mostrar: bloquinhodigital
```

### 4.3 Fazer deploy do frontend
```powershell
# Na raiz do projeto (não dentro de /web)
cd caderninhopreciso
npm run build --prefix web
firebase deploy --only hosting
```

URL de produção: https://bloquinhodigital.web.app

---

## 5. CONFIGURAR AS FUNCTIONS (backend)

```powershell
cd functions
npm install
```

### 5.1 Arquivo .env das functions
O arquivo `functions/.env` já existe no repositório com as variáveis necessárias.

### 5.2 Deploy das functions
```powershell
firebase deploy --only functions
```

---

## 6. CONFIGURAR OS TESTES E2E (Playwright)

```powershell
cd tests
npm install
npx playwright install chromium
```

### 6.1 Configurar credenciais de teste
Edite o arquivo `tests/.env.test`:
```env
TEST_EMAIL=email_que_usa_para_logar@gmail.com
TEST_PASSWORD=sua_senha_aqui
```

### 6.2 Rodar os testes
```powershell
cd tests

# Todos os testes (headless — sem abrir browser)
npm test

# Com browser visível (bom para ver o que acontece)
npx playwright test --headed

# Só um arquivo específico
npx playwright test specs/07-commission.spec.ts --headed

# Só desktop
npx playwright test --project=desktop

# Ver relatório HTML após os testes
npm run report
```

---

## 7. ESTRUTURA DO PROJETO

```
caderninhopreciso/
├── web/                        # Frontend React + Vite + Tailwind
│   ├── src/
│   │   ├── pages/              # Páginas da aplicação
│   │   │   ├── DashboardPage.tsx
│   │   │   ├── SalesPage.tsx       # Vendas com autocomplete de cliente
│   │   │   ├── InventoryPage.tsx   # Estoque com filtro por vencimento
│   │   │   ├── CustomersPage.tsx
│   │   │   ├── ReceivablesPage.tsx # Recebimentos com modal de pagamento
│   │   │   ├── CommissionPage.tsx  # Comissões + calculadora
│   │   │   ├── FinancialReportPage.tsx
│   │   │   ├── SettingsPage.tsx    # Margens + importar/exportar
│   │   │   └── components/
│   │   │       └── ImportWizard.tsx
│   │   ├── lib/                # Lógica de negócio
│   │   │   ├── firebase.ts     # Configuração Firebase
│   │   │   ├── sales.ts        # Criação de vendas + recebíveis
│   │   │   ├── margins.ts      # Cálculo de margens por marca
│   │   │   ├── money.ts        # toCents / formatMoney
│   │   │   ├── spreadsheet.ts  # Importar/exportar Excel
│   │   │   ├── types.ts        # Tipos TypeScript
│   │   │   └── ...
│   │   └── ui/
│   │       ├── DashboardLayout.tsx  # Layout com bottom nav mobile
│   │       └── StockHealthWidget.tsx
│   ├── .env.local              # Variáveis Firebase (NÃO está no git)
│   └── package.json
├── functions/                  # Firebase Cloud Functions
│   ├── src/index.js
│   └── .env                    # Variáveis das functions
├── tests/                      # Testes E2E Playwright
│   ├── specs/                  # Arquivos de teste
│   ├── .env.test               # Credenciais de teste (NÃO está no git)
│   └── playwright.config.ts
├── firestore.rules             # Regras de segurança do Firestore
├── firebase.json               # Configuração do Firebase
└── ulttask.md                  # Este arquivo
```

---

## 8. FUNCIONALIDADES IMPLEMENTADAS

### Dashboard
- Cards: Faturamento, Lucro, Valor em Estoque, Clientes
- Widget Saúde do Estoque (FEFO) com cards clicáveis de vencimento
- Cards de vencimento navegam para Estoque com filtro ativo

### Vendas (`/sales`)
- Catálogo de produtos com busca
- Carrinho com cálculo de total, custo e lucro em tempo real
- **Cliente obrigatório** em todas as vendas
- Autocomplete de cliente (digita 2+ letras, aparece sugestões)
- Formas de pagamento: Dinheiro, PIX, Cartão, Fiado, Parcelado
- **Fiado**: campo de entrada opcional, restante vai para Recebimentos
- **Parcelado**: configura nº de parcelas, 1ª parcela em X dias, entrada opcional, preview das parcelas

### Estoque (`/inventory`)
- Lista FEFO (prioridade por vencimento)
- Busca por nome, marca ou SKU
- Filtro por vencimento via URL (`?expiry=30|60|90`)
- Banner de filtro ativo com botão "Limpar filtro"
- CRUD de produtos

### Clientes (`/customers`)
- Lista com busca
- Saldo em aberto visível
- Botão WhatsApp com histórico

### Recebimentos (`/receivables`)
- Lista compacta por cliente
- Modal com 4 ações:
  - **Pagar selecionadas**: checkboxes, soma automática, valor fixo
  - **Pagar tudo**: quita tudo de uma vez
  - **Pagamento parcial**: digita valor recebido, sistema recalcula e reparcelamento o restante (escolhe nº de parcelas e datas)
  - **Mudar prazo**: reagenda data de vencimento

### Comissões (`/commission`)
- Comissão por marca no período
- Filtros: Este mês / 30 dias / Tudo
- **Calculadora**: digita custo → calcula preço sugerido e comissão automaticamente

### Relatório Financeiro (`/financial-report`)
- Receita, Custo, Lucro Bruto, Fluxo de Caixa
- Gráfico de tendência mensal
- Top produtos e top clientes
- Análise de rentabilidade com recomendação

### Configurações (`/settings`)
- **Margens por marca**: configurável, adicionar/remover marcas
- **Importar/Exportar Excel**:
  - Baixar modelo com abas Clientes e Produtos
  - Importar planilha preenchida com preview
  - Exportar dados atuais
- Alterar senha

### Navegação Mobile
- Bottom navigation fixa com 4 tabs: Dashboard, Nova Venda, Recebimentos, Menu
- Menu abre drawer com: Estoque, Clientes, Comissões, Relatório, Configurações
- Desktop mantém navbar horizontal no topo

---

## 9. FLUXO DE DEPLOY

```powershell
# 1. Fazer as alterações no código
# 2. Build
npm run build --prefix web

# 3. Deploy só do frontend
firebase deploy --only hosting

# 4. Deploy só das functions (se mudou algo no backend)
firebase deploy --only functions

# 5. Deploy completo
firebase deploy
```

---

## 10. BANCO DE DADOS (Firestore)

Estrutura das coleções por usuário:
```
users/{uid}/
  ├── customers/      # Clientes
  ├── inventory/      # Estoque (FEFO por expiryDate)
  ├── products/       # Catálogo de produtos
  ├── sales/          # Vendas registradas
  └── receivables/    # Contas a receber (fiado/parcelado)
```

Campos do perfil do usuário (`users/{uid}`):
- `brandMargins`: array de `{ brand, marginPercent }` — margens configuradas
- `growthLevel`: nível do Plano de Crescimento (controlado pelo servidor)

---

## 11. PROBLEMAS CONHECIDOS E SOLUÇÕES

### "Firestore transactions require all reads before writes"
Já corrigido em `web/src/lib/sales.ts` — todas as leituras acontecem antes das escritas.

### Calculadora mostrando valores errados (R$10.000 em vez de R$100)
Já corrigido em `web/src/lib/money.ts` — o `toCents` trata corretamente ponto decimal vs separador de milhar.

### Autocomplete de cliente não seleciona
Já corrigido em `web/src/pages/SalesPage.tsx` — usa `onMouseDown` com `preventDefault` para evitar que o blur feche as sugestões antes do clique.

### Bottom navigation não aparece no mobile
Funciona corretamente abaixo de 768px. Para testar: abrir DevTools (F12) → ícone de celular → selecionar iPhone ou Android.

---

## 12. PRÓXIMAS FUNCIONALIDADES SUGERIDAS

- [ ] Exportar relatório financeiro para PDF
- [ ] Notificações push para recebíveis atrasados
- [ ] Metas de vendas mensais com acompanhamento
- [ ] Comparativo com períodos anteriores no relatório
- [ ] Scan de código de barras para cadastro de produtos
- [ ] Exportar/importar aba de Vendas no Excel
- [ ] IA para previsão de demanda por sazonalidade

---

## 13. CONTATOS E REPOSITÓRIO

- **Repositório**: https://github.com/tecnicorikardo/caderninhopreciso
- **App em produção**: https://bloquinhodigital.web.app
- **Firebase Console**: https://console.firebase.google.com/project/bloquinhodigital
