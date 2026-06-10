# Supabase

Use `schema.sql` no SQL Editor do Supabase para criar as tabelas, indices,
triggers de `updatedAt` e politicas RLS.

O frontend usa somente `VITE_SUPABASE_URL` e `VITE_SUPABASE_PUBLISHABLE_KEY`.
Chaves `service_role` e credenciais EFI devem ficar apenas como secrets da
Supabase Edge Function `mp-payment`, nunca no bundle do browser.

## Edge Function Pix

A funcao `functions/mp-payment/index.ts` cria cobrancas Pix na EFI, recebe o
webhook de confirmacao e ativa o plano Pro em `users_profiles`.

Deploy:

```bash
supabase functions deploy mp-payment --project-ref nhrzaeteadlzvgqfqzkr --no-verify-jwt --use-api
```

Webhook EFI:

```text
https://nhrzaeteadlzvgqfqzkr.supabase.co/functions/v1/mp-payment
```
