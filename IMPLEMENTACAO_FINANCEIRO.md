# Implementação do Sistema Financeiro Reestruturado

## ✅ Mudanças Implementadas

### 1. Separação de Tipos de Despesas

**Antes:** Todas as despesas eram tratadas como `expense`

**Agora:** Três tipos distintos de movimentações financeiras:
- `revenue` - Receitas (vendas, pagamentos de fiados)
- `expense` - Despesas operacionais (aluguel, energia, funcionários)
- `stock` - Compra de estoque (mercadorias, insumos)

**Benefício:** Permite cálculos financeiros mais precisos, separando custos operacionais de investimento em estoque.

---

### 2. Módulo Financeiro - Visão Rápida

**Localização:** `lib/src/features/finance/finance_screen.dart`

**Funcionalidades:**
- Filtros: Dia, Semana, Mês
- Card resumido mostrando:
  - Receita total do período
  - Despesas totais do período
  - Saldo (ou Prejuízo se negativo)
- Botão "Ver Relatório Detalhado" que abre o módulo de Relatórios
- Lista de movimentações com ícones diferenciados:
  - 🟢 Receita (verde)
  - 🔴 Despesa (vermelho)
  - 🟠 Compra de Estoque (laranja)
- Botão flutuante para adicionar nova despesa
- Ao adicionar despesa, pode marcar se é "Compra de estoque"

---

### 3. Módulo de Relatórios - Análise Detalhada

**Localização:** `lib/src/features/reports/reports_screen.dart`

**Funcionalidades:**

#### Card de Faturamento
- Receita Total
- Despesas Operacionais
- Custo dos Produtos Vendidos (CPV)

#### Card de Lucro
- Lucro Bruto = Receita - CPV
- Lucro Líquido = Lucro Bruto - Despesas Operacionais
- Margem de Lucro = (Lucro Líquido / Receita) × 100

#### Card de Métricas Inteligentes
- Ticket Médio = Faturamento / Quantidade de Vendas
- Quantidade de Vendas
- Produto Mais Vendido (com quantidade)
- Maior Despesa do Período (com valor)

#### Card Informativo
- Explicação dos cálculos financeiros
- Ajuda o usuário a entender as métricas

---

### 4. Módulo de Produtos - Origem dos Custos

**Localização:** `lib/src/features/products/products_screen.dart`

**Melhorias:**
- Cards expansíveis para cada produto
- Indicador visual de estoque (verde = tem estoque, vermelho = sem estoque)
- Exibição de margem de lucro no card principal
- Ao expandir, mostra:
  - Preço de Venda
  - Custo Unitário
  - Lucro Unitário
  - Margem de Lucro (%)
  - Valor total em estoque
- Cores indicativas:
  - Verde: margem ≥ 30%
  - Laranja: margem < 30%

---

### 5. Integração entre Módulos

**AppStore** (`lib/src/core/app_store.dart`):

Novos métodos:
- `addExpense()` - Adiciona despesa operacional ou compra de estoque
- `getReportForPeriod()` - Calcula todas as métricas do relatório

**Cálculos implementados:**
- CPV (Custo dos Produtos Vendidos) baseado nos custos cadastrados nos produtos
- Lucro Bruto e Líquido
- Margem de Lucro
- Ticket Médio
- Produto mais vendido
- Maior despesa

---

### 6. Dashboard Atualizado

**Localização:** `lib/src/features/home/dashboard_screen.dart`

**Mudanças:**
- Adicionado módulo "Relatórios" com ícone de analytics
- Todos os módulos agora têm navegação funcional
- Reorganização visual dos cards

---

## 🎯 Fluxo de Dados

```
Produtos (custos cadastrados)
    ↓
Vendas (geram receita + calculam CPV)
    ↓
Financeiro (registra movimentações)
    ↓
Relatórios (analisa e calcula métricas)
```

---

## 📊 Exemplo de Uso

### Cenário: Venda de Açaí

1. **Cadastro no Produtos:**
   - Nome: Açaí 300ml
   - Custo: R$ 4,50
   - Preço de venda: R$ 10,00
   - Lucro unitário: R$ 5,50
   - Margem: 55%

2. **Venda registrada:**
   - Gera receita de R$ 10,00 no Financeiro
   - CPV de R$ 4,50 é calculado automaticamente

3. **Relatório mostra:**
   - Receita: R$ 10,00
   - CPV: R$ 4,50
   - Lucro Bruto: R$ 5,50
   - Se teve despesa operacional de R$ 2,00:
     - Lucro Líquido: R$ 3,50
     - Margem: 35%

---

## 🔄 Diferença entre Despesas

### Despesa Operacional
- Exemplo: Aluguel R$ 500,00
- Tipo: `expense`
- Impacto: Reduz lucro líquido diretamente
- Cor: Vermelho

### Compra de Estoque
- Exemplo: Compra de 100 potes de açaí
- Tipo: `stock`
- Impacto: Não afeta lucro imediatamente (só quando vender)
- Cor: Laranja
- Registrado como investimento em mercadoria

---

## ✨ Benefícios da Reestruturação

1. **Clareza Financeira:** Separação clara entre custos operacionais e investimento em estoque
2. **Análises Precisas:** Cálculos corretos de CPV, lucro bruto e líquido
3. **Decisões Informadas:** Métricas inteligentes ajudam o comerciante a entender o negócio
4. **Interface Profissional:** Organização clara entre visão rápida e análise detalhada
5. **Gestão de Produtos:** Visualização de margem e lucro por produto

---

## 🚀 Próximos Passos Sugeridos

Para tornar o app ainda mais profissional, considere adicionar:

1. **Gráficos:**
   - Evolução de vendas ao longo do tempo
   - Comparação entre períodos
   - Distribuição de despesas

2. **Análise Inteligente:**
   - Alertas de prejuízo
   - Sugestões de produtos com baixa margem
   - Previsão de faturamento

3. **Ranking de Produtos:**
   - Top 10 produtos mais vendidos
   - Produtos com melhor margem
   - Produtos com estoque baixo

4. **Comparação de Períodos:**
   - Hoje vs Ontem
   - Semana atual vs semana passada
   - Mês atual vs mês anterior

5. **Exportação:**
   - Relatórios em PDF
   - Planilhas Excel
   - Compartilhamento via WhatsApp
