# Modelos de Dados - Sistema de Assinatura

Este diretório contém os modelos de dados TypeScript/Dart para o sistema de assinatura do Bloquinho Digital.

## Estrutura no Firestore

### 1. Subscription (Assinatura)

**Caminho**: `users/{userId}/subscription/current`

Documento único que armazena a assinatura atual do usuário.

```dart
class SubscriptionModel {
  SubscriptionPlan plan;           // free, monthly, quarterly, annual
  SubscriptionStatus status;       // active, expired, trial
  DateTime startDate;              // Data de início da assinatura
  DateTime expirationDate;         // Data de expiração
  bool trialUsed;                  // Se já usou os 2 meses grátis
  bool autoRenew;                  // Renovação automática (futuro)
  DateTime createdAt;              // Data de criação
  DateTime updatedAt;              // Data de atualização
}
```

**Métodos úteis**:
- `isActive`: Verifica se a assinatura está ativa
- `isExpired`: Verifica se a assinatura está expirada
- `daysUntilExpiration`: Calcula quantos dias faltam para expirar
- `shouldShowWarning`: Verifica se deve mostrar aviso (5 dias ou menos)

### 2. Transaction (Transação)

**Caminho**: `users/{userId}/transactions/{transactionId}`

Coleção que armazena todas as transações de pagamento do usuário.

```dart
class TransactionModel {
  String id;                       // ID do documento Firestore
  String mercadoPagoId;            // ID do pagamento no Mercado Pago
  String preferenceId;             // ID da preferência criada
  String plan;                     // monthly, quarterly, annual
  double amount;                   // Valor pago
  TransactionStatus status;        // pending, approved, rejected, cancelled
  String paymentMethod;            // credit_card, pix, boleto
  PaymentDetails? paymentDetails;  // Detalhes do pagamento (cartão)
  String externalReference;        // Referência externa (userId_plan_timestamp)
  DateTime createdAt;              // Data de criação
  DateTime? processedAt;           // Data de processamento
  DateTime? approvedAt;            // Data de aprovação
  Map<String, dynamic>? metadata;  // Metadados adicionais
}
```

**Métodos úteis**:
- `isApproved`: Verifica se a transação foi aprovada
- `isPending`: Verifica se a transação está pendente
- `isRejected`: Verifica se a transação foi rejeitada
- `isCancelled`: Verifica se a transação foi cancelada

### 3. WebhookLog (Log de Webhook)

**Caminho**: `webhooks/{webhookId}`

Coleção global que armazena logs de todos os webhooks recebidos do Mercado Pago (para auditoria).

```dart
class WebhookLogModel {
  String id;                       // ID do documento Firestore
  String type;                     // payment, merchant_order
  String action;                   // payment.created, payment.updated
  Map<String, dynamic> data;       // Payload completo do webhook
  bool processed;                  // Se foi processado com sucesso
  String? error;                   // Mensagem de erro (se houver)
  DateTime createdAt;              // Data de recebimento
  DateTime? processedAt;           // Data de processamento
}
```

**Métodos úteis**:
- `isProcessedSuccessfully`: Verifica se foi processado sem erros
- `hasError`: Verifica se teve erro
- `isPending`: Verifica se está pendente de processamento

## Regras de Segurança

As regras do Firestore garantem que:

1. **Subscription**: Apenas o próprio usuário pode ler sua assinatura. Apenas Firebase Functions podem escrever.
2. **Transactions**: Apenas o próprio usuário pode ler suas transações. Apenas Firebase Functions podem escrever.
3. **Webhooks**: Ninguém pode acessar diretamente. Apenas Firebase Functions podem ler/escrever (para auditoria).

## Uso nos Componentes

### Leitura de Assinatura

```dart
final subscriptionDoc = await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .collection('subscription')
    .doc('current')
    .get();

final subscription = SubscriptionModel.fromDoc(subscriptionDoc);

if (subscription.isExpired) {
  // Mostrar banner de expiração
}
```

### Leitura de Transações

```dart
final transactionsSnapshot = await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .collection('transactions')
    .orderBy('createdAt', descending: true)
    .limit(10)
    .get();

final transactions = transactionsSnapshot.docs
    .map((doc) => TransactionModel.fromDoc(doc))
    .toList();
```

### Stream de Assinatura (Tempo Real)

```dart
Stream<SubscriptionModel?> subscriptionStream(String userId) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('subscription')
      .doc('current')
      .snapshots()
      .map((doc) {
        if (!doc.exists) return null;
        return SubscriptionModel.fromDoc(doc);
      });
}
```

## Planos e Preços

| Plano | Código | Preço | Duração |
|-------|--------|-------|---------|
| Gratuito | `free` | R$ 0,00 | 2 meses (trial) |
| Mensal | `monthly` | R$ 29,90 | 1 mês |
| Trimestral | `quarterly` | R$ 49,90 | 3 meses |
| Anual | `annual` | R$ 299,90 | 12 meses |

## Status de Assinatura

- **trial**: Período de teste gratuito (2 meses)
- **active**: Assinatura paga ativa
- **expired**: Assinatura expirada (sem acesso completo)

## Status de Transação

- **pending**: Pagamento pendente (aguardando confirmação)
- **approved**: Pagamento aprovado (assinatura ativada)
- **rejected**: Pagamento rejeitado (assinatura não ativada)
- **cancelled**: Pagamento cancelado pelo usuário

## Observações Importantes

1. **Documento Único**: A assinatura é sempre o documento `current` dentro da subcoleção `subscription`.
2. **Apenas Leitura**: O frontend só pode LER os dados. Toda escrita é feita pelas Firebase Functions.
3. **Validação Server-Side**: A validação de acesso deve sempre ser feita no servidor para evitar manipulação.
4. **Webhooks**: Os webhooks são processados automaticamente pelas Functions e não devem ser acessados pelo frontend.
5. **Trial**: O trial de 2 meses é concedido automaticamente na criação da conta (Firebase Function `initializeUserSubscription`).

## Próximos Passos

1. Implementar `SubscriptionService` para gerenciar lógica de negócio
2. Criar componentes de UI (banner, tela de assinatura)
3. Implementar controle de acesso baseado no status
4. Desenvolver funcionalidade de exportação de dados
