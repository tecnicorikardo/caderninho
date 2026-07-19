# Manter Supabase ativo sem cartao

Este projeto usa o plano gratuito da Supabase. Como o GitHub Actions da conta
`tecnicorikardo` esta bloqueado por billing e nao ha cartao disponivel, o
keep-alive oficial passa a ser feito pelo `cron-job.org`.

Antes de configurar ou restaurar o Supabase, confira a conta correta em:

```text
CONTAS_E_PROJETOS.md
```

## Metodo oficial: cron-job.org

Use:

```text
https://cron-job.org
```

Conta cadastrada no `cron-job.org`:

```text
martinsantosric@gmail.com
```

O `cron-job.org` e gratuito, permite agendar chamadas HTTP e aceita headers
customizados. Ele nao depende do GitHub Actions nem de Firebase Functions.

## Como funciona

O cron chama:

```text
https://nhrzaeteadlzvgqfqzkr.supabase.co/rest/v1/users_profiles?select=id&limit=1
```

Com RLS ativo, a chamada pode retornar uma lista vazia (`[]`), mas ainda valida
que a API REST e o banco estao respondendo.

## Configuracao recomendada

No painel do `cron-job.org`, crie ou edite o cronjob com estes dados:

```text
Title: Supabase Users Profile Check
URL: https://nhrzaeteadlzvgqfqzkr.supabase.co/rest/v1/users_profiles?select=id&limit=1
Request method: GET
Timezone: America/Sao_Paulo
Schedule: todos os dias as 03:00
```

Headers:

```text
apikey: sb_publishable_4vudSxBAP0wT6w8Jnwi6Mw_c9MrUukm
Authorization: Bearer sb_publishable_4vudSxBAP0wT6w8Jnwi6Mw_c9MrUukm
Accept: application/json
```

Nao use `service_role` aqui. A chave deve ser a publishable key, a mesma usada
pelo frontend.

## Teste esperado

Ao clicar em `Test run`, o status esperado e:

```text
200 OK
```

O corpo pode vir como:

```json
[]
```

Isso esta correto. O objetivo e acordar a API, nao retornar dados.

## Status conferido

Em 19/07/2026, a tela do `cron-job.org` mostrou:

```text
Conta: martinsantosric@gmail.com
Cronjob: Supabase Users Profile Check
Proxima execucao: amanha as 03:00
```

Tambem foi feito teste local no endpoint com os headers recomendados, com
resultado:

```text
200 OK
Resposta: []
```

Na captura, o campo `Last execution` ainda aparece como `-`. Isso significa que
o cronjob esta criado e agendado, mas ainda nao ha historico de execucao. Depois
da primeira execucao ou de um `Test run`, conferir se o `History` mostra `200 OK`.

## Quando a chave for rotacionada

Se a publishable key for trocada no Supabase:

1. Abra o Supabase.
2. Copie a nova publishable key.
3. Atualize os headers `apikey` e `Authorization` no `cron-job.org`.
4. Atualize tambem `web/.env.local` e a configuracao de build/deploy, se
   necessario.
5. Rode `Test run` no `cron-job.org`.

## Por que nao usar GitHub Actions

O GitHub Actions estava falhando antes de iniciar o runner com:

```text
The job was not started because your account is locked due to a billing issue.
```

Isso significa que o workflow nem chegava a executar o `curl`. Portanto, nao
era erro do Supabase, da publishable key ou do Firebase.

O workflow `.github/workflows/keep-alive.yml` foi removido para parar os e-mails
de falha agendada.

## Quando o Supabase pausar

1. Entre em `https://supabase.com/dashboard`.
2. Use o GitHub conectado ao e-mail `emilycristini2024@gmail.com`.
3. Abra o projeto `nhrzaeteadlzvgqfqzkr`.
4. Clique em `Resume project`.
5. Aguarde sair de `Coming up...` para `Active`.
6. Abra o `cron-job.org`.
7. Rode `Test run` no cronjob do Supabase.

## Limites importantes

- Este ping nao substitui o plano Pro da Supabase.
- Se o `cron-job.org` parar ou falhar por muitos dias, o projeto pode pausar.
- Verifique o historico do cronjob periodicamente.
- O projeto continua no Firebase Spark para Hosting; nao precisa Firebase
  Functions.
