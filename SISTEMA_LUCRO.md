# 💰 Sistema de Cálculo de Lucro - Caderninho do Comerciante

## 🎯 **Visão Geral**

Implementamos um sistema completo de cálculo de lucro real que permite ao comerciante entender exatamente quanto está ganhando com cada produto vendido.

## ✅ **Funcionalidades Implementadas**

### 1. **Campos de Custo nos Produtos**
- ✅ `custoUnitario` - Custo por unidade do produto
- ✅ `categoria` - Para agrupar produtos similares
- ✅ `fornecedor` - Para rastreamento
- ✅ `dataUltimaCompra` - Para controle de custos

### 2. **Cálculos Automáticos**
- ✅ **Lucro Unitário** = Preço de Venda - Custo Unitário
- ✅ **Margem de Lucro (%)** = (Lucro Unitário / Preço de Venda) × 100
- ✅ **Lucro Total do Estoque** = Lucro Unitário × Quantidade em Estoque

### 3. **Relatórios de Lucro**
- ✅ Lucro por período (hoje, mês, personalizado)
- ✅ Análise por produto
- ✅ Análise por categoria
- ✅ Produtos mais lucrativos
- ✅ Produtos com problemas (baixo lucro)
- ✅ Margem de lucro média

## 📊 **Como Funciona**

### **Exemplo Prático: Açaí 300ml**

```
📦 Produto: Açaí 300ml
💰 Preço de Venda: R$ 12,00
💸 Custo Unitário: R$ 5,50
📈 Lucro Unitário: R$ 6,50
📊 Margem de Lucro: 54,2%
```

### **Cálculo Automático na Venda**
Quando você vende 10 unidades:
```
🛒 Quantidade Vendida: 10
💰 Total de Vendas: 10 × R$ 12,00 = R$ 120,00
💸 Total de Custos: 10 × R$ 5,50 = R$ 55,00
📈 Lucro Total: R$ 120,00 - R$ 55,00 = R$ 65,00
```

## 🎨 **Interface do Sistema**

### **1. Tela de Estoque - Nova Aba "Relatório de Lucro"**

#### **Seletor de Período**
- Escolha o período para análise
- Botão de atualização
- Período padrão: últimos 30 dias

#### **Resumo do Período**
- **Lucro Total**: Soma de todos os lucros do período
- **Margem Média**: Percentual médio de lucro

#### **Lista de Produtos com Lucro**
Para cada produto mostra:
- ✅ Nome do produto
- ✅ Categoria
- ✅ Quantidade vendida
- ✅ Total de vendas
- ✅ Total de custos
- ✅ Lucro total
- ✅ Lucro médio por unidade
- ✅ Margem de lucro (%)

### **2. Tela de Estoque - Nova Aba "Análise"**

#### **Produtos Mais Lucrativos**
- Lista dos produtos que geraram mais lucro
- Ordenados por lucro total decrescente
- Mostra categoria e lucro total

#### **Produtos com Problemas**
- Produtos com menor lucro ou prejuízo
- Ajuda a identificar produtos que precisam de ajuste
- Mostra categoria e lucro total

#### **Análise por Categoria**
- Agrupa produtos por categoria
- Mostra lucro total por categoria
- Calcula margem média por categoria

## 🔧 **Como Configurar**

### **1. Adicionar Custo aos Produtos**

Ao cadastrar ou editar um produto:

```dart
Produto(
  nome: 'Açaí 300ml',
  preco: 12.00,
  custoUnitario: 5.50, // ✅ NOVO CAMPO
  categoria: 'Bebidas',
  fornecedor: 'Fornecedor A',
  unidade: 'unidade',
  quantidadeEstoque: 50,
)
```

### **2. Atualizar Produtos Existentes**

Para produtos já cadastrados sem custo:

1. Vá em **Estoque** → **Produtos**
2. Edite cada produto
3. Adicione o campo **Custo Unitário**
4. Salve as alterações

### **3. Importar Custos de Compras**

O sistema pode automaticamente atualizar custos baseado nas compras:

```dart
// Quando registrar uma compra
await atualizarCustoProduto(
  produtoId: 'produto_id',
  novoCusto: valorUnitarioCompra,
  dataCompra: DateTime.now(),
);
```

## 📈 **Relatórios Disponíveis**

