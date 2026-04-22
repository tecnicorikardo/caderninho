# Configuração de Credenciais do Mercado Pago

Este documento explica como configurar as credenciais do Mercado Pago no Firebase Functions para o sistema de assinatura do Bloquinho Digital.

## 📋 Índice

1. [Obter Credenciais do Mercado Pago](#obter-credenciais-do-mercado-pago)
2. [Configurar no Firebase Functions](#configurar-no-firebase-functions)
3. [Configurar Localmente (Desenvolvimento)](#configurar-localmente-desenvolvimento)
4. [Verificar Configuração](#verificar-configuração)
5. [Segurança](#segurança)
6. [Troubleshooting](#troubleshooting)

---

## 🔑 Obter Credenciais do Mercado Pago

### Passo 1: Acessar o Painel do Mercado Pago

1. Acesse: https://www.mercadopago.com.br/developers/panel
2. Faça login com sua conta do Mercado Pago
3. Selecione ou crie uma aplicação

### Passo 2: Obter as Credenciais

No painel da sua aplicação, você encontrará:

- **Access Token**: Token de acesso para fazer requisições à API
- **Public Key**: Chave pública para uso no frontend
- **Client Secret**: Segredo para validar webhooks

**IMPORTANTE**: Use as credenciais de **PRODUÇÃO** para o ambiente de produção e as de **TESTE** para desenvolvimento.

---

## ⚙️ Configurar no Firebase Functions

### Método 1: Usando Firebase CLI (Recomendado para Produção)

```bash
# Instalar Firebase CLI (se ainda não tiver)
npm install -g firebase-tools

# Fazer login no Firebase
firebase login

# Configurar as credenciais
firebase functions:config:set \
  mercadopago.access_token="SEU_ACCESS_TOKEN_AQUI" \
  mercadopago.public_key="SUA_PUBLIC_KEY_AQUI" \
  mercadopago.client_secret="SEU_CLIENT_SECRET_AQUI" \
  app.base_url="https://bloquinhodigital.web.app"
```

### Exemplo com Credenciais Reais (PRODUÇÃO):

```bash
firebase functions:config:set \
  mercadopago.access_token="APP_USR-5103858731893876-030411-92514761f8a098ef418a525724240068-466908277" \
  mercadopago.public_key="APP_USR-abc96f3b-22e4-4032-aee6-b5f6e286b27c" \
  mercadopago.client_secret="3u8B8HQwEPzOiOcUnZ3ciDNkXZxrfU3p" \
  app.base_url="https://bloquinhodigital.web.app"
```

**⚠️ ATENÇÃO**: As credenciais acima são de PRODUÇÃO e devem ser renovadas periodicamente pelo proprietário do sistema.

### Verificar Configuração:

```bash
# Ver todas as configurações
firebase functions:config:get

# Ver apenas configurações do Mercado Pago
firebase functions:config:get mercadopago
```

### Fazer Deploy das Configurações:

```bash
# As configurações são aplicadas automaticamente no próximo deploy
firebase deploy --only functions
```

---

## 💻 Configurar Localmente (Desenvolvimento)

Para testar as functions localmente, você precisa criar um arquivo `.env` ou usar o emulador do Firebase.

### Opção 1: Arquivo .env (Simples)

1. Copie o arquivo de exemplo:
   ```bash
   cd functions
   cp .env.example .env
   ```

2. Edite o arquivo `.env` com suas credenciais de **TESTE**:
   ```env
   MERCADOPAGO_ACCESS_TOKEN=APP_USR-XXXXXXXX-TESTE
   MERCADOPAGO_PUBLIC_KEY=APP_USR-XXXXXXXX-TESTE
   MERCADOPAGO_CLIENT_SECRET=XXXXXXXXXXXXXXXX
   APP_BASE_URL=http://localhost:5000
   FUNCTIONS_URL=http://localhost:5001/seu-projeto/us-central1
   ```

3. **NUNCA** commite o arquivo `.env` no Git!

### Opção 2: Firebase Emulator (Recomendado)

1. Baixar configurações do Firebase para o emulador:
   ```bash
   firebase functions:config:get > .runtimeconfig.json
   ```

2. Iniciar o emulador:
   ```bash
   firebase emulators:start
   ```

3. **NUNCA** commite o arquivo `.runtimeconfig.json` no Git!

---

## ✅ Verificar Configuração

### No Firebase Console:

1. Acesse: https://console.firebase.google.com
2. Selecione seu projeto
3. Vá em **Functions** > **Configuração**
4. Verifique se as variáveis estão configuradas

### Via CLI:

```bash
firebase functions:config:get
```

Saída esperada:
```json
{
  "mercadopago": {
    "access_token": "APP_USR-...",
    "public_key": "APP_USR-...",
    "client_secret": "..."
  },
  "app": {
    "base_url": "https://bloquinhodigital.web.app"
  }
}
```

### No Código (Functions):

```typescript
import * as functions from 'firebase-functions';

// Acessar as configurações
const accessToken = functions.config().mercadopago.access_token;
const publicKey = functions.config().mercadopago.public_key;
const clientSecret = functions.config().mercadopago.client_secret;
const baseUrl = functions.config().app.base_url;
```

---

## 🔒 Segurança

### ✅ Boas Práticas:

1. **NUNCA** commite credenciais no código
2. **SEMPRE** use `.env` ou Firebase Config
3. **SEMPRE** adicione `.env` no `.gitignore`
4. **RENOVE** as credenciais periodicamente
5. **USE** credenciais de teste em desenvolvimento
6. **USE** credenciais de produção apenas em produção
7. **LIMITE** o acesso às credenciais (apenas pessoas autorizadas)

### ❌ O que NÃO fazer:

```typescript
// ❌ NUNCA faça isso!
const accessToken = "APP_USR-5103858731893876-030411-...";

// ✅ Faça isso:
const accessToken = functions.config().mercadopago.access_token;
```

### 🔐 Rotação de Credenciais:

Se você suspeitar que suas credenciais foram comprometidas:

1. Acesse o painel do Mercado Pago
2. Gere novas credenciais
3. Atualize no Firebase:
   ```bash
   firebase functions:config:set mercadopago.access_token="NOVO_TOKEN"
   ```
4. Faça deploy:
   ```bash
   firebase deploy --only functions
   ```

---

## 🐛 Troubleshooting

### Erro: "functions.config() is not a function"

**Causa**: Você está tentando usar `functions.config()` localmente sem configuração.

**Solução**:
```bash
firebase functions:config:get > .runtimeconfig.json
```

### Erro: "Invalid credentials"

**Causa**: Credenciais incorretas ou expiradas.

**Solução**:
1. Verifique se copiou as credenciais corretamente
2. Verifique se está usando credenciais de produção (não teste)
3. Gere novas credenciais no painel do Mercado Pago

### Erro: "Configuration not found"

**Causa**: Configuração não foi definida no Firebase.

**Solução**:
```bash
firebase functions:config:set mercadopago.access_token="SEU_TOKEN"
firebase deploy --only functions
```

### Como Remover uma Configuração:

```bash
firebase functions:config:unset mercadopago.access_token
```

### Como Limpar Todas as Configurações:

```bash
firebase functions:config:unset mercadopago
```

---

## 📞 Suporte

Se você tiver problemas com as credenciais ou configuração:

- **Email**: tecnicorikardo@gmail.com
- **WhatsApp**: (21) 97090-2074

---

## 📚 Referências

- [Documentação do Mercado Pago](https://www.mercadopago.com.br/developers/pt/docs)
- [Firebase Functions Config](https://firebase.google.com/docs/functions/config-env)
- [Mercado Pago SDK Node.js](https://github.com/mercadopago/sdk-nodejs)

---

## 📝 Checklist de Configuração

- [ ] Obtive as credenciais do Mercado Pago
- [ ] Configurei as credenciais no Firebase Functions
- [ ] Verifiquei a configuração com `firebase functions:config:get`
- [ ] Adicionei `.env` no `.gitignore`
- [ ] Criei arquivo `.env.example` com template
- [ ] Testei localmente com credenciais de teste
- [ ] Fiz deploy das functions com as configurações
- [ ] Documentei as credenciais em local seguro

---

**Última atualização**: 2024
**Versão**: 1.0
