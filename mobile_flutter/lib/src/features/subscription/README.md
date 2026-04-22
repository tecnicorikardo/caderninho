# Sistema de Assinatura - Bloquinho Digital

Implementação completa do sistema de assinatura com integração ao Mercado Pago.

## 📁 Estrutura de Arquivos

```
subscription/
├── models/
│   ├── subscription_model.dart    # Modelo de assinatura
│   ├── transaction_model.dart     # Modelo de transação
│   └── plan_model.dart            # Modelo de planos
├── services/
│   ├── subscription_service.dart  # Serviço de assinatura
│   └── export_service.dart        # Serviço de exportação
├── widgets/
│   └── subscription_banner.dart   # Banner de expiração
├── subscription_screen.dart       # Tela de planos
├── payment_success_screen.dart    # Tela de sucesso
├── payment_failure_screen.dart    # Tela de falha
├── payment_pending_screen.dart    # Tela de pendente
├── INTEGRATION_EXAMPLE.md         # Guia de integração
└── README.md                      # Este arquivo
```

## 🚀 Funcionalidades Implementadas

### ✅ FASE 3: Frontend Flutter

#### 1. SubscriptionService
- `checkStatus()` - Verifica status da assinatura com cache de 5 minutos
- `createPaymentPreference(plan)` - Chama Firebase Function para criar pagamento
- `canAccess(feature)` - Verifica se pode acessar funcionalidade
- `daysUntilExpiration()` - Calcula dias restantes
- `getCurrentSubscription()` - Stream da assinatura atual em tempo real

#### 2. SubscriptionScreen
- Exibe 3 planos (mensal R$ 29,90, trimestral R$ 49,90, anual R$ 299,90)
- Cards com botão "Assinar"
- Badge "Mais Popular" no trimestral
- Mostra economia nos planos trimestral e anual
- FAQ section com perguntas frequentes
- Layout responsivo (desktop: 3 colunas, mobile: empilhado)
- Mostra plano atual do usuário

#### 3. SubscriptionBanner
- WarningBanner (amarelo) - Quando faltam 5 dias ou menos
- ExpiredBanner (vermelho) - Quando expirado
- Botão "Renovar" que leva para tela de assinatura
- Mostra dias restantes
- Integrado no HomeShell

#### 4. Telas de Retorno de Pagamento
- PaymentSuccessScreen - Confirmação de pagamento aprovado
- PaymentFailureScreen - Pagamento recusado com opção de tentar novamente
- PaymentPendingScreen - Pagamento em processamento

### ✅ FASE 4: Controle de Acesso

#### SubscriptionMiddleware
- `checkAccess(action)` - Verifica antes de executar ações
- Identifica automaticamente ações de escrita vs leitura
- Bloqueia ações de escrita se expirado
- Mostra modal explicativo com opções disponíveis
- Botão "Renovar Agora" no modal

#### Ações Bloqueadas (quando expirado)
- addCustomer
- updateCustomer
- addProduct
- updateProduct
- registerSale
- addDebt
- addLoan
- addExpense
- addIncome

### ✅ FASE 5: Exportação de Dados

#### ExportService
- `exportCustomers()` - Exporta clientes para Excel
- `exportProducts()` - Exporta produtos para Excel
- `exportReports()` - Exporta relatórios para Excel
- Suporte para Web (download via blob) e Mobile (salva em documentos)
- Formatação automática de células
- Cabeçalhos e dados organizados

#### Formato de Exportação

**Clientes:**
- Nome, Telefone, Status, Data de Cadastro

**Produtos:**
- Nome, Categoria, Preço de Venda, Custo, Estoque, Unidade, Margem de Lucro

**Relatórios:**
- Aba Vendas: Data, Hora, Descrição, Cliente, Valor, Forma de Pagamento
- Aba Financeiro: Data, Tipo, Categoria, Descrição, Valor
- Aba Resumo: Total de Vendas, Receitas, Despesas, Lucro Líquido

### ✅ FASE 6: Ajustes em Configurações

#### SettingsScreen Atualizado
1. **Seção "Minha Assinatura"**
   - Mostra plano atual
   - Data de expiração
   - Status (Ativa/Expirada/Expira em X dias)
   - Botão "Gerenciar Assinatura"

2. **Seção "Exportar Dados"**
   - Botão para exportar clientes
   - Botão para exportar produtos
   - Indicador de loading durante exportação

3. **Seção "Suporte"**
   - Email: tecnicorikardo@gmail.com (com botão para abrir)
   - WhatsApp: (21) 97090-2074 (com botão para abrir)

4. **Vitrine Removida**
   - Campos de slug e status da vitrine removidos
   - Foco apenas nas configurações essenciais

## 📦 Dependências Adicionadas

```yaml
dependencies:
  cloud_functions: ^5.2.2      # Para chamar Firebase Functions
  excel: ^4.0.6                # Para gerar arquivos Excel
  path_provider: ^2.1.5        # Para salvar arquivos no mobile
  universal_html: ^2.2.4       # Para download no web
```

## 🔧 Como Usar

### 1. Verificar Status da Assinatura

```dart
final subscriptionService = SubscriptionService();
final subscription = await subscriptionService.checkStatus();

if (subscription != null && subscription.isActive) {
  // Usuário tem acesso
} else {
  // Usuário não tem acesso
}
```

