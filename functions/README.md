# Bloquinho Digital - Firebase Functions

Este diretório contém as Firebase Functions do Bloquinho Digital, incluindo a integração com o Mercado Pago para o sistema de assinatura.

## 📋 Configuração Inicial

### Credenciais do Mercado Pago

**IMPORTANTE**: Antes de fazer deploy ou testar localmente, você precisa configurar as credenciais do Mercado Pago.

📖 **[Guia Completo de Configuração](./CONFIGURACAO_CREDENCIAIS.md)**

### Setup Rápido

```bash
# 1. Configurar credenciais no Firebase
firebase functions:config:set \
  mercadopago.access_token="SEU_ACCESS_TOKEN" \
  mercadopago.public_key="SUA_PUBLIC_KEY" \
  mercadopago.client_secret="SEU_CLIENT_SECRET" \
  app.base_url="https://bloquinhodigital.web.app"

# 2. Instalar dependências
npm install

# 3. Testar localmente
npm run serve

# 4. Deploy
npm run deploy
```

## 🚀 Scripts Disponíveis

- `npm run serve` - Inicia o emulador local das functions
- `npm run deploy` - Faz deploy das functions para produção
- `npm run migrate:vitrine:dry` - Testa migração de vitrine (dry-run)
- `npm run migrate:vitrine` - Executa migração de vitrine

## 📁 Estrutura

```
functions/
├── src/
│   └── index.js          # Ponto de entrada das functions
├── scripts/
│   └── migrate-vitrine-fields.js
├── .env.example          # Template de variáveis de ambiente
├── .gitignore            # Arquivos ignorados pelo Git
├── CONFIGURACAO_CREDENCIAIS.md  # Guia completo de configuração
├── package.json
└── README.md             # Este arquivo
```

## 🔐 Segurança

- ✅ `.env` está no `.gitignore`
- ✅ `.runtimeconfig.json` está no `.gitignore`
- ⚠️ NUNCA commite credenciais no código
- ⚠️ Use credenciais de TESTE em desenvolvimento
- ⚠️ Use credenciais de PRODUÇÃO apenas em produção

## 📚 Documentação

- [Configuração de Credenciais](./CONFIGURACAO_CREDENCIAIS.md)
- [Firebase Functions Docs](https://firebase.google.com/docs/functions)
- [Mercado Pago Docs](https://www.mercadopago.com.br/developers/pt/docs)

## 📞 Suporte

- **Email**: tecnicorikardo@gmail.com
- **WhatsApp**: (21) 97090-2074

## 🔗 Links Úteis

- [Firebase Console](https://console.firebase.google.com)
- [Painel Mercado Pago](https://www.mercadopago.com.br/developers/panel)
