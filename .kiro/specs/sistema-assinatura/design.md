# Design Técnico: Sistema de Assinatura Bloquinho Digital

## 1. Arquitetura Geral

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter Web/Mobile                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ Subscription │  │  Subscription │  │   Export     │      │
│  │    Screen    │  │    Banner     │  │   Service    │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│         │                  │                  │              │
│         └──────────────────┴──────────────────┘              │
│                            │                                 │
└────────────────────────────┼─────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                    Firebase Backend                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Firestore   │  │   Functions  │  │     Auth     │      │
│  │  (Database)  │  │  (Backend)   │  │   (Users)    │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│         │                  │                                 │
│         │                  ▼                                 │
│         │         ┌──────────────────┐                       │
│         │         │ Webhook Handler  │                       │
│         │         │ Payment Creator  │                       │
│         │         │ Status Checker   │                       │
│         │         └──────────────────┘                       │
└─────────┴──────────────────┼───────────────────────────────┘
                             │
                             ▼
                  ┌──────────────────────┐
                  │   Mercado Pago API   │
                  │  - Create Preference │
                  │  - Process Payment   │
                  │  - Send Webhooks     │
                  └──────────────────────┘
```

## 2. Modelo de Dados (Firestore)

### 2.1 Coleção: `users/{userId}`

```typescript
interface User {
  uid: string;
  email: string;
  createdAt: Timestamp;
  updatedAt: Timestamp;
  // ... outros campos existentes
}
```

### 2.2 Subcoleção: `users/{userId}/subscription`

```typescript
interface Subscription {
  plan: 'free' | 'monthly' | 'quarterly' | 'annual';
  status: 'active' | 'expired' | 'trial';
  startDate: Timestamp;
  expirationDate: Timestamp;
  trialUsed: boolean; // Se já usou os 2 meses grátis
  autoRenew: boolean;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}
```

**Documento único**: `users/{userId}/subscription/current`

### 2.3 Subcoleção: `users/{userId}/transactions`

```typescript
interface Transaction {
  id: string; // ID gerado pelo Firestore
  mercadoPagoId: string; // ID do pagamento no Mercado Pago
  preferenceId: string; // ID da preferência criada
  plan: 'monthly' | 'quarterly' | 'annual';
  amount: number;
  status: 'pending' | 'approved' | 'rejected' | 'cancelled';
  paymentMethod: string; // credit_card, pix, boleto
  paymentDetails?: {
    cardBrand?: string;
    lastFourDigits?: string;
  };
  externalReference: string; // user_id + plan
  createdAt: Timestamp;
  processedAt?: Timestamp;
  approvedAt?: Timestamp;
  metadata?: Record<string, any>;
}
```

### 2.4 Coleção: `webhooks` (para debug/auditoria)

```typescript
interface WebhookLog {
  id: string;
  type: string; // payment, merchant_order
  action: string; // payment.created, payment.updated
  data: any; // Payload completo do webhook
  processed: boolean;
  error?: string;
  createdAt: Timestamp;
  processedAt?: Timestamp;
}
```

## 3. Componentes Frontend (Flutter)

### 3.1 Subscription Screen

**Arquivo**: `lib/src/features/subscription/subscription_screen.dart`

```dart
class SubscriptionScreen extends StatelessWidget {
  // Exibe os 3 planos
  // Mostra status atual da assinatura
  // Botão para assinar cada plano
  // FAQ sobre assinaturas
}
```

**Widgets**:
- `PlanCard` - Card de cada plano
- `CurrentPlanBanner` - Banner mostrando plano atual
- `FAQSection` - Perguntas frequentes

### 3.2 Subscription Banner

**Arquivo**: `lib/src/features/subscription/widgets/subscription_banner.dart`

```dart
class SubscriptionBanner extends StatelessWidget {
  // Banner no topo quando faltam 5 dias ou menos
  // Banner permanente quando expirado
  // Botão para renovar
}
```

**Estados**:
- `WarningBanner` - 5 dias ou menos (amarelo)
- `ExpiredBanner` - Expirado (vermelho)
- `null` - Não exibe (mais de 5 dias)

### 3.3 Subscription Service

**Arquivo**: `lib/src/features/subscription/services/subscription_service.dart`

```dart
class SubscriptionService {
  // Verificar status da assinatura
  Future<SubscriptionStatus> checkStatus(String userId);
  
