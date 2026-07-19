# bloquinhodigital

PWA em React + TypeScript + Tailwind para gestao comercial.

## Stack atual

- `web/`: app PWA (Vite) hospedado no Firebase Hosting.
- `supabase/`: schema SQL, indices e politicas RLS do banco Supabase.
- `supabase/functions/mp-payment`: Edge Function para Pix EFI e ativacao do plano Pro.
- `tests/`: testes Playwright.

O Firebase fica no plano Spark e e usado apenas para Hosting. O projeto nao
depende de Firebase Functions.

## Rodar localmente

1. Configure o ambiente do frontend:

```bash
cd web
cp .env.example .env.local
```

2. Edite `web/.env.local` com:

```bash
VITE_SUPABASE_URL=https://nhrzaeteadlzvgqfqzkr.supabase.co
VITE_SUPABASE_PUBLISHABLE_KEY=sua-publishable-key
VITE_DB_PROVIDER=supabase
```

3. Instale e rode:

```bash
npm install
npm run dev
```

## Preparar Supabase

Antes de mexer em conta, projeto pausado ou keep-alive, confira:
`CONTAS_E_PROJETOS.md`.

Execute o arquivo `supabase/schema.sql` no SQL Editor do Supabase. Ele cria as
tabelas, indices, triggers de `updatedAt` e politicas RLS para isolamento por
usuario autenticado.

No frontend use apenas a publishable key. A `service_role` deve ficar somente
em ambiente de servidor, como Supabase Edge Function.

## Supabase Edge Function Pix

Configure as secrets da Edge Function antes do deploy:

```bash
SUPABASE_URL=https://nhrzaeteadlzvgqfqzkr.supabase.co
SUPABASE_SERVICE_ROLE_KEY=sua-service-role-key
SUPABASE_PROFILES_TABLE=users_profiles
EFI_CLIENT_ID=seu-client-id
EFI_CLIENT_SECRET=seu-client-secret
EFI_CERT_BASE64=seu-certificado-p12-em-base64
EFI_PIX_KEY=sua-chave-pix
APP_BASE_URL=https://bloquinhodigital.web.app
```

Guia detalhado: `CONFIGURAR_SUPABASE_EDGE_FUNCTION_PIX.md`.

## Keep-alive Supabase

O keep-alive oficial usa `cron-job.org`, porque o GitHub Actions da conta esta
bloqueado por billing e nao ha cartao disponivel. O cron externo faz um ping
gratuito no Supabase para reduzir o risco de pausa por inatividade no plano
Free.

Guia: `MANTER_SUPABASE_ATIVO.md`.

Deploy da Edge Function:

```bash
supabase functions deploy mp-payment --project-ref nhrzaeteadlzvgqfqzkr --no-verify-jwt --use-api
```

## Build e deploy

```bash
cd web
npm run build
cd ..
firebase deploy --only hosting
```
