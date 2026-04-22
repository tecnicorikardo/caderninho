# Guia de Testes - Sistema de Assinatura

Este guia fornece instruções detalhadas para testar todas as funcionalidades do sistema de assinatura.

## Configuração Inicial

### 1. Iniciar Emuladores Locais

```bash
cd functions
firebase emulators:start --only functions,firestore,auth
```

Isso iniciará:
- Functions: http://localhost:5001
- Firestore: http://localhost:8080
- Auth: http://localhost:9099

### 2. Configurar Variáveis de Ambiente

Certifique-se de ter o arquivo `.env` configurado:

```bash
cp .env.example .env
# Edite .env com suas credenciais de teste do Mercado Pago
```

## Testes Unitários

### Teste 1: Inicialização de Trial para Novo Usuário

**Objetivo**: Verificar se novos usuários recebem 2 meses de trial automaticamente.

**Passos**:
1. Crie um novo usuário no Firebase Auth
2. Verifique se o documento foi criado em `users/{userId}/subscription/current`
3. Verifique os campos:
   - `plan` = 'free'
   - `status` = 'trial'
   - `expirationDate` = hoje + 2 meses
   - `trialUsed` = true

**Comando de teste**:
```javascript
// No console do Firebase ou em um script
const auth = firebase.auth();
auth.createUserWithEmailAndPassword('teste@example.com', 'senha123')
  .then(userCredential => {
    const userId = userCredential.user.uid;
    console.log('User created:', userId);
    
    // Aguardar 2 segundos para a function executar
    setTimeout(() => {
      firebase.firestore()
        .collection('users')
        .doc(userId)
        .collection('subscription')
        .doc('current')
        .get()
        .then(doc => {
          console.log('Subscription:', doc.data());
        });
    }, 2000);
  });
```

**Resultado esperado**:
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

---

### Teste 2: Criar Preferência de Pagamento

**Objetivo**: Verificar se a preferência é criada corretamente no Mercado Pago.

**Passos**:
1. Autentique um usuário
2. Chame a função `createPaymentPreference` com um plano
3. Verifique o retorno (preferenceId e initPoint)
4. Verifique se a transação foi salva no Firestore

**Código de teste**:
```javascript
const functions = firebase.functions();
const createPayment = functions.httpsCallable('createPaymentPreference');

// Testar plano mensal
createPayment({ plan: 'monthly' })
  .then(result => {
    console.log('Success!');
    console.log('Preference ID:', result.data.preferenceId);
    console.log('Payment URL:', result.data.initPoint);
    
    // Verificar transação no Firestore
    const userId = firebase.auth().currentUser.uid;
    firebase.firestore()
      .collection('users')
      .doc(userId)
      .collection('transactions')
      .where('preferenceId', '==', result.data.preferenceId)
      .get()
      .then(snapshot => {
        console.log('Transaction:', snapshot.docs[0].data());
      });
  })
  .catch(error => {
    console.error('Error:', error);
  });
```

**Resultado esperado**:
```javascript
{
  preferenceId: 'XXXXXXXXX',
  initPoint: 'https://www.mercadopago.com.br/checkout/v1/redirect?pref_id=XXXXXXXXX'
}

// Transaction no Firestore:
{
  preferenceId: 'XXXXXXXXX',
  plan: 'monthly',
  amount: 29.90,
  status: 'pending',
  externalReference: 'userId_monthly_timestamp',
  createdAt: Timestamp
}
```

**Testar todos os planos**:
```javascript
// Mensal
createPayment({ plan: 'monthly' });

// Trimestral
createPayment({ plan: 'quarterly' });

// Anual
createPayment({ plan: 'annual' });
```

**Testar validações**:
```javascript
// Plano inválido (deve retornar erro)
createPayment({ plan: 'invalid' })
  .catch(error => {
    console.log('Expected error:', error.message);
  });

// Sem autenticação (deve retornar erro)
firebase.auth().signOut();
createPayment({ plan: 'monthly' })
  .catch(error => {
    console.log('Expected error:', error.message);
  });
```

