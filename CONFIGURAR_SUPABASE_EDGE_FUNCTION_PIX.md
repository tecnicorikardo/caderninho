# Configurar variaveis da Supabase Edge Function Pix

Este guia substitui a configuracao de Firebase Functions. Como o projeto esta
no Firebase Spark, o Firebase deve continuar apenas com Hosting. A criacao de
cobranca Pix, webhook da EFI e ativacao do plano Pro ficam na Supabase Edge
Function `mp-payment`.

## 1. Visao geral

Fluxo final:

```text
App no Firebase Hosting
  -> supabase.functions.invoke("mp-payment")
  -> Supabase Edge Function
  -> API Pix EFI
  -> Webhook EFI chama a mesma Edge Function
  -> Edge Function atualiza users_profiles no Supabase
```

Arquivos relacionados:

- `supabase/functions/mp-payment/index.ts`
- `supabase/config.toml`
- `supabase/schema.sql`
- `web/src/pages/PlansPage.tsx`

## 2. Variaveis necessarias

Configure estas variaveis como secrets da Supabase Edge Function:

```text
SUPABASE_URL
SUPABASE_SERVICE_ROLE_KEY
SUPABASE_PROFILES_TABLE
EFI_CLIENT_ID
EFI_CLIENT_SECRET
EFI_CERT_BASE64
EFI_CERT_PASSPHRASE
EFI_PIX_KEY
APP_BASE_URL
PAYMENT_WEBHOOK_SECRET
```

Obrigatorias:

- `SUPABASE_URL`: URL do projeto Supabase.
- `SUPABASE_SERVICE_ROLE_KEY`: chave server-side para a function atualizar o
  plano do usuario. Nunca use no frontend.
- `EFI_CLIENT_ID`: Client ID da aplicacao Pix EFI.
- `EFI_CLIENT_SECRET`: Client Secret da aplicacao Pix EFI.
- `EFI_CERT_BASE64`: certificado `.p12` da EFI convertido para Base64.
- `EFI_PIX_KEY`: chave Pix cadastrada na EFI.

Recomendadas/opcionais:

- `SUPABASE_PROFILES_TABLE`: use `users_profiles`.
- `EFI_CERT_PASSPHRASE`: senha do certificado, se o `.p12` tiver senha.
- `APP_BASE_URL`: URL publica do app, por exemplo
  `https://bloquinhodigital.web.app`.
- `PAYMENT_WEBHOOK_SECRET`: token aleatorio para proteger o webhook. Se
  configurado, adicione `?token=SEU_TOKEN` na URL do webhook da EFI.

## 3. Instalar e autenticar a Supabase CLI

Instale a CLI, se ainda nao tiver:

```bash
npm install -g supabase
```

Entre na conta:

```bash
supabase login
```

Vincule o projeto:

```bash
supabase link --project-ref nhrzaeteadlzvgqfqzkr
```

## 4. Converter o certificado EFI para Base64

