# Configurar variaveis da Firebase Function `mpPayment`

Este guia explica como configurar as variaveis usadas pela Firebase Function
`mpPayment`, responsavel por criar cobrancas Pix, receber webhook EFI e ativar
o plano Pro no Supabase.

## Variaveis usadas

Variaveis nao secretas, configuradas em `functions/.env`:

```env
SUPABASE_URL=https://nhrzaeteadlzvgqfqzkr.supabase.co
SUPABASE_PROFILES_TABLE=users_profiles
APP_BASE_URL=https://bloquinhodigital.web.app
```

Secrets, configuradas no Google Secret Manager via Firebase CLI:

```text
SUPABASE_SERVICE_ROLE_KEY
EFI_CLIENT_ID
EFI_CLIENT_SECRET
EFI_CERT_BASE64
EFI_PIX_KEY
```

Importante: nunca coloque `SUPABASE_SERVICE_ROLE_KEY`, credenciais EFI ou
certificado EFI em `web/.env.local`, `web/.env.example` ou qualquer arquivo
versionado. O frontend usa somente a publishable key do Supabase.

## 1. Pre-requisitos

Na raiz do projeto (`D:\projetos\bloquinhodigital`), confirme que o Firebase CLI
esta instalado e autenticado:

```powershell
firebase --version
firebase login
firebase projects:list
```

Confirme que o projeto selecionado e o correto:

```powershell
firebase use
```

Este repositorio esta configurado para o projeto Firebase `bloquinhodigital` no
arquivo `.firebaserc`.

## 2. Configurar variaveis nao secretas

Abra ou crie o arquivo ignorado pelo Git:

```powershell
notepad functions\.env
```

Garanta que ele tenha estas linhas:

```env
SUPABASE_URL=https://nhrzaeteadlzvgqfqzkr.supabase.co
SUPABASE_PROFILES_TABLE=users_profiles
APP_BASE_URL=https://bloquinhodigital.web.app
```

Se o arquivo ja tiver outras variaveis, nao apague. Apenas adicione ou atualize
essas tres linhas.

## 3. Configurar secrets no Firebase

Execute os comandos abaixo na raiz do projeto. O Firebase CLI vai pedir o valor
de cada secret no terminal. Cole o valor e confirme.

```powershell
firebase functions:secrets:set SUPABASE_SERVICE_ROLE_KEY
firebase functions:secrets:set EFI_CLIENT_ID
firebase functions:secrets:set EFI_CLIENT_SECRET
firebase functions:secrets:set EFI_CERT_BASE64
firebase functions:secrets:set EFI_PIX_KEY
```

### Onde pegar cada valor

`SUPABASE_SERVICE_ROLE_KEY`

- Supabase Dashboard
- Project Settings
- API
- Use a chave `service_role`
- Esta chave ignora RLS e deve ficar somente no servidor.

`EFI_CLIENT_ID` e `EFI_CLIENT_SECRET`

- Painel EFI/Gerencianet
- Aplicacao Pix/API
- Credenciais de producao da aplicacao.

`EFI_CERT_BASE64`

- E o certificado `.p12` da EFI convertido para Base64.
- No PowerShell, gere assim:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\caminho\para\certificado.p12")) | Set-Clipboard
```

Depois rode:

```powershell
firebase functions:secrets:set EFI_CERT_BASE64
```

Cole o valor que ficou no clipboard.

`EFI_PIX_KEY`

- E a chave Pix cadastrada na EFI para receber os pagamentos.
- Pode ser CPF, CNPJ, e-mail, telefone ou chave aleatoria, conforme sua conta EFI.

## 4. Confirmar que os secrets existem

Para listar/validar secrets:

```powershell
firebase functions:secrets:get SUPABASE_SERVICE_ROLE_KEY
firebase functions:secrets:get EFI_CLIENT_ID
firebase functions:secrets:get EFI_CLIENT_SECRET
firebase functions:secrets:get EFI_CERT_BASE64
firebase functions:secrets:get EFI_PIX_KEY
```

Esse comando nao deve ser usado para colar valores em documentos ou commits. Ele
serve apenas para confirmar que o Secret Manager tem versoes ativas.

## 5. Conferir o codigo da Function

A function `mpPayment` esta em `functions/src/index.js` e ja declara acesso aos
secrets:

```js
secrets: [
  "SUPABASE_SERVICE_ROLE_KEY",
  "EFI_CLIENT_ID",
  "EFI_CLIENT_SECRET",
  "EFI_CERT_BASE64",
  "EFI_PIX_KEY",
]
```

Sem essa declaracao, secrets criadas no Firebase ficam `undefined` durante a
execucao da Function.

## 6. Deploy da Function

Depois de configurar `.env` e secrets, rode:

```powershell
firebase deploy --only functions:mpPayment
```

No log do deploy, procure mensagens parecidas com:

```text
i  functions: Loaded environment variables from .env.
```

Se tambem for subir o frontend:

```powershell
cd web
npm run build
cd ..
firebase deploy --only hosting,functions:mpPayment
```

## 7. Testar apos deploy

### Teste simples do endpoint de plano

Use um `userId` real do Supabase Auth:

```powershell
Invoke-RestMethod `
  -Uri "https://southamerica-east1-bloquinhodigital.cloudfunctions.net/mpPayment/check-plan?userId=COLE_O_USER_ID_AQUI" `
  -Method GET
```

Resposta esperada para usuario sem plano Pro:

```json
{
  "planStatus": "free",
  "planExpiresAt": null
}
```

### Ver logs

```powershell
firebase functions:log --only mpPayment
```

Se der erro de variavel ausente, revise:

- O nome da secret esta exatamente igual.
- A Function foi redeployada depois de criar a secret.
- A secret esta listada na opcao `secrets` do `onRequest`.
- `functions/.env` tem `SUPABASE_URL`.

## 8. Teste local com emulator

Para testar localmente com o emulator, crie `functions/.secret.local`:

```powershell
notepad functions\.secret.local
```

Conteudo:

```env
SUPABASE_SERVICE_ROLE_KEY=cole_aqui
EFI_CLIENT_ID=cole_aqui
EFI_CLIENT_SECRET=cole_aqui
EFI_CERT_BASE64=cole_aqui
EFI_PIX_KEY=cole_aqui
```

Depois:

```powershell
cd functions
npm run serve
```

Nao versione `functions/.secret.local`. Ele ja fica coberto pelo `.gitignore`
por causa da regra `functions/.env.*`; se criar outro padrao de arquivo de
segredo, adicione ao `.gitignore`.

## 9. Checklist final

- `functions/.env` tem `SUPABASE_URL`.
- Secrets foram criadas com `firebase functions:secrets:set`.
- `functions/src/index.js` declara as secrets em `mpPayment`.
- `firebase deploy --only functions:mpPayment` concluiu sem erro.
- `check-plan` respondeu JSON.
- Logs nao mostram `SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY precisam estar configurados`.
- Nenhum segredo foi commitado.

## Referencias oficiais

- Firebase: Configure your environment
  https://firebase.google.com/docs/functions/config-env
- Firebase: Secret Manager em Cloud Functions
  https://firebase.google.com/docs/functions/config-env#secret_parameters
