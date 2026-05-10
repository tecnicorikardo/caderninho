# Bloquinho Digital — Documentação de API para Agente de IA

## Informações Gerais

| Item | Valor |
|------|-------|
| **Projeto Firebase** | `bloquinhodigital` |
| **Sistema Web (URL)** | https://bloquinhodigital.web.app |
| **Região das Functions** | `southamerica-east1` |
| **Base URL das Functions** | `https://southamerica-east1-bloquinhodigital.cloudfunctions.net` |
| **Autenticação** | Firebase Auth (JWT Bearer Token) |
| **Banco de Dados** | Cloud Firestore |

---

## Autenticação

Todas as chamadas autenticadas exigem um **Firebase ID Token** no header:

```
Authorization: Bearer <FIREBASE_ID_TOKEN>
```

Para obter o token via Firebase Auth:
```js
const token = await firebase.auth().currentUser.getIdToken()
```

---

## Cloud Functions (Callable)

As funções Callable são chamadas via SDK do Firebase ou via HTTP POST:

**Endpoint base:**
```
POST https://southamerica-east1-bloquinhodigital.cloudfunctions.net/<nomeDaFuncao>
```

**Headers obrigatórios:**
```
Content-Type: application/json
Authorization: Bearer <FIREBASE_ID_TOKEN>
```

**Body padrão (Callable via HTTP):**
```json
{
  "data": { ...parâmetros... }
}
```

---

### 1. `createPaymentPreference`

Cria uma preferência de pagamento no Mercado Pago para assinar um plano.

**Endpoint:**
```
POST https://southamerica-east1-bloquinhodigital.cloudfunctions.net/createPaymentPreference
```

**Requer autenticação:** Sim

**Body:**
```json
{
  "data": {
    "plan": "monthly" 
  }
}
```

**Planos disponíveis:**

| plan | Nome | Preço | Duração |
|------|------|-------|---------|
| `monthly` | Plano Mensal | R$ 29,90 | 1 mês |
| `quarterly` | Plano Trimestral | R$ 49,90 | 3 meses |
| `annual` | Plano Anual | R$ 299,90 | 12 meses |

**Resposta de sucesso:**
```json
{
  "result": {
    "preferenceId": "123456789-abc",
    "initPoint": "https://www.mercadopago.com.br/checkout/v1/redirect?pref_id=..."
  }
}
```

**Erros possíveis:**
- `unauthenticated` — usuário não autenticado
- `invalid-argument` — plano inválido
- `failed-precondition` — credenciais do Mercado Pago não configuradas
- `internal` — erro interno

---

### 2. `initializeExistingUsersSubscriptions`

Inicializa assinaturas trial para usuários que já existiam antes do sistema de assinaturas. Uso administrativo.

**Endpoint:**
```
POST https://southamerica-east1-bloquinhodigital.cloudfunctions.net/initializeExistingUsersSubscriptions
```

**Requer autenticação:** Sim (admin)

**Body:**
```json
{
  "data": {}
}
```

**Resposta de sucesso:**
```json
{
  "result": {
    "success": true,
    "initialized": 42,
    "skipped": 8,
    "message": "Initialized 42 users, skipped 8 users that already had subscriptions"
  }
}
```

---

## HTTP Endpoints (Webhook)

### 3. `mercadoPagoWebhook`

Recebe notificações de pagamento do Mercado Pago. Chamado automaticamente pelo MP após um pagamento.

**Endpoint:**
```
POST https://southamerica-east1-bloquinhodigital.cloudfunctions.net/mercadoPagoWebhook
```

**Requer autenticação:** Não (chamado pelo Mercado Pago)

**Body (enviado pelo Mercado Pago):**
```json
{
  "type": "payment",
  "action": "payment.updated",
  "data": {
    "id": "123456789"
  }
}
```

**Fluxo ao receber pagamento aprovado:**
1. Busca detalhes do pagamento na API do Mercado Pago
2. Atualiza a transação do usuário no Firestore
3. Ativa/renova a assinatura do usuário
4. Registra log em `/webhooks/{docId}`

---

## Funções Agendadas (Automáticas)

### 4. `sendPersonalEntryRemindersDaily`
- **Horário:** Todo dia às 08:00 (horário de Brasília)
- **O que faz:** Envia push notifications para usuários com lançamentos pessoais vencendo no dia
- **Coleção:** `users/{uid}/personal_entries` onde `remindersEnabled == true`

