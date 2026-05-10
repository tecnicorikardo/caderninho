# Guia: Como Obter Credenciais do Mercado Pago

## Passo 0: Escolher o Tipo de Checkout

⚠️ **IMPORTANTE**: Use o **Checkout Pro** (Integração fácil)

**Por quê?**
- ✅ Mais simples de implementar
- ✅ Cliente paga no ambiente seguro do Mercado Pago
- ✅ Aceita cartão, PIX e boleto automaticamente
- ✅ Responsivo (funciona em mobile e desktop)

**NÃO use:**
- ❌ Checkout Bricks - Mais complexo, desnecessário para seu caso
- ❌ Checkout Transparente - Requer mais código e certificações

## Passo 1: Acessar o Painel do Mercado Pago

1. Acesse: https://www.mercadopago.com.br/
2. Faça login com sua conta
3. No menu superior, clique em **"Seu negócio"** ou **"Developers"**

## Passo 2: Acessar as Credenciais

1. No painel lateral, procure por **"Suas integrações"** ou **"Developers"**
2. Clique em **"Credenciais"**
3. Você verá duas abas:
   - **Credenciais de teste** (para desenvolvimento)
   - **Credenciais de produção** (para uso real)

## Passo 3: Credenciais de Teste (Para Desenvolvimento)

### O que você precisa copiar:

1. **Public Key (Chave Pública de Teste)**
   - Formato: `TEST-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`
   - Usado no frontend para criar preferências

2. **Access Token (Token de Acesso de Teste)**
   - Formato: `TEST-xxxxxxxxxxxx-xxxxxx-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx-xxxxxxxxx`
   - Usado no backend para processar pagamentos

### Como testar pagamentos:

O Mercado Pago fornece cartões de teste. Use estes dados:

**Cartão de Crédito Aprovado:**
- Número: `5031 4332 1540 6351`
- CVV: `123`
- Validade: Qualquer data futura
- Nome: Qualquer nome

**Cartão de Crédito Rejeitado:**
- Número: `5031 7557 3453 0604`
- CVV: `123`
- Validade: Qualquer data futura

## Passo 4: Credenciais de Produção (Para Uso Real)

⚠️ **IMPORTANTE**: Só use credenciais de produção quando o sistema estiver 100% testado!

### Requisitos para ativar credenciais de produção:

1. **Conta verificada**: Você precisa ter uma conta Mercado Pago verificada
2. **Dados cadastrais completos**: CPF/CNPJ, endereço, etc.
3. **Certificação de segurança**: O Mercado Pago pode solicitar informações sobre segurança do seu site

### O que você precisa copiar:

1. **Public Key (Chave Pública de Produção)**
   - Formato: `APP_USR-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`
   - Usado no frontend

2. **Access Token (Token de Acesso de Produção)**
   - Formato: `APP_USR-xxxxxxxxxxxx-xxxxxx-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx-xxxxxxxxx`
   - Usado no backend

## Passo 5: Configurar Webhooks (Notificações)

Os webhooks são essenciais para o sistema funcionar automaticamente!

### Como configurar:

1. No painel do Mercado Pago, vá em **"Webhooks"** ou **"Notificações"**
2. Clique em **"Configurar notificações"**
3. Adicione a URL do seu webhook:
   ```
   https://us-central1-bloquinhodigital.cloudfunctions.net/mercadoPagoWebhook
   ```
4. Selecione os eventos que deseja receber:
   - ✅ `payment` (Pagamento criado/atualizado)
   - ✅ `merchant_order` (Pedido criado/atualizado)

5. Salve a configuração

### Testando Webhooks Localmente:

Para testar webhooks durante desenvolvimento, use **ngrok**:

```bash
# Instalar ngrok
npm install -g ngrok

# Expor sua função local
ngrok http 5001

# Use a URL gerada (ex: https://xxxx.ngrok.io) no painel do Mercado Pago
```

## Passo 6: Onde Colocar as Credenciais no Projeto

### Opção 1: Firebase Functions Config (Recomendado)

```bash
# Configurar credenciais de teste
firebase functions:config:set mercadopago.access_token="SEU_ACCESS_TOKEN_TESTE" mercadopago.public_key="SUA_PUBLIC_KEY_TESTE"

# Configurar credenciais de produção (quando estiver pronto)
firebase functions:config:set mercadopago.access_token="SEU_ACCESS_TOKEN_PROD" mercadopago.public_key="SUA_PUBLIC_KEY_PROD"

# Ver configurações atuais
firebase functions:config:get
```

### Opção 2: Arquivo .env (Apenas para desenvolvimento local)

