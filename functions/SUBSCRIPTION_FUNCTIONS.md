# Firebase Functions - Sistema de Assinatura

Este documento descreve as Firebase Functions implementadas para o sistema de assinatura do Bloquinho Digital.

## Funções Implementadas

### 1. initializeUserSubscription

**Tipo**: `beforeUserCreated` trigger  
**Região**: `southamerica-east1`

**Descrição**: Inicializa automaticamente a assinatura de trial de 2 meses para novos usuários quando eles criam uma conta.

**Trigger**: Executada automaticamente quando um novo usuário é criado no Firebase Authentication.

**Comportamento**:
- Cria um documento em `users/{userId}/subscription/current`
- Define o plano como `free` e status como `trial`
- Adiciona 2 meses à data atual como data de expiração
- Marca `trialUsed` como `true`

**Estrutura de dados criada**:
```javascript
{
  plan: 'free',
  status: 'trial',
  startDate: Timestamp,
  expirationDate: Timestamp, // +2 meses
  trialUsed: true,
  autoRenew: false,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

**Logs**:
- Sucesso: `Initialized trial subscription for user {userId}`
- Erro: `Error initializing user subscription`

---

### 2. createPaymentPreference

**Tipo**: `onCall` (Callable function)  
**Região**: `southamerica-east1`

**Descrição**: Cria uma preferência de pagamento no Mercado Pago para o plano selecionado.

**Parâmetros de entrada**:
```javascript
{
  plan: 'monthly' | 'quarterly' | 'annual'
}
```

**Retorno**:
```javascript
{
  preferenceId: string,  // ID da preferência no Mercado Pago
  initPoint: string      // URL para redirecionar o usuário
}
```

**Validações**:
- Usuário deve estar autenticado
- Plano deve ser válido (monthly, quarterly, annual)
- Credenciais do Mercado Pago devem estar configuradas

**Comportamento**:
1. Valida autenticação e plano
2. Cria preferência no Mercado Pago com:
   - Detalhes do plano (nome, descrição, preço)
   - URLs de retorno (sucesso, falha, pendente)
   - URL de notificação (webhook)
   - Referência externa: `{userId}_{plan}_{timestamp}`
3. Salva transação pendente em `users/{userId}/transactions`
4. Retorna ID da preferência e URL de pagamento

**Planos disponíveis**:
- **monthly**: R$ 29,90 (1 mês)
- **quarterly**: R$ 49,90 (3 meses)
- **annual**: R$ 299,90 (12 meses)

**Erros**:
- `unauthenticated`: Usuário não autenticado
- `invalid-argument`: Plano inválido
- `failed-precondition`: Credenciais não configuradas
- `internal`: Erro ao criar preferência

---

### 3. mercadoPagoWebhook

**Tipo**: `onRequest` (HTTP function)  
**Região**: `southamerica-east1`

**Descrição**: Processa webhooks do Mercado Pago para atualizar status de pagamentos e assinaturas.

**Endpoint**: `https://southamerica-east1-{project-id}.cloudfunctions.net/mercadoPagoWebhook`

**Método**: POST

**Comportamento**:
1. Valida método HTTP (apenas POST)
2. Salva webhook completo em `webhooks` collection para auditoria
3. Processa apenas eventos do tipo `payment`
4. Busca detalhes do pagamento no Mercado Pago
5. Atualiza transação em `users/{userId}/transactions` com:
   - ID do pagamento
   - Status (approved, rejected, pending)
   - Método de pagamento
   - Detalhes do cartão (se aplicável)
6. Se status = `approved`, chama `updateSubscription()`
7. Marca webhook como processado

**Webhook payload esperado**:
```javascript
{
  type: 'payment',
  action: 'payment.created' | 'payment.updated',
  data: {
    id: string  // Payment ID
  }
}
```

**Logs salvos em Firestore**:
```javascript
// Collection: webhooks
{
  type: string,
  action: string,
  data: object,
  processed: boolean,
  error?: string,
  createdAt: Timestamp,
  processedAt?: Timestamp
}
```

---

### 4. updateSubscription (Helper function)

**Tipo**: Função auxiliar (não exportada)

**Descrição**: Atualiza ou cria assinatura após pagamento aprovado.

**Parâmetros**:
- `userId`: ID do usuário
- `plan`: Plano contratado (monthly, quarterly, annual)

