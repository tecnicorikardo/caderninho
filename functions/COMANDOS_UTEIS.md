# Comandos Úteis - Firebase Functions

## 🔧 Configuração de Credenciais

### Configurar todas as credenciais de uma vez:

```bash
firebase functions:config:set \
  mercadopago.access_token="APP_USR-5103858731893876-030411-92514761f8a098ef418a525724240068-466908277" \
  mercadopago.public_key="APP_USR-abc96f3b-22e4-4032-aee6-b5f6e286b27c" \
  mercadopago.client_secret="3u8B8HQwEPzOiOcUnZ3ciDNkXZxrfU3p" \
  app.base_url="https://bloquinhodigital.web.app"
```

### Configurar uma credencial específica:

```bash
firebase functions:config:set mercadopago.access_token="NOVO_TOKEN"
```

### Ver todas as configurações:

```bash
firebase functions:config:get
```

### Ver apenas configurações do Mercado Pago:

```bash
firebase functions:config:get mercadopago
```

### Remover uma configuração:

```bash
firebase functions:config:unset mercadopago.access_token
```

### Remover todas as configurações do Mercado Pago:

```bash
firebase functions:config:unset mercadopago
```

---

## 🚀 Deploy

### Deploy de todas as functions:

```bash
npm run deploy
# ou
firebase deploy --only functions
```

### Deploy de uma function específica:

```bash
firebase deploy --only functions:createPaymentPreference
```

### Deploy com força (ignora cache):

```bash
firebase deploy --only functions --force
```

---

## 💻 Desenvolvimento Local

### Baixar configurações do Firebase:

```bash
firebase functions:config:get > .runtimeconfig.json
```

### Iniciar emulador:

```bash
npm run serve
# ou
firebase emulators:start --only functions
```

### Iniciar emulador com UI:

```bash
firebase emulators:start --only functions --ui
```

### Limpar cache do emulador:

```bash
firebase emulators:start --only functions --clear-cache
```

---

## 📊 Logs e Monitoramento

### Ver logs em tempo real:

```bash
firebase functions:log
```

### Ver logs de uma function específica:

```bash
firebase functions:log --only createPaymentPreference
```

### Ver logs com filtro:

```bash
firebase functions:log --only createPaymentPreference --lines 50
```

### Ver logs no Firebase Console:

```bash
firebase open functions:log
```

---

## 🔍 Debug

### Testar uma function localmente:

```bash
firebase functions:shell
```

Depois, no shell:
```javascript
createPaymentPreference({ plan: 'monthly' }, { auth: { uid: 'test-user-id' } })
```

### Ver informações do projeto:

```bash
firebase projects:list
firebase use
```

### Trocar de projeto:

```bash
firebase use outro-projeto
```

---

## 📦 Dependências

### Instalar dependências:

```bash
npm install
```

### Adicionar nova dependência:

```bash
npm install nome-do-pacote
```

### Atualizar dependências:

```bash
npm update
```

### Verificar dependências desatualizadas:

```bash
npm outdated
```

---

## 🧪 Testes

### Executar testes (quando implementados):

```bash
npm test
```

### Executar testes com cobertura:

```bash
npm run test:coverage
```

---

## 🔐 Segurança

### Verificar regras de segurança:

```bash
firebase deploy --only firestore:rules
```

### Testar regras localmente:

```bash
firebase emulators:start --only firestore
```

---

## 📝 Outros Comandos Úteis

### Fazer login no Firebase:

```bash
firebase login
```

### Fazer logout:

```bash
firebase logout
```

### Ver versão do Firebase CLI:

```bash
firebase --version
```

### Atualizar Firebase CLI:

```bash
npm install -g firebase-tools@latest
```

### Abrir Firebase Console:

```bash
firebase open
```

### Abrir Functions no Console:

```bash
firebase open functions
```

### Inicializar novo projeto Firebase:

```bash
firebase init
```

---

## 🐛 Troubleshooting

### Limpar cache do npm:

```bash
npm cache clean --force
rm -rf node_modules package-lock.json
npm install
```

### Reinstalar Firebase Tools:

```bash
npm uninstall -g firebase-tools
npm install -g firebase-tools
```

### Verificar status do Firebase:

```bash
firebase status
```

### Ver ajuda de um comando:

```bash
firebase functions:config:set --help
```

---

## 📞 Suporte

Se você encontrar problemas:

1. Verifique os logs: `firebase functions:log`
2. Consulte a documentação: [Firebase Docs](https://firebase.google.com/docs/functions)
3. Entre em contato:
   - **Email**: tecnicorikardo@gmail.com
   - **WhatsApp**: (21) 97090-2074

---

## 🔗 Links Úteis

- [Firebase Console](https://console.firebase.google.com)
- [Firebase CLI Reference](https://firebase.google.com/docs/cli)
- [Firebase Functions Docs](https://firebase.google.com/docs/functions)
- [Mercado Pago Docs](https://www.mercadopago.com.br/developers/pt/docs)
- [Painel Mercado Pago](https://www.mercadopago.com.br/developers/panel)