### 2. Criar Pagamento

```dart
final subscriptionService = SubscriptionService();

try {
  final result = await subscriptionService.createPaymentPreference('monthly');
  final initPoint = result['initPoint'];
  
  // Abrir URL do Mercado Pago
  await launchUrl(Uri.parse(initPoint));
} catch (e) {
  print('Erro: $e');
}
```

### 3. Integrar Middleware

```dart
class _MyScreenState extends State<MyScreen> {
  final _middleware = SubscriptionMiddleware();
  
  Future<void> _addItem() async {
    final canAccess = await _middleware.checkAccess(context, 'addCustomer');
    if (!canAccess) return;
    
    // Continuar com a ação
  }
}
```

### 4. Exportar Dados

```dart
final exportService = ExportService();
final store = AppStoreScope.of(context);

// Exportar clientes
await exportService.exportCustomers(store.customers.toList());

// Exportar produtos
await exportService.exportProducts(store.products.toList());

// Exportar relatórios
await exportService.exportReports(
  sales: store.sales.toList(),
  finances: store.finances.toList(),
  startDate: DateTime(2024, 1, 1),
  endDate: DateTime.now(),
);
```

## 🎨 Componentes Visuais

### Banner de Aviso (5 dias ou menos)
- Cor: Laranja
- Ícone: warning_amber
- Mensagem: "Sua assinatura expira em X dias"
- Botão: "Renovar" (TextButton)

### Banner de Expirado
- Cor: Vermelho
- Ícone: error_outline
- Mensagem: "Assinatura expirada. Renove para continuar usando."
- Botão: "Renovar Agora" (FilledButton)

### Cards de Planos
- Elevação maior no plano popular
- Badge "MAIS POPULAR" no trimestral
- Mostra economia em verde
- Lista de funcionalidades incluídas
- Botão "Assinar" destacado

## 🔐 Segurança

- Verificação de status sempre no servidor (Firebase Functions)
- Cache local apenas para performance (5 minutos)
- Middleware valida antes de cada ação de escrita
- Dados de pagamento nunca armazenados localmente
- Integração segura com Mercado Pago

## 📱 Responsividade

- Desktop: Cards de planos em 3 colunas
- Mobile: Cards empilhados verticalmente
- Banner adapta-se à largura da tela
- Botões e textos ajustam-se automaticamente

## 🧪 Testes Recomendados

1. **Fluxo de Assinatura**
   - Criar conta nova (deve receber 2 meses grátis)
   - Assinar plano mensal
   - Verificar atualização de status
   - Verificar banner quando próximo de expirar

2. **Controle de Acesso**
   - Tentar adicionar cliente com assinatura expirada
   - Verificar modal de bloqueio
   - Confirmar que visualização ainda funciona
   - Testar exportação com assinatura expirada

3. **Exportação**
   - Exportar clientes vazios
   - Exportar clientes com dados
   - Exportar produtos
   - Exportar relatórios de diferentes períodos
   - Verificar formato do Excel gerado

4. **Integração Mercado Pago**
   - Criar preferência de pagamento
   - Redirecionar para Mercado Pago
   - Simular pagamento aprovado
   - Simular pagamento rejeitado
   - Verificar webhook (backend)

## 📝 Próximos Passos

Para completar a implementação:

1. **Integrar Middleware nas Telas**
   - Ver `INTEGRATION_EXAMPLE.md` para exemplos
   - Adicionar verificação em todas as ações de escrita
   - Testar bloqueio em cada funcionalidade

2. **Configurar Firebase Functions**
   - Implementar `createPaymentPreference`
   - Implementar `mercadoPagoWebhook`
   - Implementar `checkSubscriptionStatus` (scheduled)
   - Configurar credenciais do Mercado Pago

3. **Configurar Rotas de Retorno**
   - Adicionar rotas para success/failure/pending
   - Configurar deep links se necessário
   - Testar redirecionamento após pagamento

4. **Testes End-to-End**
   - Fluxo completo de assinatura
   - Renovação antes e depois de expirar
   - Múltiplas renovações
   - Diferentes planos

## 🐛 Troubleshooting

### Banner não aparece
- Verificar se o Stream está conectado
- Verificar se a assinatura existe no Firestore
- Verificar cálculo de dias restantes

### Exportação não funciona
- Verificar permissões de arquivo (mobile)
- Verificar se dados existem
- Verificar console do navegador (web)

### Middleware não bloqueia
- Verificar se o nome da ação está correto
- Verificar se está usando await
- Verificar status da assinatura no Firestore

### Pagamento não redireciona
- Verificar URL retornada pela Function
- Verificar configuração do url_launcher
- Verificar console para erros

## 📚 Referências

- [Mercado Pago API](https://www.mercadopago.com.br/developers)
- [Firebase Functions](https://firebase.google.com/docs/functions)
- [Excel Package](https://pub.dev/packages/excel)
- [URL Launcher](https://pub.dev/packages/url_launcher)

## 👨‍💻 Suporte

Para dúvidas ou problemas:
- Email: tecnicorikardo@gmail.com
- WhatsApp: (21) 97090-2074