**Comportamento**:

**Se assinatura existe**:
- Se não expirou: Adiciona meses ao final da assinatura atual
- Se expirou: Adiciona meses a partir de agora
- Atualiza `plan`, `status` (active), `expirationDate`, `updatedAt`

**Se assinatura não existe**:
- Cria nova assinatura com:
  - `plan`: Plano contratado
  - `status`: 'active'
  - `startDate`: Agora
  - `expirationDate`: Agora + meses do plano
  - `trialUsed`: false
  - `autoRenew`: false

**Exemplo de cálculo**:
```javascript
// Assinatura expira em: 2024-01-15
// Hoje: 2024-01-10
// Plano: quarterly (3 meses)
// Nova expiração: 2024-04-15 (adiciona ao final)

// Assinatura expira em: 2024-01-15
// Hoje: 2024-02-01 (já expirou)
// Plano: quarterly (3 meses)
// Nova expiração: 2024-05-01 (adiciona a partir de hoje)
```

---

### 5. checkSubscriptionStatus

**Tipo**: `onSchedule` (Scheduled function)  
**Região**: `southamerica-east1`  
**Agendamento**: A cada 24 horas (diariamente)  
**Timezone**: America/Sao_Paulo

**Descrição**: Verifica diariamente todas as assinaturas ativas e marca como expiradas se a data passou.

**Comportamento**:
1. Busca todas as assinaturas com status `active` ou `trial`
2. Para cada assinatura:
   - Verifica se `expirationDate` < data atual
   - Se expirou, atualiza `status` para `expired`
3. Usa batch write para eficiência
4. Loga quantidade de assinaturas atualizadas

**Query executada**:
```javascript
db.collectionGroup('subscription')
  .where('status', 'in', ['active', 'trial'])
  .get()
```

**Logs**:
- `No active subscriptions to check`: Nenhuma assinatura ativa
- `Updated X expired subscriptions`: X assinaturas expiradas
- `No expired subscriptions found`: Nenhuma expiração detectada

---

## Configuração de Variáveis de Ambiente

As funções utilizam as seguintes variáveis de ambiente:

```bash
MERCADOPAGO_ACCESS_TOKEN=APP_USR-...
MERCADOPAGO_PUBLIC_KEY=APP_USR-...
MERCADOPAGO_CLIENT_SECRET=...
APP_BASE_URL=https://bloquinhodigital.web.app
FUNCTIONS_URL=https://southamerica-east1-bloquinhodigital.cloudfunctions.net
```

### Como configurar:

1. Copie `.env.example` para `.env`
2. Preencha com suas credenciais do Mercado Pago
3. As variáveis serão carregadas automaticamente no emulador local

### Para produção:

Configure as variáveis no Firebase:
```bash
firebase functions:config:set \
  mercadopago.access_token="SEU_ACCESS_TOKEN" \
  mercadopago.public_key="SEU_PUBLIC_KEY" \
  mercadopago.client_secret="SEU_CLIENT_SECRET" \
  app.base_url="https://bloquinhodigital.web.app" \
  functions.url="https://southamerica-east1-bloquinhodigital.cloudfunctions.net"
```

---

## Estrutura de Dados no Firestore

### Collection: users/{userId}/subscription/current

```javascript
{
  plan: 'free' | 'monthly' | 'quarterly' | 'annual',
  status: 'trial' | 'active' | 'expired',
  startDate: Timestamp,
  expirationDate: Timestamp,
  trialUsed: boolean,
  autoRenew: boolean,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

### Collection: users/{userId}/transactions

```javascript
{
  preferenceId: string,           // ID da preferência MP
  mercadoPagoId?: string,         // ID do pagamento MP
  plan: 'monthly' | 'quarterly' | 'annual',
  amount: number,
  status: 'pending' | 'approved' | 'rejected' | 'cancelled',
  paymentMethod?: string,
  paymentDetails?: {
    cardBrand?: string,
    lastFourDigits?: string
  },
  externalReference: string,      // userId_plan_timestamp
  createdAt: Timestamp,
  processedAt?: Timestamp
}
```

### Collection: webhooks

```javascript
{
  type: string,                   // 'payment', 'merchant_order', etc
  action: string,                 // 'payment.created', 'payment.updated'
  data: object,                   // Payload completo do webhook
  processed: boolean,
  error?: string,
  createdAt: Timestamp,
  processedAt?: Timestamp
}
```

---

## Fluxo Completo de Assinatura

### 1. Novo Usuário
```
Usuário cria conta
  ↓