  // Criar preferência de pagamento
  Future<String> createPaymentPreference(String userId, String plan);
  
  // Verificar se pode acessar funcionalidade
  bool canAccess(String feature);
  
  // Calcular dias restantes
  int daysUntilExpiration();
}
```

### 3.4 Export Service

**Arquivo**: `lib/src/features/subscription/services/export_service.dart`

```dart
class ExportService {
  // Exportar clientes para Excel
  Future<void> exportCustomers(List<Customer> customers);
  
  // Exportar produtos para Excel
  Future<void> exportProducts(List<Product> products);
  
  // Exportar relatórios para Excel
  Future<void> exportReports(Map<String, dynamic> reportData);
}
```

### 3.5 Access Control Middleware

**Arquivo**: `lib/src/core/subscription_middleware.dart`

```dart
class SubscriptionMiddleware {
  // Verificar antes de executar ações
  Future<bool> checkAccess(String action) async {
    final status = await _subscriptionService.checkStatus();
    
    if (status.isExpired) {
      // Bloquear ações de escrita
      if (_isWriteAction(action)) {
        _showExpiredDialog();
        return false;
      }
    }
    
    return true;
  }
}
```

## 4. Backend (Firebase Functions)

### 4.1 Create Payment Preference

**Função**: `createPaymentPreference`

```typescript
export const createPaymentPreference = functions.https.onCall(
  async (data, context) => {
    // Validar autenticação
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');
    }

    const { plan } = data;
    const userId = context.auth.uid;

    // Validar plano
    const validPlans = ['monthly', 'quarterly', 'annual'];
    if (!validPlans.includes(plan)) {
      throw new functions.https.HttpsError('invalid-argument', 'Invalid plan');
    }

    // Configurar preferência
    const preference = {
      items: [{
        title: `Bloquinho Digital - ${getPlanName(plan)}`,
        description: getPlanDescription(plan),
        unit_price: getPlanPrice(plan),
        quantity: 1,
        currency_id: 'BRL'
      }],
      back_urls: {
        success: `${BASE_URL}/pagamento/sucesso`,
        failure: `${BASE_URL}/pagamento/falha`,
        pending: `${BASE_URL}/pagamento/pendente`
      },
      auto_return: 'approved',
      external_reference: `${userId}_${plan}_${Date.now()}`,
      notification_url: `${FUNCTIONS_URL}/mercadoPagoWebhook`,
      metadata: {
        user_id: userId,
        plan: plan
      }
    };

    // Criar preferência no Mercado Pago
    const mercadopago = new MercadoPagoConfig({
      accessToken: functions.config().mercadopago.access_token
    });

    const preferenceClient = new Preference(mercadopago);
    const result = await preferenceClient.create({ body: preference });

    // Salvar transação pendente
    await admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('transactions')
      .add({
        preferenceId: result.id,
        plan: plan,
        amount: getPlanPrice(plan),
        status: 'pending',
        externalReference: preference.external_reference,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });

    return {
      preferenceId: result.id,
      initPoint: result.init_point // URL para redirecionar
    };
  }
);
```

### 4.2 Webhook Handler

**Função**: `mercadoPagoWebhook`

```typescript
export const mercadoPagoWebhook = functions.https.onRequest(
  async (req, res) => {
    // Validar método
    if (req.method !== 'POST') {
      res.status(405).send('Method not allowed');
      return;
    }

    // Log do webhook
    const webhookLog = await admin.firestore()
      .collection('webhooks')
      .add({
        type: req.body.type,
        action: req.body.action,
        data: req.body,
        processed: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });

    try {
      // Processar apenas eventos de pagamento
      if (req.body.type === 'payment') {
        const paymentId = req.body.data.id;
        
        // Buscar detalhes do pagamento
        const mercadopago = new MercadoPagoConfig({
          accessToken: functions.config().mercadopago.access_token
        });
        
        const paymentClient = new Payment(mercadopago);
        const payment = await paymentClient.get({ id: paymentId });

        // Extrair informações
        const externalReference = payment.external_reference;
        const status = payment.status;
        const [userId, plan] = externalReference.split('_');

        // Atualizar transação
        const transactionQuery = await admin.firestore()
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .where('externalReference', '==', externalReference)
          .limit(1)
          .get();

        if (!transactionQuery.empty) {
          const transactionDoc = transactionQuery.docs[0];
          await transactionDoc.ref.update({
            mercadoPagoId: paymentId,
            status: status,
            paymentMethod: payment.payment_method_id,
            paymentDetails: {
              cardBrand: payment.payment_method?.issuer_id,
              lastFourDigits: payment.card?.last_four_digits
            },
            processedAt: admin.firestore.FieldValue.serverTimestamp()
          });
        }

        // Se aprovado, atualizar assinatura
        if (status === 'approved') {
          await updateSubscription(userId, plan);
        }

        // Marcar webhook como processado
        await webhookLog.update({
          processed: true,
          processedAt: admin.firestore.FieldValue.serverTimestamp()
        });
      }

      res.status(200).send('OK');
    } catch (error) {
      console.error('Error processing webhook:', error);
      
      // Salvar erro no log
      await webhookLog.update({
        error: error.message,
        processedAt: admin.firestore.FieldValue.serverTimestamp()
      });

      res.status(500).send('Error processing webhook');
    }
  }
);
```

### 4.3 Update Subscription

**Função auxiliar**: `updateSubscription`

```typescript
async function updateSubscription(userId: string, plan: string) {
  const subscriptionRef = admin.firestore()
    .collection('users')
    .doc(userId)
    .collection('subscription')
    .doc('current');

  const subscriptionDoc = await subscriptionRef.get();
  const now = admin.firestore.Timestamp.now();

  let newExpirationDate: admin.firestore.Timestamp;

  if (subscriptionDoc.exists) {
    const currentData = subscriptionDoc.data();
    const currentExpiration = currentData.expirationDate.toDate();
    
    // Se ainda não expirou, adiciona ao tempo atual
    if (currentExpiration > new Date()) {
      newExpirationDate = admin.firestore.Timestamp.fromDate(
        addMonths(currentExpiration, getPlanMonths(plan))
      );
    } else {
      // Se já expirou, começa de agora
      newExpirationDate = admin.firestore.Timestamp.fromDate(
        addMonths(new Date(), getPlanMonths(plan))
      );
    }

    await subscriptionRef.update({
      plan: plan,
      status: 'active',
      expirationDate: newExpirationDate,
      updatedAt: now
    });
  } else {
    // Primeira assinatura
    newExpirationDate = admin.firestore.Timestamp.fromDate(
      addMonths(new Date(), getPlanMonths(plan))
    );

    await subscriptionRef.set({
      plan: plan,
      status: 'active',
      startDate: now,
      expirationDate: newExpirationDate,
      trialUsed: false,
      autoRenew: false,
      createdAt: now,
      updatedAt: now
    });
  }
}
```

### 4.4 Check Subscription Status (Scheduled)

**Função**: `checkSubscriptionStatus`

```typescript
export const checkSubscriptionStatus = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    const now = new Date();
    
    // Buscar todas as assinaturas ativas
    const subscriptionsSnapshot = await admin.firestore()
      .collectionGroup('subscription')
      .where('status', '==', 'active')
      .get();

    const batch = admin.firestore().batch();
    let updatedCount = 0;

    subscriptionsSnapshot.forEach((doc) => {
      const data = doc.data();
      const expirationDate = data.expirationDate.toDate();

      // Se expirou, atualizar status
      if (expirationDate < now) {
        batch.update(doc.ref, {
          status: 'expired',
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        updatedCount++;
      }
    });

    if (updatedCount > 0) {
      await batch.commit();
      console.log(`Updated ${updatedCount} expired subscriptions`);
    }

    return null;
  });
