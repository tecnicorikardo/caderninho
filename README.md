# Bloquinho Digital

Base nova do projeto, com foco em:

- `web`: vitrine e gestor comercial em Next.js.
- `mobile_flutter`: app Flutter (base inicial).
- `firebase`: configuração inicial para Hosting e futuras integrações.

## Estrutura

```txt
.
|- web/
|- mobile_flutter/
|- firebase.json
|- PLANO_DESENVOLVIMENTO.md
```

## Web

```bash
cd web
npm install
npm run dev
```

Copie as variaveis de ambiente:

```bash
cp .env.local.example .env.local
```

Preencha credenciais Firebase no arquivo `web/.env.local`.
Se quiser notificacoes push web (FCM), preencha tambem:
`NEXT_PUBLIC_FIREBASE_VAPID_KEY`.

Rotas principais:

- `/` dashboard inicial com `Vendas Feitas Hoje` e botao fixo `Resumo do Dia`.
- `/configuracoes` personalizacao de cores e imagem principal.
- `/operacoes` fluxo automatico de estoque/pagamento.
- `/importacao` importacao de produtos e clientes via Excel (com validacao por linha).
- `/relatorios` relatorio detalhado operacional e financeiro por periodo.
- `/vitrine` simulacao do cliente comprando no site (aceita `?slug=minha-loja`).
- Notificacoes: eventos principais geram notificacao local no navegador.
  Com FCM + VAPID configurado, o token do dispositivo e registrado em
  `users/{uid}/fcm_tokens` para envio push.

## Visualizacao Basica (modo demo)

1. `cd web`
2. `npm install`
3. `npm run dev`
4. Abra `http://localhost:3000`
5. Teste o fluxo:
6. Abra `/vitrine` e crie um pedido.
7. Abra `/operacoes` e confirme o pagamento desse pedido.
8. Veja atualizacao em `/` (resumo do dia) e `/relatorios`.

## Modo Real (Firebase existente)

1. O arquivo `web/.env.local` ja foi configurado para o projeto `bloquinhodigital`.
2. Rode `cd web && npm run build`.
3. Deploy das regras e hosting:
4. `firebase deploy --only firestore:rules,firestore:indexes,storage,hosting`

## Push em producao (Functions)

1. `cd functions`
2. `npm install`
3. `firebase deploy --only functions`

A function `sendPushFromNotificationEvents` foi criada para enviar push FCM
a partir dos eventos em `notification_events`.

## Flutter

```bash
cd mobile_flutter
flutter pub get
flutter run
```
