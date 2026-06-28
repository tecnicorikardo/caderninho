# Manter Supabase ativo com GitHub Actions

Este projeto usa um workflow gratuito do GitHub Actions para fazer um ping leve
no Supabase a cada 3 dias.

Arquivo:

```text
.github/workflows/keep-alive.yml
```

## Como funciona

O workflow chama:

```text
https://nhrzaeteadlzvgqfqzkr.supabase.co/rest/v1/users_profiles?select=id&limit=1
```

Ele usa a chave publica do Supabase como header `apikey` e `Authorization`.
Com RLS ativo, a chamada pode retornar uma lista vazia, mas ainda valida que a
API REST e o banco estao respondendo.

## Configurar o Secret no GitHub

1. Abra o repositorio no GitHub.
2. Acesse `Settings`.
3. Acesse `Secrets and variables`.
4. Clique em `Actions`.
5. Clique em `New repository secret`.
6. Nome do secret:

```text
SUPABASE_PUBLISHABLE_KEY
```

7. Valor: cole a publishable key do Supabase.
8. Salve.

Nao use `service_role` aqui. A chave do workflow deve ser a publishable/anon
key, a mesma usada pelo frontend.

## Rodar manualmente

Depois que o arquivo estiver na branch `main`:

1. Abra a aba `Actions` no GitHub.
2. Selecione `Supabase Keep Alive`.
3. Clique em `Run workflow`.
4. Confira se o job termina com sucesso.

Se o projeto ja estiver pausado, restaure primeiro no painel da Supabase e rode
o workflow manualmente em seguida.

## Agendamento atual

```yaml
cron: "17 9 */3 * *"
```

Isso roda a cada 3 dias as 09:17 UTC.

## Limites importantes

- Este ping nao substitui o plano Pro da Supabase.
- Se a Supabase pausar o projeto antes do primeiro ping, restaure manualmente.
- Se o GitHub Actions for desativado ou falhar, o projeto pode pausar de novo.
- Verifique a aba `Actions` depois do primeiro agendamento para confirmar que o
  workflow esta rodando.