### 5. `checkSubscriptionStatus`
- **Horário:** A cada 24 horas
- **O que faz:** Verifica assinaturas expiradas e atualiza status para `expired`
- **Coleção:** `users/{uid}/subscription/current`

### 6. `sendPushFromNotificationEvents`
- **Trigger:** Criação de documento em `notification_events/{eventId}`
- **O que faz:** Envia push notification para todos os membros da loja

### 7. `initializeUserSubscription`
- **Trigger:** Criação de documento em `users/{userId}`
- **O que faz:** Cria automaticamente 2 meses de trial para novos usuários

---

## Estrutura do Firestore

### Usuário
```
users/{uid}
  ├── subscription/current          → Status da assinatura
  ├── transactions/{id}             → Histórico de pagamentos
  ├── personal_accounts/{id}        → Contas pessoais
  ├── personal_categories/{id}      → Categorias pessoais
  ├── personal_transactions/{id}    → Transações pessoais
  ├── personal_entries/{id}         → Lançamentos com lembrete
  ├── fcm_tokens/{id}               → Tokens de push notification
  └── device_tokens/{id}            → Tokens de dispositivo
```

### Assinatura (`users/{uid}/subscription/current`)
```json
{
  "plan": "monthly | quarterly | annual | free",
  "status": "trial | active | expired",
  "startDate": "2025-01-01T00:00:00.000Z",
  "expirationDate": "2025-03-01T00:00:00.000Z",
  "trialUsed": true,
  "autoRenew": false,
  "createdAt": "2025-01-01T00:00:00.000Z",
  "updatedAt": "2025-01-01T00:00:00.000Z"
}
```

### Transação Pessoal (`users/{uid}/personal_transactions/{id}`)
```json
{
  "tipo": "receita | despesa",
  "nome": "Salário",
  "categoriaId": "abc123",
  "contaId": "xyz789",
  "valor": 3500.00,
  "dataPrevista": "Timestamp",
  "dataPagamento": "Timestamp | null",
  "status": "pago | pendente",
  "recorrente": false,
  "frequencia": "mensal | semanal | anual | null",
  "parcelado": false,
  "numeroParcelas": null,
  "parcelaAtual": null,
  "notificar": false,
  "diasAntesNotificacao": null,
  "observacao": null,
  "criadoEm": "Timestamp"
}
```

### Loja (`stores/{storeId}`)
```json
{
  "ownerUid": "uid_do_dono",
  "nome": "Nome da Loja"
}
```

---

## Regras de Acesso (Resumo)

| Recurso | Leitura | Escrita |
|---------|---------|---------|
| `users/{uid}` | Público (se ativo) ou próprio usuário | Próprio usuário |
| `users/{uid}/subscription` | Próprio usuário | Apenas Functions |
| `users/{uid}/transactions` | Próprio usuário | Apenas Functions |
| `users/{uid}/*` (demais) | Próprio usuário | Próprio usuário |
| `stores/{storeId}` | Público | Dono |
| `orders/{orderId}` | Dono/membro da loja | Público (criar), Dono/membro (editar) |
| `products/{productId}` | Público | Dono/membro da loja |

---

## Exemplo de Integração com Agente de IA

### Verificar assinatura de um usuário
```
GET Firestore: users/{uid}/subscription/current
Requer: Firebase ID Token do usuário
```

### Criar preferência de pagamento
```
POST https://southamerica-east1-bloquinhodigital.cloudfunctions.net/createPaymentPreference
Headers: Authorization: Bearer <token>
Body: { "data": { "plan": "monthly" } }
```

### Listar transações pessoais
```
GET Firestore: users/{uid}/personal_transactions
Filtros disponíveis:
  - tipo == "receita" | "despesa"
  - status == "pago" | "pendente"
  - dataPrevista >= <timestamp>
  - dataPrevista <= <timestamp>
  - categoriaId == <id>
  - contaId == <id>
Ordenação: dataPrevista descending
```

---

## Links Úteis

| Recurso | URL |
|---------|-----|
| Sistema Web | https://bloquinhodigital.web.app |
| Firebase Console | https://console.firebase.google.com/project/bloquinhodigital |
| Functions Base URL | https://southamerica-east1-bloquinhodigital.cloudfunctions.net |
| Webhook MP | https://southamerica-east1-bloquinhodigital.cloudfunctions.net/mercadoPagoWebhook |