---

### Teste 3: Processar Webhook do Mercado Pago

**Objetivo**: Verificar se o webhook processa pagamentos corretamente.

**Passos**:
1. Simule um webhook de pagamento aprovado
2. Verifique se a transação foi atualizada
3. Verifique se a assinatura foi atualizada

**Comando de teste**:
```bash
# Webhook de pagamento aprovado
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

**NOTA**: Para testar completamente, você precisará:
1. Criar uma preferência real
2. Fazer um pagamento de teste no Mercado Pago
3. Aguardar o webhook real

**Verificar logs**:
```bash
firebase functions:log --only mercadoPagoWebhook
```

**Verificar no Firestore**:
- Collection `webhooks`: Deve ter um documento com o webhook
- Collection `users/{userId}/transactions`: Status deve ser 'approved'
- Collection `users/{userId}/subscription/current`: Data de expiração deve ser atualizada

---

### Teste 4: Atualização de Assinatura

**Objetivo**: Verificar se a assinatura é atualizada corretamente após pagamento.

**Cenário 1: Assinatura ainda ativa**
```javascript
// Assinatura atual expira em: 2024-06-01
// Compra plano mensal hoje (2024-05-15)
// Nova expiração deve ser: 2024-07-01 (adiciona 1 mês ao final)
```

**Cenário 2: Assinatura expirada**
```javascript
// Assinatura expirou em: 2024-04-01
// Compra plano mensal hoje (2024-05-15)
// Nova expiração deve ser: 2024-06-15 (adiciona 1 mês a partir de hoje)
```

**Teste manual**:
1. Crie uma assinatura com data de expiração específica
2. Simule um pagamento aprovado
3. Verifique se a data foi calculada corretamente

---

### Teste 5: Verificação Agendada de Assinaturas

**Objetivo**: Verificar se assinaturas expiradas são marcadas corretamente.

**Preparação**:
1. Crie assinaturas de teste com datas de expiração no passado
2. Execute a função manualmente

**Executar manualmente**:
```bash
# No emulador, a função agendada não executa automaticamente
# Você pode chamá-la manualmente via HTTP ou criar um script
```

**Script de teste**:
```javascript
// Criar assinatura expirada para teste
const userId = 'test-user-id';
firebase.firestore()
  .collection('users')
  .doc(userId)
  .collection('subscription')
  .doc('current')
  .set({
    plan: 'monthly',
    status: 'active',
    startDate: firebase.firestore.Timestamp.fromDate(new Date('2024-01-01')),
    expirationDate: firebase.firestore.Timestamp.fromDate(new Date('2024-02-01')),
    trialUsed: true,
    autoRenew: false,
    createdAt: firebase.firestore.Timestamp.now(),
    updatedAt: firebase.firestore.Timestamp.now()
  })
  .then(() => {
    console.log('Test subscription created');
    // Agora execute checkSubscriptionStatus manualmente
  });
```

**Verificar resultado**:
- Status deve mudar de 'active' para 'expired'

---

## Testes de Integração

### Fluxo Completo: Novo Usuário → Trial → Compra → Renovação

**Passo 1: Criar novo usuário**
```javascript
firebase.auth().createUserWithEmailAndPassword('teste@example.com', 'senha123');
```

**Passo 2: Verificar trial**
```javascript
// Aguardar 2 segundos
const userId = firebase.auth().currentUser.uid;
firebase.firestore()
  .collection('users')
  .doc(userId)
  .collection('subscription')
  .doc('current')
  .get()
  .then(doc => {
    console.log('Trial:', doc.data());
    // Deve ter 2 meses de trial
  });
```

**Passo 3: Criar preferência de pagamento**
```javascript
const functions = firebase.functions();
const createPayment = functions.httpsCallable('createPaymentPreference');

createPayment({ plan: 'monthly' })
  .then(result => {
    console.log('Payment URL:', result.data.initPoint);
    // Abrir URL no navegador e completar pagamento
  });