Crie um arquivo `.env` na pasta `functions/`:

```env
MERCADOPAGO_ACCESS_TOKEN=TEST-xxxxxxxxxxxx-xxxxxx-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx-xxxxxxxxx
MERCADOPAGO_PUBLIC_KEY=TEST-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

⚠️ **NUNCA commite o arquivo .env no Git!**

Adicione ao `.gitignore`:
```
functions/.env
```

## Passo 7: Estrutura de Preços no Mercado Pago (Checkout Pro)

Com o Checkout Pro, você cria uma "preferência de pagamento" para cada plano:

### Plano Mensal
```javascript
{
  items: [{
    title: "Bloquinho Digital - Plano Mensal",
    description: "Acesso completo por 1 mês",
    unit_price: 29.90,
    quantity: 1,
    currency_id: "BRL"
  }],
  back_urls: {
    success: "https://bloquinhodigital.web.app/pagamento/sucesso",
    failure: "https://bloquinhodigital.web.app/pagamento/falha",
    pending: "https://bloquinhodigital.web.app/pagamento/pendente"
  },
  auto_return: "approved",
  external_reference: "user_123_monthly" // ID do usuário + plano
}
```

### Plano Trimestral
```javascript
{
  items: [{
    title: "Bloquinho Digital - Plano Trimestral",
    description: "Acesso completo por 3 meses - Economize 44%",
    unit_price: 49.90,
    quantity: 1,
    currency_id: "BRL"
  }],
  back_urls: {
    success: "https://bloquinhodigital.web.app/pagamento/sucesso",
    failure: "https://bloquinhodigital.web.app/pagamento/falha",
    pending: "https://bloquinhodigital.web.app/pagamento/pendente"
  },
  auto_return: "approved",
  external_reference: "user_123_quarterly"
}
```

### Plano Anual
```javascript
{
  items: [{
    title: "Bloquinho Digital - Plano Anual",
    description: "Acesso completo por 12 meses - Economize 16%",
    unit_price: 299.90,
    quantity: 1,
    currency_id: "BRL"
  }],
  back_urls: {
    success: "https://bloquinhodigital.web.app/pagamento/sucesso",
    failure: "https://bloquinhodigital.web.app/pagamento/falha",
    pending: "https://bloquinhodigital.web.app/pagamento/pendente"
  },
  auto_return: "approved",
  external_reference: "user_123_annual"
}
```

**Importante:**
- `external_reference`: Use para identificar o usuário e o plano (ex: `user_abc123_monthly`)
- `back_urls`: URLs para onde o usuário volta após o pagamento
- `auto_return`: Retorna automaticamente quando aprovado

## Passo 8: Taxas do Mercado Pago

⚠️ **Importante saber**: O Mercado Pago cobra taxas sobre cada transação:

- **Cartão de Crédito**: ~4,99% + R$ 0,39 por transação
- **PIX**: ~0,99% por transação
- **Boleto**: ~R$ 3,49 por transação

**Exemplo de cálculo:**
- Plano Mensal: R$ 29,90
- Taxa Mercado Pago (cartão): R$ 1,88
- **Você recebe**: R$ 28,02

## Passo 9: Checklist de Segurança

Antes de ir para produção, verifique:

- [ ] Credenciais estão em variáveis de ambiente (não no código)
- [ ] Webhooks validam assinatura do Mercado Pago
- [ ] HTTPS está ativado em todas as URLs
- [ ] Logs de transações estão sendo salvos
- [ ] Tratamento de erros está implementado
- [ ] Testes com cartões de teste foram realizados
- [ ] Fluxo de pagamento foi testado end-to-end

## Passo 10: Links Úteis

- **Documentação Oficial**: https://www.mercadopago.com.br/developers/pt/docs
- **SDK Node.js**: https://github.com/mercadopago/sdk-nodejs
- **Painel de Desenvolvedores**: https://www.mercadopago.com.br/developers/panel
- **Cartões de Teste**: https://www.mercadopago.com.br/developers/pt/docs/checkout-api/testing
- **Suporte**: https://www.mercadopago.com.br/ajuda

## Próximos Passos

1. ✅ Acesse o painel do Mercado Pago
2. ✅ Copie as credenciais de TESTE
3. ✅ Configure os webhooks
4. ✅ Teste com cartões de teste
5. ⏳ Quando tudo estiver funcionando, ative credenciais de PRODUÇÃO

---

**Dúvidas?** Entre em contato:
- Email: tecnicorikardo@gmail.com
- WhatsApp: (21) 97090-2074
