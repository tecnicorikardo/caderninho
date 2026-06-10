# Supabase

Use `schema.sql` no SQL Editor do Supabase para criar as tabelas, indices,
triggers de `updatedAt` e politicas RLS.

O frontend usa somente `VITE_SUPABASE_URL` e `VITE_SUPABASE_PUBLISHABLE_KEY`.
Chaves `service_role` devem ficar apenas em ambiente de servidor, como Firebase
Functions, e nunca no bundle do browser.