```

**Passo 4: Completar pagamento**
- Abra a URL retornada
- Use cartão de teste do Mercado Pago
- Complete o pagamento

**Passo 5: Verificar atualização**
```javascript
// Aguardar webhook ser processado (alguns segundos)
firebase.firestore()
  .collection('users')
  .doc(userId)
  .collection('subscription')
  .doc('current')
  .get()
  .then(doc => {
    console.log('Updated subscription:', doc.data());
    // Data de expiração deve ter sido estendida
  });
```

---

## Testes de Cartão (Mercado Pago)

### Cartões de Teste

**Aprovado**:
```
Número: 5031 4332 1540 6351
CVV: 123
Validade: 11/25
Nome: APRO
```

**Rejeitado**:
```
Número: 5031 7557 3453 0604
CVV: 123
Validade: 11/25
Nome: OTHE
```

**Pendente**:
```
Número: 5031 4332 1540 6351
CVV: 123
Validade: 11/25
Nome: PEND
```

---

## Checklist de Testes

### Fase 1.3: Inicialização de Trial
- [ ] Novo usuário recebe 2 meses de trial
- [ ] Subscription é criada com status 'trial'
- [ ] Data de expiração é calculada corretamente
- [ ] Logs são gerados corretamente

### Fase 2.2: Criar Preferência de Pagamento
- [ ] Preferência é criada no Mercado Pago
- [ ] Transação pendente é salva no Firestore
- [ ] initPoint é retornado corretamente
- [ ] Validação de autenticação funciona
- [ ] Validação de plano funciona
- [ ] Erro é retornado se credenciais não configuradas

### Fase 2.3: Webhook Handler
- [ ] Webhook é recebido e salvo em 'webhooks'
- [ ] Detalhes do pagamento são buscados no MP
- [ ] Transação é atualizada no Firestore
- [ ] updateSubscription é chamada se aprovado
- [ ] Erros são logados corretamente

### Fase 2.4: Atualizar Assinatura
- [ ] Assinatura ativa: adiciona meses ao final
- [ ] Assinatura expirada: adiciona meses a partir de hoje
- [ ] Nova assinatura: cria com data correta
- [ ] Logs são gerados corretamente

### Fase 2.5: Verificação Agendada
- [ ] Assinaturas expiradas são detectadas
- [ ] Status é atualizado para 'expired'
- [ ] Batch write funciona corretamente
- [ ] Logs são gerados corretamente

---

## Ferramentas de Teste

### Firebase Emulator UI
Acesse: http://localhost:4000

- Visualize dados do Firestore
- Visualize logs das functions
- Visualize usuários do Auth

### Postman/Insomnia
Importe a collection para testar webhooks:

```json
{
  "name": "Mercado Pago Webhook",
  "request": {
    "method": "POST",
    "url": "http://localhost:5001/bloquinhodigital/southamerica-east1/mercadoPagoWebhook",
    "header": [
      {
        "key": "Content-Type",
        "value": "application/json"
      }
    ],
    "body": {
      "mode": "raw",
      "raw": "{\n  \"type\": \"payment\",\n  \"action\": \"payment.created\",\n  \"data\": {\n    \"id\": \"123456789\"\n  }\n}"
    }
  }
}
```

---

## Troubleshooting

### Erro: "User not authenticated"
- Certifique-se de estar autenticado antes de chamar a função
- Verifique se o token não expirou

### Erro: "Invalid plan"
- Verifique se o plano é 'monthly', 'quarterly' ou 'annual'
- Verifique se não há espaços ou caracteres extras

### Erro: "Credentials not configured"
- Verifique se o arquivo .env existe
- Verifique se as variáveis estão corretas
- Reinicie os emuladores

### Webhook não é processado
- Verifique se a URL está correta
- Verifique se o método é POST
- Verifique logs de erro
- Verifique se o payment ID existe no Mercado Pago

---

## Próximos Passos

Após completar todos os testes:
1. ✅ Testar localmente
2. ⏳ Deploy em produção
3. ⏳ Testar em produção com cartões de teste
4. ⏳ Implementar frontend Flutter
5. ⏳ Testar fluxo completo end-to-end