No PowerShell:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\caminho\certificado.p12")) | Set-Clipboard
```

O valor fica na area de transferencia. Cole esse conteudo quando configurar
`EFI_CERT_BASE64`.

## 5. Configurar secrets

Rode os comandos abaixo a partir da raiz do projeto. Substitua os valores
`cole_aqui` pelos valores reais.

```bash
supabase secrets set SUPABASE_URL="https://nhrzaeteadlzvgqfqzkr.supabase.co"
supabase secrets set SUPABASE_SERVICE_ROLE_KEY="cole_aqui"
supabase secrets set SUPABASE_PROFILES_TABLE="users_profiles"
supabase secrets set EFI_CLIENT_ID="cole_aqui"
supabase secrets set EFI_CLIENT_SECRET="cole_aqui"
supabase secrets set EFI_CERT_BASE64="cole_aqui"
supabase secrets set EFI_CERT_PASSPHRASE=""
supabase secrets set EFI_PIX_KEY="cole_aqui"
supabase secrets set APP_BASE_URL="https://bloquinhodigital.web.app"
supabase secrets set PAYMENT_WEBHOOK_SECRET="gere_um_token_grande_e_aleatorio"
```

Para conferir os nomes configurados:

```bash
supabase secrets list
```

## 6. Aplicar o schema do banco

No painel do Supabase, abra SQL Editor e execute:

```text
supabase/schema.sql
```

Isso cria as tabelas, indices, triggers e politicas RLS.

## 7. Deploy da Edge Function

O arquivo `supabase/config.toml` define:

```toml
[functions.mp-payment]
verify_jwt = false
```

Isso e necessario porque a EFI precisa chamar o webhook sem um JWT de usuario.
A propria function valida usuario na criacao de cobranca e confirma o `txid`
com a API da EFI antes de ativar plano.

Deploy:

```bash
supabase functions deploy mp-payment --project-ref nhrzaeteadlzvgqfqzkr --no-verify-jwt --use-api
```

URL publica:

```text
https://nhrzaeteadlzvgqfqzkr.supabase.co/functions/v1/mp-payment
```

Se `PAYMENT_WEBHOOK_SECRET` estiver configurado, use:

```text
https://nhrzaeteadlzvgqfqzkr.supabase.co/functions/v1/mp-payment?token=SEU_TOKEN
```

## 8. Configurar webhook na EFI

No painel EFI, configure o webhook Pix para apontar para a URL publica da Edge
Function:

```text
https://nhrzaeteadlzvgqfqzkr.supabase.co/functions/v1/mp-payment
```

Com token opcional:

```text
https://nhrzaeteadlzvgqfqzkr.supabase.co/functions/v1/mp-payment?token=SEU_TOKEN
```

## 9. Configurar frontend

No arquivo `web/.env.local`, mantenha apenas variaveis publicas:

```text
VITE_SUPABASE_URL=https://nhrzaeteadlzvgqfqzkr.supabase.co
VITE_SUPABASE_PUBLISHABLE_KEY=sua_publishable_key
VITE_DB_PROVIDER=supabase
```

Nao configure `SUPABASE_SERVICE_ROLE_KEY`, `EFI_CLIENT_SECRET` ou
`EFI_CERT_BASE64` no frontend.

## 10. Deploy no Firebase Spark

Agora o deploy do Firebase e somente Hosting:

```bash
cd web
npm install
npm run build
cd ..
firebase deploy --only hosting
```

Nao use:

```bash
firebase deploy --only functions
firebase deploy --only hosting,functions
```

## 11. Testes recomendados

Antes do deploy:

```bash
cd web
npm run typecheck
npm run build
```

Depois do deploy da Edge Function:

```bash
supabase functions list --project-ref nhrzaeteadlzvgqfqzkr
```

Para logs, use o painel da Supabase em Edge Functions > `mp-payment` > Logs.

Teste manual:

1. Acesse o app publicado no Firebase Hosting.
2. Entre com um usuario Supabase.
3. Abra a tela de Planos.
4. Gere um Pix.
5. Pague em ambiente de teste ou producao conforme credenciais EFI usadas.
6. Confira se `users_profiles.planStatus` mudou para `pro`.
7. Confira se `users_profiles.planExpiresAt` foi preenchido.

## 12. Checklist

- `supabase/schema.sql` executado.
- Secrets configuradas no Supabase.
- `supabase functions deploy mp-payment` concluido.
- Webhook Pix EFI apontando para a Edge Function.
- `web/.env.local` contem somente variaveis publicas.
- `npm run typecheck` passou.
- `npm run build` passou.
- `firebase deploy --only hosting` concluido.

## 13. Seguranca

As chaves enviadas em conversa ou copiadas para lugares visiveis devem ser
rotacionadas no painel do Supabase/EFI. A `SUPABASE_SERVICE_ROLE_KEY` ignora
RLS e deve existir somente em ambiente de servidor, como secret da Edge
Function.
