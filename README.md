# bloquinhodigital

PWA em React + TypeScript + Tailwind para gestao comercial.

## Stack atual

- `web/`: app PWA (Vite) hospedado no Firebase Hosting.
- `supabase/`: schema SQL, indices e politicas RLS do banco Supabase.
- `functions/`: Firebase Functions usadas pelo fluxo Pix/planos.
- `tests/`: testes Playwright.

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
VITE_PAYMENT_FUNCTION_URL=https://southamerica-east1-bloquinhodigital.cloudfunctions.net/mpPayment
```

3. Instale e rode:

```bash
npm install
npm run dev
```

## Preparar Supabase

Execute o arquivo `supabase/schema.sql` no SQL Editor do Supabase. Ele cria as
tabelas, indices, triggers de `updatedAt` e politicas RLS para isolamento por
usuario autenticado.

No frontend use apenas a publishable key. A `service_role` deve ficar somente
em ambiente de servidor, como Firebase Functions.

## Firebase Functions

Configure as variaveis de servidor antes do deploy:

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

## Build e deploy

```bash
cd web
npm run build
cd ..
firebase deploy --only hosting,functions
```
