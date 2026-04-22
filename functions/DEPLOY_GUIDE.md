# Guia de Deploy - Sistema de Assinatura

Este guia explica como fazer o deploy das Firebase Functions do sistema de assinatura.

## Pré-requisitos

1. Firebase CLI instalado:
```bash
npm install -g firebase-tools
```

2. Autenticado no Firebase:
```bash
firebase login
```

3. Credenciais do Mercado Pago obtidas

## Passo 1: Configurar Variáveis de Ambiente

### Opção A: Usando Firebase Functions Config (Recomendado para produção)

```bash
firebase functions:config:set \
  mercadopago.access_token="APP_USR-5103858731893876-030411-92514761f8a098ef418a525724240068-466908277" \
  mercadopago.public_key="APP_USR-abc96f3b-22e4-4032-aee6-b5f6e286b27c" \
  mercadopago.client_secret="3u8B8HQwEPzOiOcUnZ3ciDNkXZxrfU3p" \
  app.base_url="https://bloquinhodigital.web.app" \
  functions.url="https://southamerica-east1-bloquinhodigital.cloudfunctions.net"
```

### Verificar configuração:
```bash
firebase functions:config:get
```

### Opção B: Usando arquivo .env (Para desenvolvimento local)

1. Copie o arquivo de exemplo:
```bash
cd functions
cp .env.example .env
```

2. Edite `.env` com suas credenciais reais

**IMPORTANTE**: Nunca commite o arquivo `.env` no Git!

## Passo 2: Instalar Dependências

```bash
cd functions
npm install
```

## Passo 3: Testar Localmente (Opcional mas Recomendado)

### Iniciar emuladores:
```bash
firebase emulators:start --only functions,firestore,auth
```

### Testar função callable:
```javascript
// No console do navegador ou em um script de teste
const functions = firebase.functions();
const createPayment = functions.httpsCallable('createPaymentPreference');

createPayment({ plan: 'monthly' })
  .then(result => console.log(result.data))
  .catch(error => console.error(error));
```

### Testar webhook:
```bash
curl -X POST http://localhost:5001/bloquinhodigital/southamerica-east1/mercadoPagoWebhook \
  -H "Content-Type: application/json" \
  -d '{
    "type": "payment",
    "action": "payment.created",
    "data": { "id": "123456789" }
  }'
```

## Passo 4: Deploy

### Deploy todas as functions:
```bash
firebase deploy --only functions
```

### Deploy função específica:
```bash
# Deploy apenas createPaymentPreference
firebase deploy --only functions:createPaymentPreference

# Deploy apenas mercadoPagoWebhook
firebase deploy --only functions:mercadoPagoWebhook

# Deploy apenas initializeUserSubscription
firebase deploy --only functions:initializeUserSubscription

# Deploy apenas checkSubscriptionStatus
firebase deploy --only functions:checkSubscriptionStatus
```

### Deploy múltiplas functions específicas:
```bash
firebase deploy --only functions:createPaymentPreference,functions:mercadoPagoWebhook
```

## Passo 5: Verificar Deploy

### Listar functions deployadas:
```bash
firebase functions:list
```

### Ver logs em tempo real:
```bash
firebase functions:log
```

### Ver logs de função específica:
```bash
firebase functions:log --only createPaymentPreference
```

## Passo 6: Configurar Webhook no Mercado Pago

1. Acesse o painel do Mercado Pago: https://www.mercadopago.com.br/developers/panel

2. Vá em "Suas integrações" → "Webhooks"

3. Adicione a URL do webhook:
```
https://southamerica-east1-bloquinhodigital.cloudfunctions.net/mercadoPagoWebhook
```

4. Selecione os eventos:
   - ✅ Pagamentos
   - ✅ Merchant Orders (opcional)

5. Salve a configuração

## Passo 7: Atualizar Regras do Firestore

Adicione as seguintes regras no Firebase Console (Firestore → Rules):

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

