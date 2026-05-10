# Configuração Rápida - Credenciais Mercado Pago

## 🚀 Setup Rápido (5 minutos)

### 1. Configurar no Firebase (Produção)

```bash
firebase functions:config:set \
  mercadopago.access_token="APP_USR-5103858731893876-030411-92514761f8a098ef418a525724240068-466908277" \
  mercadopago.public_key="APP_USR-abc96f3b-22e4-4032-aee6-b5f6e286b27c" \
  mercadopago.client_secret="3u8B8HQwEPzOiOcUnZ3ciDNkXZxrfU3p" \
  app.base_url="https://bloquinhodigital.web.app"
```

### 2. Verificar

```bash
firebase functions:config:get
```

### 3. Deploy

```bash
firebase deploy --only functions
```

---

## 💻 Setup Local (Desenvolvimento)

### Opção 1: Baixar do Firebase

```bash
cd functions
firebase functions:config:get > .runtimeconfig.json
firebase emulators:start
```

### Opção 2: Criar .env

```bash
cd functions
cp .env.example .env
# Edite o .env com suas credenciais de TESTE
```

---

## ⚠️ IMPORTANTE

- ✅ `.env` está no `.gitignore` (não será commitado)
- ✅ `.runtimeconfig.json` está no `.gitignore`
- ⚠️ As credenciais acima são de PRODUÇÃO
- ⚠️ Use credenciais de TESTE para desenvolvimento
- 🔄 Renove as credenciais periodicamente

---

## 📖 Documentação Completa

Para mais detalhes, consulte: `functions/CONFIGURACAO_CREDENCIAIS.md`

---

## 🔗 Links Úteis

- [Painel Mercado Pago](https://www.mercadopago.com.br/developers/panel)
- [Documentação Mercado Pago](https://www.mercadopago.com.br/developers/pt/docs)
- [Firebase Console](https://console.firebase.google.com)

---

## 📞 Suporte

- **Email**: tecnicorikardo@gmail.com
- **WhatsApp**: (21) 97090-2074
