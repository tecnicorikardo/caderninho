# 🚀 Configurar Supabase - Guia Completo

Este guia mostra como configurar o Supabase no projeto Bloquinho Digital.

---

## ✅ Status Atual

**Suas variáveis já estão configuradas!** ✅

Arquivo `web/.env.local` contém:

```env
VITE_SUPABASE_URL=https://nhrzaeteadlzvgqfqzkr.supabase.co
VITE_SUPABASE_PUBLISHABLE_KEY=sb_publishable_4vudSxBAP0wT6w8Jnwi6Mw_c9MrUukm
VITE_DB_PROVIDER=supabase
```

**Você está pronto para usar!** 🎉

---

## 📋 Índice

1. [Verificar Configuração](#verificar-configuração)
2. [Variáveis de Ambiente](#variáveis-de-ambiente)
3. [Estrutura do Banco](#estrutura-do-banco)
4. [Como Obter as Variáveis](#como-obter-as-variáveis)
5. [Testar a Conexão](#testar-a-conexão)
6. [Solução de Problemas](#solução-de-problemas)

---

## 1. Verificar Configuração

### ✅ Verificar se está funcionando

Execute o servidor de desenvolvimento:

```bash
cd web
npm run dev
```

Acesse: http://localhost:5173

**Se você conseguir fazer login**, está tudo OK! ✅

---

## 2. Variáveis de Ambiente

### Variáveis do Frontend (públicas)

Arquivo: `web/.env.local`

```env
# URL do projeto Supabase
VITE_SUPABASE_URL=https://nhrzaeteadlzvgqfqzkr.supabase.co

# Chave pública (anon key) - pode ser exposta no frontend
VITE_SUPABASE_PUBLISHABLE_KEY=sb_publishable_4vudSxBAP0wT6w8Jnwi6Mw_c9MrUukm

# Provider de banco de dados (supabase ou firebase)
VITE_DB_PROVIDER=supabase
```

### Variáveis Privadas (NUNCA no frontend)

Estas variáveis são **secretas** e só devem ser usadas no servidor (Edge Functions):

```env
# ⚠️ NUNCA adicione estas no .env.local!
SUPABASE_SERVICE_ROLE_KEY=xxxx  # Ignora RLS, só para servidor
```

---

## 3. Estrutura do Banco

### Tabelas Principais

O Supabase usa estas tabelas:

| Tabela | Descrição |
|--------|-----------|
| `users_profiles` | Perfil do usuário (CPF, margens, plano) |
| `products` | Estoque de produtos |
| `customers` | Clientes |
| `sales` | Vendas |
| `sale_items` | Itens de cada venda |
| `receivables` | Recebíveis (fiado, parcelas) |

### Schema

O schema está em: `supabase/schema.sql`

**Já aplicado no seu projeto!** ✅

---

## 4. Como Obter as Variáveis

Se você precisar reconfigurar ou para outro projeto:

### 4.1 Acessar o Painel do Supabase

1. Acesse: https://supabase.com
2. Faça login
3. Abra seu projeto: **nhrzaeteadlzvgqfqzkr**

### 4.2 Obter VITE_SUPABASE_URL

No painel do Supabase:

1. Vá em **Settings** → **API**
2. Copie **Project URL**

Exemplo: `https://nhrzaeteadlzvgqfqzkr.supabase.co`

### 4.3 Obter VITE_SUPABASE_PUBLISHABLE_KEY

No painel do Supabase:

1. Vá em **Settings** → **API**
2. Copie **Project API keys** → **anon / public**

Exemplo: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

> ⚠️ **Atenção**: Use a chave **anon/public**, NÃO a **service_role**!

### 4.4 Configurar no .env.local

```bash
cd web
```

Edite `web/.env.local`:

```env
VITE_SUPABASE_URL=sua_url_aqui
VITE_SUPABASE_PUBLISHABLE_KEY=sua_chave_aqui
VITE_DB_PROVIDER=supabase
```

---

## 5. Testar a Conexão

### Teste 1: Verificar variáveis carregadas

Crie um arquivo temporário `web/test-supabase.js`:

```javascript
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseKey = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY

console.log('URL:', supabaseUrl)
console.log('Key (primeiros 20 chars):', supabaseKey?.substring(0, 20))

const supabase = createClient(supabaseUrl, supabaseKey)

// Teste de conexão
const { data, error } = await supabase.from('users_profiles').select('count')

if (error) {
  console.error('Erro:', error.message)
} else {
  console.log('✅ Conexão OK! Profiles:', data)
}
```

Execute:

```bash
node test-supabase.js
```

### Teste 2: Login no app

1. Execute: `cd web && npm run dev`
2. Acesse: http://localhost:5173
3. Tente fazer login com suas credenciais
4. Se conseguir entrar no dashboard: **✅ Tudo OK!**

### Teste 3: Verificar no navegador

No console do navegador (F12), execute:

```javascript
console.log('Supabase URL:', import.meta.env.VITE_SUPABASE_URL)
console.log('Supabase Key:', import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY?.substring(0, 20))
```

Deve mostrar os valores configurados.

---

## 6. Solução de Problemas

### ❌ Erro: "Invalid API key"

**Causa**: Chave incorreta ou expirada

**Solução**:
1. Verifique se copiou a chave **anon/public**, não a **service_role**
2. Confirme que não há espaços extras
3. Regenere a chave no painel do Supabase se necessário

### ❌ Erro: "URL is required"

**Causa**: Variável `VITE_SUPABASE_URL` não está configurada

**Solução**:
1. Verifique se o arquivo `web/.env.local` existe
2. Confirme que a variável começa com `VITE_`
3. Reinicie o servidor de desenvolvimento

### ❌ Variáveis não carregam

**Causa**: Servidor não reiniciado após editar `.env.local`

**Solução**:
```bash
# Pare o servidor (Ctrl+C)
cd web
npm run dev
```

### ❌ Erro: "Failed to fetch"

**Causa**: URL incorreta ou projeto desativado

**Solução**:
1. Verifique a URL no painel do Supabase
2. Confirme que o projeto está ativo
3. Teste a URL no navegador: `https://seu-projeto.supabase.co`

### ❌ Login falha silenciosamente

**Causa**: Tabela `users_profiles` não existe ou RLS muito restritivo

**Solução**:
1. Execute o schema: `supabase/schema.sql`
2. Verifique as políticas RLS no painel do Supabase
3. Veja os logs de erro no console do navegador (F12)

---

## 📊 Arquitetura

### Fluxo de Autenticação

```
LoginPage.tsx
  ↓
account.createEmailPasswordSession()  ← Supabase Auth
  ↓
Supabase valida credenciais
  ↓
Retorna JWT token
  ↓
App.tsx recebe usuário autenticado
  ↓
Carrega perfil de users_profiles
  ↓
Dashboard
```

### Fluxo de Dados

```
Componente React
  ↓
lib/db-adapter.ts  ← Abstração (Supabase ou Firebase)
  ↓
lib/adapters/supabase-adapter.ts  ← Cliente Supabase
  ↓
Supabase Database
```

---

## 🔒 Segurança

### ✅ Boas Práticas

1. **Nunca** commite a `service_role_key`
2. Use apenas chaves **anon/public** no frontend
3. Configure RLS (Row Level Security) no Supabase
4. Use variáveis de ambiente para secrets
5. Rotacione chaves regularmente

### ⚠️ O que NUNCA fazer

```env
# ❌ ERRADO - Nunca no .env.local!
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# ✅ CERTO - Apenas no servidor (Edge Functions)
# Configurar via: supabase secrets set
```

---

## 🔗 Recursos

### Documentação

- **Supabase Docs**: https://supabase.com/docs
- **Supabase Auth**: https://supabase.com/docs/guides/auth
- **JavaScript Client**: https://supabase.com/docs/reference/javascript

### Painel do Supabase

- **Dashboard**: https://supabase.com/dashboard
- **Seu Projeto**: https://supabase.com/dashboard/project/nhrzaeteadlzvgqfqzkr

### Supabase CLI

```bash
# Instalar
npm install -g supabase

# Login
supabase login

# Vincular projeto
supabase link --project-ref nhrzaeteadlzvgqfqzkr

# Listar secrets
supabase secrets list

# Aplicar migrations
supabase db push
```

---

## 📝 Checklist de Configuração

### Frontend (web/.env.local)

- [x] `VITE_SUPABASE_URL` configurada
- [x] `VITE_SUPABASE_PUBLISHABLE_KEY` configurada
- [x] `VITE_DB_PROVIDER=supabase`
- [x] Arquivo não commitado (.gitignore)

### Banco de Dados

- [x] Schema aplicado (`supabase/schema.sql`)
- [x] Tabelas criadas
- [x] RLS configurado
- [x] Índices criados

### Autenticação

- [x] Login funciona
- [x] Registro funciona
- [x] Logout funciona
- [x] Perfil carrega após login

### Aplicação

- [x] `npm run dev` funciona
- [x] `npm run build` funciona
- [x] Nenhum erro no console
- [x] Dashboard carrega dados

---

## ✅ Você está pronto!

Suas variáveis já estão configuradas e funcionando. Para verificar:

```bash
cd web
npm run dev
```

Acesse: http://localhost:5173

Se conseguir fazer login: **🎉 Tudo configurado corretamente!**

---

**Próximos passos**:

1. ✅ Configuração do Supabase (concluído)
2. ⏭️ [Execute os testes](EXECUTAR_TESTES.md)
3. ⏭️ [Configure Edge Functions para Pix](CONFIGURAR_SUPABASE_EDGE_FUNCTION_PIX.md)