### **1. Relatório de Lucro por Produto**
```
📊 Exemplo de Saída:
┌─────────────────┬──────────┬──────────┬──────────┬──────────┐
│ Produto         │ Qtd Vend │ Vendas   │ Custos   │ Lucro    │
├─────────────────┼──────────┼──────────┼──────────┼──────────┤
│ Açaí 300ml      │ 150      │ R$ 1.800 │ R$ 825   │ R$ 975   │
│ Açaí 500ml      │ 80       │ R$ 1.200 │ R$ 600   │ R$ 600   │
│ Tapioca         │ 200      │ R$ 1.000 │ R$ 400   │ R$ 600   │
└─────────────────┴──────────┴──────────┴──────────┴──────────┘
```

### **2. Relatório por Categoria**
```
📊 Exemplo de Saída:
┌──────────────┬──────────┬──────────┬──────────┬──────────┐
│ Categoria    │ Produtos │ Vendas   │ Custos   │ Lucro    │
├──────────────┼──────────┼──────────┼──────────┼──────────┤
│ Bebidas      │ 5        │ R$ 3.000 │ R$ 1.425 │ R$ 1.575 │
│ Salgados     │ 8        │ R$ 2.500 │ R$ 1.200 │ R$ 1.300 │
│ Doces        │ 3        │ R$ 1.800 │ R$ 900   │ R$ 900   │
└──────────────┴──────────┴──────────┴──────────┴──────────┘
```

### **3. Análise de Rentabilidade**
```
📊 Produtos Mais Lucrativos:
1. Açaí 300ml - R$ 975 (54,2%)
2. Tapioca - R$ 600 (60,0%)
3. Açaí 500ml - R$ 600 (50,0%)

📊 Produtos com Problemas:
1. Refrigerante - R$ 50 (10,0%)
2. Água - R$ 20 (25,0%)
3. Salgadinho - R$ 15 (15,0%)
```

## 🎯 **Benefícios do Sistema**

### **Para o Comerciante:**
- ✅ **Visibilidade Total**: Sabe exatamente quanto ganha com cada produto
- ✅ **Tomada de Decisão**: Identifica produtos mais e menos rentáveis
- ✅ **Otimização de Preços**: Ajusta preços baseado na rentabilidade
- ✅ **Controle de Custos**: Monitora variações nos custos
- ✅ **Planejamento**: Planeja compras baseado na lucratividade

### **Para o Negócio:**
- ✅ **Aumento de Lucro**: Foca nos produtos mais rentáveis
- ✅ **Redução de Perdas**: Identifica produtos problemáticos
- ✅ **Eficiência**: Otimiza o mix de produtos
- ✅ **Crescimento**: Base de dados para expansão

## 🚀 **Próximos Passos**

### **Fase 2 - Melhorias Planejadas:**
1. **Integração com Compras**: Atualizar custos automaticamente
2. **Histórico de Custos**: Rastrear variações ao longo do tempo
3. **Alertas**: Notificar quando custos aumentam significativamente
4. **Comparação Períodos**: Análise mês a mês
5. **Exportação**: Relatórios em PDF/Excel
6. **Dashboard**: Gráficos e visualizações
7. **Meta de Lucro**: Definir e acompanhar metas por produto

### **Fase 3 - Recursos Avançados:**
1. **Custos Variáveis**: Custos que variam com a quantidade
2. **Custos Fixos**: Distribuição de custos fixos por produto
3. **Análise de Sazonalidade**: Lucro por período do ano
4. **Previsão de Lucro**: Baseado em histórico
5. **Integração com Fornecedores**: Custos em tempo real

## 💡 **Dicas de Uso**

### **1. Configure Custos Realistas**
- Inclua todos os custos (matéria-prima, embalagem, etc.)
- Atualize custos regularmente
- Considere custos indiretos quando relevante

### **2. Analise Regularmente**
- Verifique relatórios semanalmente
- Identifique tendências
- Ajuste preços quando necessário

### **3. Use as Categorias**
- Agrupe produtos similares
- Compare rentabilidade entre categorias
- Identifique categorias mais lucrativas

### **4. Monitore Produtos Problemáticos**
- Produtos com baixa margem podem precisar de ajuste
- Considere aumentar preços ou reduzir custos
- Avalie se vale manter no mix

## 🎉 **Conclusão**

O sistema de cálculo de lucro transforma seu app de um simples controle de estoque em uma ferramenta poderosa de gestão financeira. Agora você tem visibilidade total sobre a rentabilidade do seu negócio e pode tomar decisões baseadas em dados reais.

**Resultado Esperado**: Aumento significativo na lucratividade através de decisões mais informadas sobre preços, produtos e estratégias de venda.

---

*Sistema implementado em: ${DateTime.now().toString()}*
*Versão: 1.0.0* 