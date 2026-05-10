# Tools - Scripts de Migração Appwrite

Esta pasta contém scripts para facilitar a migração do Firebase para o Appwrite.

## 📁 Arquivos

### `setup-appwrite-collections.js`
Cria automaticamente todas as collections, atributos e índices no Appwrite.

**Uso:**
```bash
# 1. Instalar dependências
npm install node-appwrite

# 2. Configurar variáveis de ambiente
# Crie um arquivo .env na raiz do projeto com:
APPWRITE_ENDPOINT=https://cloud.appwrite.io/v1
APPWRITE_PROJECT_ID=seu-project-id
APPWRITE_API_KEY=sua-api-key
APPWRITE_DATABASE_ID=bloquinho

# 3. Executar
node setup-appwrite-collections.js
```

### `migrate-to-appwrite.js`
Exporta dados do Firebase e importa para o Appwrite.

**Uso:**
```bash
# 1. Instalar dependências
npm install firebase-admin node-appwrite

# 2. Garantir que o arquivo de credenciais do Firebase está na raiz
# bloquinhodigital-firebase-adminsdk-fbsvc-6e47d7a045.json

# 3. Configurar variáveis de ambiente (mesmo .env acima)

# 4. Executar
node migrate-to-appwrite.js
```

## 🔄 Fluxo Completo de Migração

### 1. Preparação

```bash
cd tools
npm install node-appwrite firebase-admin
```

### 2. Criar arquivo .env

Crie um arquivo `.env` na **raiz do projeto** (não na pasta tools):

```env
APPWRITE_ENDPOINT=https://cloud.appwrite.io/v1
APPWRITE_PROJECT_ID=seu-project-id-aqui
APPWRITE_API_KEY=sua-api-key-aqui
APPWRITE_DATABASE_ID=bloquinho
```

### 3. Executar Setup

```bash
node setup-appwrite-collections.js
```

Isso irá:
- ✅ Criar o database `bloquinho`
- ✅ Criar todas as 6 collections
- ✅ Criar todos os atributos
- ✅ Criar todos os índices

### 4. Executar Migração

```bash
node migrate-to-appwrite.js
```

Isso irá:
- ✅ Exportar dados do Firebase
- ✅ Salvar backup em `export/`
- ✅ Importar dados para Appwrite
- ✅ Mostrar estatísticas

### 5. Verificar

Acesse o console do Appwrite e verifique:
- Database criado
- Collections criadas
- Dados importados

## 📊 Collections Criadas

1. **users_profiles** - Perfis de usuários
2. **customers** - Clientes
3. **inventory_items** - Itens do estoque
4. **sales** - Vendas
5. **receivables** - Recebíveis (fiados)
6. **inventory_movements** - Movimentações de estoque

## 🔑 Obtendo API Key

1. Acesse o console do Appwrite
2. Vá em **Settings** → **API Keys**
3. Clique em **Create API Key**
4. Nome: `Migration Script`
5. Scopes: Selecione todos os de `databases.*`
6. Copie a API Key (só aparece uma vez!)

## 🆘 Troubleshooting

### Erro: "Project not found"
- Verifique se o `APPWRITE_PROJECT_ID` está correto
- Confirme que está usando o endpoint correto

### Erro: "Invalid API key"
- Verifique se a API Key está correta
- Confirme que a API Key tem as permissões necessárias

### Erro: "Collection already exists"
- As collections já foram criadas
- Você pode pular o setup e ir direto para a migração

### Erro: "Attribute already exists"
- Normal se você executar o script múltiplas vezes
- O script continua mesmo com esses erros

### Erro ao importar dados
- Verifique se as collections foram criadas corretamente
- Confirme que os atributos estão corretos
- Verifique os logs para ver qual documento falhou

## 📦 Backup

Os dados exportados do Firebase são salvos em:
```
tools/export/firebase-export-[timestamp].json
```

**Importante:** Mantenha esse backup por pelo menos 30 dias!

## 🔄 Rollback

Se precisar voltar para o Firebase:

1. Mude `VITE_DB_PROVIDER=firebase` no `web/.env.local`
2. Faça deploy da versão anterior
3. Os dados do Firebase permanecem intactos

## 📝 Notas

- O script usa rate limiting para evitar sobrecarga
- Cada documento é importado individualmente
- Erros são logados mas não param a execução
- Timestamps são convertidos automaticamente
- Arrays e objetos são serializados como JSON

## 🎯 Próximos Passos

Após a migração:

1. Atualize `web/.env.local` com as configurações do Appwrite
2. Mude `VITE_DB_PROVIDER=appwrite`
3. Teste a aplicação: `cd web && npm run dev`
4. Verifique todas as funcionalidades
5. Faça deploy quando estiver confiante

## 📚 Recursos

- [Documentação Appwrite](https://appwrite.io/docs)
- [API Reference](https://appwrite.io/docs/references)
- [Discord Appwrite](https://appwrite.io/discord)