```

### 4.5 Initialize Trial for New Users

**Função**: `initializeUserSubscription`

```typescript
export const initializeUserSubscription = functions.auth
  .user()
  .onCreate(async (user) => {
    const userId = user.uid;
    const now = admin.firestore.Timestamp.now();
    
    // Adicionar 2 meses de trial
    const expirationDate = admin.firestore.Timestamp.fromDate(
      addMonths(new Date(), 2)
    );

    await admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('subscription')
      .doc('current')
      .set({
        plan: 'free',
        status: 'trial',
        startDate: now,
        expirationDate: expirationDate,
        trialUsed: true,
        autoRenew: false,
        createdAt: now,
        updatedAt: now
      });

    console.log(`Initialized trial subscription for user ${userId}`);
  });
```

## 5. Fluxos de Dados

### 5.1 Fluxo de Assinatura

```
1. Usuário clica em "Assinar Plano Mensal"
   ↓
2. Frontend chama createPaymentPreference(userId, 'monthly')
   ↓
3. Firebase Function cria preferência no Mercado Pago
   ↓
4. Function retorna init_point (URL de pagamento)
   ↓
5. Frontend redireciona usuário para Mercado Pago
   ↓
6. Usuário completa pagamento no Mercado Pago
   ↓
7. Mercado Pago envia webhook para Firebase Function
   ↓
