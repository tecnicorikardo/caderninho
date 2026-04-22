# Setup do Sistema de Assinatura

## 📦 Instalação de Dependências

Execute o seguinte comando no diretório `mobile_flutter`:

```bash
flutter pub get
```

Isso instalará as novas dependências:
- `cloud_functions: ^5.2.2` - Para chamar Firebase Functions
- `excel: ^4.0.6` - Para gerar arquivos Excel
- `path_provider: ^2.1.5` - Para salvar arquivos no mobile
- `universal_html: ^2.2.4` - Para download no web

## 🔧 Configuração do Firebase

### 1. Habilitar Cloud Functions

No Firebase Console:
1. Acesse "Functions" no menu lateral
2. Clique em "Começar"
3. Siga as instruções para habilitar

### 2. Configurar Credenciais do Mercado Pago

No terminal, execute:

```bash
firebase functions:config:set \
  mercadopago.access_token="APP_USR-5103858731893876-030411-92514761f8a098ef418a525724240068-466908277" \
  mercadopago.public_key="APP_USR-abc96f3b-22e4-4032-aee6-b5f6e286b27c" \
  mercadopago.client_secret="3u8B8HQwEPzOiOcUnZ3ciDNkXZxrfU3p"
```

### 3. Configurar URL Base

```bash
firebase functions:config:set \
  app.base_url="https://bloquinhodigital.web.app"
```

## 🚀 Testando a Implementação

### 1. Executar o App

```bash
cd mobile_flutter
flutter run
```

### 2. Navegar para Configurações

1. Abra o app
2. Vá para o Dashboard
3. Clique em "Configurações"
4. Você verá as novas seções:
   - Minha Assinatura
   - Exportar Dados
   - Suporte

### 3. Testar Tela de Assinatura

1. Em "Minha Assinatura", clique em "Gerenciar Assinatura"
2. Você verá os 3 planos disponíveis
3. Role até o final para ver o FAQ

### 4. Testar Banner de Expiração

Para testar o banner, você precisa modificar a data de expiração no Firestore:

1. Acesse o Firebase Console
2. Vá para Firestore Database
3. Navegue até: `users/{userId}/subscription/current`
4. Modifique o campo `expirationDate` para:
   - **5 dias no futuro** → Banner amarelo de aviso
   - **Data passada** → Banner vermelho de expirado

### 5. Testar Exportação

1. Vá para Configurações
2. Na seção "Exportar Dados"
3. Clique em "Clientes" ou "Produtos"
4. Um arquivo Excel será baixado/salvo

## 🔍 Verificando a Instalação

Execute os seguintes comandos para verificar:

```bash
# Verificar dependências
flutter pub deps

# Verificar se não há erros
flutter analyze mobile_flutter/lib/src/features/subscription/

# Executar testes (se houver)
flutter test
```

## 📱 Estrutura de Dados no Firestore

Certifique-se de que a estrutura está correta:

```
users/
  {userId}/
    subscription/
      current/
        - plan: "free" | "monthly" | "quarterly" | "annual"
        - status: "active" | "expired" | "trial"
        - startDate: Timestamp
        - expirationDate: Timestamp
        - trialUsed: boolean
        - autoRenew: boolean
        - createdAt: Timestamp
        - updatedAt: Timestamp
    transactions/
      {transactionId}/
        - mercadoPagoId: string
        - preferenceId: string
        - plan: string
        - amount: number
        - status: "pending" | "approved" | "rejected" | "cancelled"
        - paymentMethod: string
        - externalReference: string
        - createdAt: Timestamp
```

## 🔐 Regras de Segurança do Firestore

Adicione as seguintes regras no Firestore:

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
  }
}
```

## 🧪 Testando com Dados de Exemplo

Para testar sem backend, você pode criar manualmente no Firestore:

### Criar Assinatura de Teste

1. Acesse Firestore Console
2. Crie o documento: `users/{seu-user-id}/subscription/current`
3. Adicione os campos:

```json
{
  "plan": "trial",
  "status": "trial",
  "startDate": "2024-01-01T00:00:00Z",
  "expirationDate": "2024-03-01T00:00:00Z",
  "trialUsed": true,
  "autoRenew": false,
  "createdAt": "2024-01-01T00:00:00Z",
  "updatedAt": "2024-01-01T00:00:00Z"
}
```

### Testar Diferentes Estados

**Assinatura Ativa (mais de 5 dias):**
```json
{
  "expirationDate": "2024-12-31T00:00:00Z"
}
```

**Assinatura com Aviso (5 dias ou menos):**
```json
{
  "expirationDate": "2024-01-05T00:00:00Z"
}
```

**Assinatura Expirada:**
```json
{
  "expirationDate": "2023-12-01T00:00:00Z",
  "status": "expired"
}
```

## 🐛 Troubleshooting

### Erro: "MissingPluginException"

Solução:
```bash
flutter clean
flutter pub get
flutter run
```

### Erro: "Package not found"

Solução:
```bash
cd mobile_flutter
flutter pub get
```

### Banner não aparece

Verifique:
1. Se a assinatura existe no Firestore
2. Se a data de expiração está correta
3. Se o userId está correto
4. Console do Flutter para erros

### Exportação não funciona

Verifique:
1. Permissões de arquivo (mobile)
2. Se há dados para exportar
3. Console do navegador (web)

### Erro ao chamar Firebase Function

Verifique:
1. Se as Functions estão habilitadas
2. Se as credenciais estão configuradas
3. Se a Function foi deployada
4. Logs no Firebase Console

## 📚 Próximos Passos

Após a instalação e testes básicos:

1. **Implementar Backend**
   - Ver `.kiro/specs/sistema-assinatura/design.md`
   - Implementar Firebase Functions
   - Configurar webhooks do Mercado Pago

2. **Integrar Middleware**
   - Ver `lib/src/features/subscription/INTEGRATION_EXAMPLE.md`
   - Adicionar verificação nas telas existentes

3. **Configurar Rotas**
   - Adicionar rotas de retorno de pagamento
   - Configurar deep links

4. **Testes End-to-End**
   - Testar fluxo completo de assinatura
   - Testar com cartões de teste do Mercado Pago

## 📞 Suporte

Se encontrar problemas:
- Email: tecnicorikardo@gmail.com
- WhatsApp: (21) 97090-2074

## ✅ Checklist de Instalação

- [ ] Executar `flutter pub get`
- [ ] Verificar que não há erros com `flutter analyze`
- [ ] Executar o app com `flutter run`
- [ ] Navegar para Configurações
- [ ] Ver seção "Minha Assinatura"
- [ ] Ver seção "Exportar Dados"
- [ ] Ver seção "Suporte"
- [ ] Clicar em "Gerenciar Assinatura"
- [ ] Ver os 3 planos
- [ ] Criar assinatura de teste no Firestore
- [ ] Ver banner aparecer no HomeShell
- [ ] Testar exportação de dados

Quando todos os itens estiverem marcados, a instalação está completa! ✨
