# Contas e projetos oficiais

Ultima atualizacao: 2026-07-10

Este arquivo existe para evitar confusao entre repositorios, contas GitHub e
projetos Supabase parecidos.

## Repositorio oficial

```text
https://github.com/tecnicorikardo/caderninho.git
```

Este e o repositorio que deve receber commits, pushes e configuracoes de
GitHub Actions do app Bloquinho Digital.

## Supabase correto do sistema

```text
Project ref: nhrzaeteadlzvgqfqzkr
Project URL: https://nhrzaeteadlzvgqfqzkr.supabase.co
Dashboard: https://supabase.com/dashboard/project/nhrzaeteadlzvgqfqzkr
```

Use este projeto para banco, auth, Edge Functions e keep-alive.

## Conta de acesso ao Supabase

O projeto Supabase correto foi localizado pelo GitHub conectado ao e-mail:

```text
emilycristini2024@gmail.com
```

Ao entrar no Supabase, use o login com GitHub dessa conta para encontrar o
projeto `nhrzaeteadlzvgqfqzkr`.

## Nao confundir com outros projetos

Nao usar como projeto principal do app:

```text
gestordedivida
helogourmet2/gestordedivida
xdskhspqrqeraqnshuey
```

Esses nomes apareceram durante a investigacao, mas nao sao o Supabase
documentado no app `tecnicorikardo/caderninho`.

## Quando o Supabase pausar

1. Entrar em `https://supabase.com/dashboard`.
2. Fazer login com GitHub da conta `emilycristini2024@gmail.com`.
3. Abrir o projeto `nhrzaeteadlzvgqfqzkr`.
4. Clicar em `Resume project`.
5. Aguardar sair de `Coming up...` para `Active`.
6. Abrir o GitHub do app.
7. Ir em `Actions`.
8. Rodar manualmente o workflow `Supabase Keep Alive`.

## Keep-alive

Workflow:

```text
.github/workflows/keep-alive.yml
```

Secret necessario no GitHub Actions:

```text
SUPABASE_PUBLISHABLE_KEY
```

Nao usar `service_role` no GitHub Actions.

Guia detalhado:

```text
MANTER_SUPABASE_ATIVO.md
```

## CLI local

Se a Supabase CLI estiver logada na conta errada:

```bash
npx supabase logout
npx supabase login
npx supabase link --project-ref nhrzaeteadlzvgqfqzkr
```

Depois confira:

```bash
npx supabase projects list
```

O projeto `nhrzaeteadlzvgqfqzkr` deve aparecer na lista.

## Cadastro e login

O app publicado usa Supabase Auth junto com o banco Supabase. Em 10/07/2026, o
endpoint publico de configuracao do Supabase indicou:

```text
mailer_autoconfirm=false
```

Isso significa que o cadastro por e-mail exige confirmacao antes do primeiro
login. Se o navegador mostrar erro `400 Bad Request` em:

```text
/auth/v1/token?grant_type=password
```

as causas mais comuns sao e-mail/senha incorretos ou e-mail ainda nao
confirmado. Para liberar acesso imediato sem confirmacao, alterar no painel do
Supabase em Authentication > Providers > Email > Confirm email.

## Sinal de app antigo ou configuracao errada

Se o console do navegador mostrar chamadas para:

```text
fra.cloud.appwrite.io
```

entao o navegador esta carregando uma versao antiga, cache antigo ou deploy
antigo que ainda aponta para Appwrite. Nesse caso, fazer novo build/deploy do
Firebase Hosting e limpar cache do navegador/PWA.