## Passo 8: Testar em Produção

### 1. Criar novo usuário:
- Crie uma conta no app
- Verifique se a subscription foi criada em Firestore
- Verifique logs: `firebase functions:log --only initializeUserSubscription`

### 2. Testar criação de preferência:
```javascript
// No app ou console
const functions = firebase.functions();
const createPayment = functions.httpsCallable('createPaymentPreference');

createPayment({ plan: 'monthly' })
  .then(result => {
    console.log('Preference ID:', result.data.preferenceId);
    console.log('Payment URL:', result.data.initPoint);
    // Abrir result.data.initPoint no navegador
  });
```

### 3. Testar pagamento completo:
- Use cartão de teste do Mercado Pago
- Complete o pagamento
- Verifique se webhook foi recebido: `firebase functions:log --only mercadoPagoWebhook`
- Verifique se subscription foi atualizada no Firestore

### Cartões de teste Mercado Pago:

**Aprovado**:
- Número: 5031 4332 1540 6351
- CVV: 123
- Validade: 11/25

**Rejeitado**:
- Número: 5031 7557 3453 0604
- CVV: 123
- Validade: 11/25

## Passo 9: Configurar Monitoramento

### Alertas de erro:
1. Acesse Firebase Console → Functions → Logs
2. Configure alertas para erros críticos
3. Adicione email ou Slack para notificações

### Métricas importantes:
- Taxa de sucesso de createPaymentPreference
- Taxa de processamento de webhooks
- Quantidade de assinaturas expiradas diariamente
- Erros de integração com Mercado Pago

## Comandos Úteis

### Ver configuração atual:
```bash
firebase functions:config:get
```

### Deletar configuração:
```bash
firebase functions:config:unset mercadopago.access_token
```

### Ver logs com filtro:
```bash
firebase functions:log --only createPaymentPreference --lines 50
```

### Deletar função:
```bash
firebase functions:delete functionName
```

### Ver uso de recursos:
```bash
firebase functions:list
```

## Troubleshooting

### Erro: "Function not found"
- Verifique se o deploy foi bem-sucedido
- Verifique o nome da função
- Verifique a região (deve ser southamerica-east1)

### Erro: "Credentials not configured"
- Verifique se as variáveis de ambiente foram configuradas
- Execute: `firebase functions:config:get`
- Reconfigure se necessário

### Webhook não está sendo recebido:
- Verifique a URL no painel do Mercado Pago
- Verifique se a função está deployada
- Teste manualmente com curl
- Verifique logs de erro

### Assinatura não atualiza:
- Verifique logs do webhook
- Verifique se o pagamento foi aprovado
- Verifique se a transação existe no Firestore
- Verifique permissões do Firestore

## Rollback

Se algo der errado, você pode fazer rollback:

```bash
# Ver versões anteriores
firebase functions:list

# Fazer rollback para versão anterior
firebase functions:rollback functionName
```

## Custos Estimados

As Firebase Functions têm custo baseado em:
- Invocações
- Tempo de execução
- Memória utilizada
- Tráfego de rede

**Estimativa para 1000 usuários ativos/mês**:
- initializeUserSubscription: ~50 invocações/mês (novos usuários)
- createPaymentPreference: ~200 invocações/mês
- mercadoPagoWebhook: ~400 invocações/mês
- checkSubscriptionStatus: 30 invocações/mês (diário)

**Custo estimado**: ~$1-5 USD/mês (dentro do free tier)

## Próximos Passos

1. ✅ Deploy das functions
2. ⏳ Implementar frontend Flutter
3. ⏳ Testar fluxo completo
4. ⏳ Configurar monitoramento
5. ⏳ Documentar para equipe

## Suporte

Em caso de dúvidas ou problemas:
- Email: tecnicorikardo@gmail.com
- WhatsApp: (21) 97090-2074
- Documentação: Ver SUBSCRIPTION_FUNCTIONS.md