initializeUserSubscription (trigger automático)
  ↓
Cria subscription com 2 meses de trial
  ↓
Usuário tem acesso completo
```

### 2. Compra de Plano
```
Frontend chama createPaymentPreference({ plan: 'monthly' })
  ↓
Function cria preferência no Mercado Pago
  ↓
Retorna initPoint (URL de pagamento)
  ↓
Frontend redireciona usuário para Mercado Pago
  ↓
Usuário completa pagamento
  ↓
Mercado Pago envia webhook para mercadoPagoWebhook
  ↓
Function processa webhook e atualiza transaction
  ↓
Se aprovado, chama updateSubscription()
  ↓
Subscription é atualizada com nova data de expiração
  ↓
Mercado Pago redireciona usuário de volta ao app
```

### 3. Verificação Diária
```
checkSubscriptionStatus (executa diariamente)
  ↓
Busca todas assinaturas ativas/trial
  ↓
Verifica se expirationDate < hoje
  ↓
Atualiza status para 'expired' se necessário
```

---

## Testes

### Testar localmente com emulador:

```bash
cd functions
npm run serve
```

### Testar createPaymentPreference:

```javascript
// No frontend ou console do Firebase
const functions = firebase.functions();
const createPayment = functions.httpsCallable('createPaymentPreference');

createPayment({ plan: 'monthly' })
  .then(result => {
    console.log('Preference ID:', result.data.preferenceId);
    console.log('Payment URL:', result.data.initPoint);
  });
```

### Testar webhook localmente:

```bash
curl -X POST http://localhost:5001/bloquinhodigital/southamerica-east1/mercadoPagoWebhook \
  -H "Content-Type: application/json" \
  -d '{
    "type": "payment",
    "action": "payment.created",
    "data": {
      "id": "123456789"
    }
  }'
```

---

## Logs e Monitoramento

### Ver logs no Firebase Console:
1. Acesse Firebase Console
2. Functions → Logs
3. Filtre por função específica

### Ver logs localmente:
```bash
firebase emulators:start --only functions
# Logs aparecem no terminal
```

### Logs importantes:
- `Initialized trial subscription for user X`
- `Payment preference created`
- `Transaction updated`
- `Subscription activated after payment`
- `Updated X expired subscriptions`

---

## Troubleshooting

### Webhook não está sendo recebido:
1. Verifique se a URL do webhook está correta no Mercado Pago
2. Verifique se a function está deployada
3. Verifique logs de erro no Firebase Console
4. Teste manualmente com curl

### Assinatura não atualiza após pagamento:
1. Verifique logs do webhook
2. Verifique se o pagamento foi aprovado
3. Verifique se a transação foi encontrada no Firestore
4. Verifique se updateSubscription foi chamada

### Trial não é criado para novo usuário:
1. Verifique se a function está deployada
2. Verifique logs de erro
3. Verifique permissões do Firestore
4. Teste manualmente criando um usuário

---

## Deploy

### Deploy todas as functions:
```bash
firebase deploy --only functions
```

### Deploy função específica:
```bash
firebase deploy --only functions:createPaymentPreference
firebase deploy --only functions:mercadoPagoWebhook
firebase deploy --only functions:initializeUserSubscription
firebase deploy --only functions:checkSubscriptionStatus
```

### Verificar deploy:
```bash
firebase functions:list
```

---

## Segurança

### Regras do Firestore recomendadas:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Subscription - apenas leitura pelo próprio usuário
    match /users/{userId}/subscription/{doc} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if false; // Apenas Functions podem escrever
    }
    
    // Transactions - apenas leitura pelo próprio usuário
    match /users/{userId}/transactions/{doc} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if false; // Apenas Functions podem escrever
    }
    
    // Webhooks - ninguém pode acessar
    match /webhooks/{doc} {
      allow read, write: if false; // Apenas Functions
    }
  }
}
```

---

## Próximos Passos

1. ✅ Implementar functions backend
2. ⏳ Implementar frontend Flutter
3. ⏳ Testar fluxo completo
4. ⏳ Deploy em produção
5. ⏳ Configurar monitoramento e alertas