8. Function processa webhook e atualiza subscription
   ↓
9. Mercado Pago redireciona usuário de volta ao app
   ↓
10. App verifica status e mostra confirmação
```

### 5.2 Fluxo de Verificação de Acesso

```
1. Usuário tenta adicionar um cliente
   ↓
2. Middleware intercepta ação
   ↓
3. Verifica status da assinatura no Firestore
   ↓
4. Se ativo: Permite ação
   ↓
5. Se expirado: Bloqueia e mostra modal
```

### 5.3 Fluxo de Exportação

```
1. Usuário com assinatura expirada clica em "Exportar Clientes"
   ↓
2. App busca dados do Firestore
   ↓
3. ExportService gera arquivo Excel
   ↓
4. Inicia download do arquivo
```

## 6. Segurança

### 6.1 Regras do Firestore

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Subscription - apenas o próprio usuário pode ler
    match /users/{userId}/subscription/{doc} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if false; // Apenas Functions podem escrever
    }
    
    // Transactions - apenas o próprio usuário pode ler
    match /users/{userId}/transactions/{doc} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if false; // Apenas Functions podem escrever
    }
    
    // Webhooks - ninguém pode acessar diretamente
    match /webhooks/{doc} {
      allow read, write: if false; // Apenas Functions
    }
  }
}
```

### 6.2 Validação de Webhooks

```typescript
function validateWebhookSignature(req: functions.https.Request): boolean {
  // Mercado Pago envia header x-signature
  const signature = req.headers['x-signature'];
  const requestId = req.headers['x-request-id'];
  
  // Validar assinatura usando secret
  const secret = functions.config().mercadopago.client_secret;
  const expectedSignature = crypto
    .createHmac('sha256', secret)
    .update(requestId + req.body)
    .digest('hex');
  
  return signature === expectedSignature;
}
```

## 7. Bibliotecas Necessárias

### Frontend (Flutter)

```yaml
dependencies:
  # Mercado Pago
  url_launcher: ^6.2.0 # Para abrir URL de pagamento
  
  # Excel Export
  excel: ^4.0.0 # Para gerar arquivos Excel
  
  # Existing
  cloud_firestore: ^4.0.0
  firebase_auth: ^4.0.0
```

### Backend (Firebase Functions)

```json
{
  "dependencies": {
    "firebase-admin": "^12.0.0",
    "firebase-functions": "^5.0.0",
    "mercadopago": "^2.0.0"
  }
}
```

## 8. Variáveis de Ambiente

```bash
# Configurar no Firebase
firebase functions:config:set \
  mercadopago.access_token="APP_USR-5103858731893876-030411-92514761f8a098ef418a525724240068-466908277" \
  mercadopago.public_key="APP_USR-abc96f3b-22e4-4032-aee6-b5f6e286b27c" \
  mercadopago.client_secret="3u8B8HQwEPzOiOcUnZ3ciDNkXZxrfU3p" \
  app.base_url="https://bloquinhodigital.web.app"
```

## 9. Testes

### 9.1 Testes Unitários

- Verificação de status de assinatura
- Cálculo de dias restantes
- Validação de planos
- Geração de Excel

### 9.2 Testes de Integração

- Criação de preferência de pagamento
- Processamento de webhook
- Atualização de assinatura
- Bloqueio de funcionalidades

### 9.3 Testes End-to-End

- Fluxo completo de assinatura
- Fluxo de expiração
- Fluxo de exportação

## 10. Monitoramento

### 10.1 Logs

- Todas as transações devem ser logadas
- Webhooks devem ser salvos para auditoria
- Erros devem ser capturados e notificados

### 10.2 Métricas

- Taxa de conversão (trial → pago)
- Churn rate
- Receita recorrente mensal (MRR)
- Lifetime value (LTV)

## 11. Próximos Passos

1. Implementar modelo de dados no Firestore
2. Criar Firebase Functions
3. Desenvolver telas no Flutter
4. Implementar controle de acesso
5. Desenvolver exportação de dados
6. Testar fluxo completo
7. Deploy em produção
