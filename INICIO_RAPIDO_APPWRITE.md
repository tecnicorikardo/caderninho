# Início Rápido - Migração para Appwrite

## 🎯 Objetivo

Migrar o Bloquinho Digital de Firebase para Appwrite em 5 passos simples.

## 📋 Pré-requisitos

- Node.js instalado
- Conta no Appwrite Cloud (gratuita) ou Appwrite self-hosted
- Acesso ao projeto Firebase atual

## 🚀 Passo a Passo

### 1. Criar Projeto no Appwrite

#### Opção A: Appwrite Cloud (Recomendado)

1. Acesse https://cloud.appwrite.io
2. Crie uma conta gratuita
3. Clique em "Create Project"
4. Nome do projeto: `Bloquinho Digital`
5. Anote o **Project ID**

#### Opção B: Self-Hosted

```bash
docker run -d \
  --name appwrite \
  -p 80:80 -p 443:443 \
  -v appwrite-data:/storage \
  appwrite/appwrite:latest
```

### 2. Criar Database e Collections

No console do Appwrite:

1. **Database**
   - Clique em "Databases" → "Create Database"
   - Nome: `bloquinho`
   - Anote o **Database ID**

2. **Collections** (criar cada uma):

#### Collection: `users_profiles`
```
Attributes:
- userId (string, 255, required)
- createdAt (datetime, required)
- updatedAt (datetime, required)
- onboardedAt (datetime)
- growthLevel (string, 50)
- brandMargins (string, 5000)
- planStatus (string, 20)
- themeColor (string, 20)

Indexes:
- userId (key: userId, type: key, attributes: [userId])

Permissions:
- Document Security: Enabled
```

#### Collection: `customers`
```
Attributes:
- userId (string, 255, required)
- name (string, 255, required)
- phone (string, 50)
- phoneNormalized (string, 50)
- email (string, 255)
- address (string, 500)
- balanceCents (integer, required, default: 0)
- createdAt (datetime, required)
- updatedAt (datetime, required)

Indexes:
- userId (key: userId, type: key, attributes: [userId])
- name (key: name, type: fulltext, attributes: [name])

Permissions:
- Document Security: Enabled
```

#### Collection: `inventory_items`
```
Attributes:
- userId (string, 255, required)
- productId (string, 255, required)
- sku (string, 100)
- productName (string, 255, required)
- brand (string, 100, required)
- quantity (integer, required, default: 0)
- costPriceCents (integer, required, default: 0)
- sellingPriceCents (integer, required, default: 0)
- expiryDate (datetime, required)
- imageUrl (string, 100000)
- createdAt (datetime, required)
- updatedAt (datetime, required)

Indexes:
- userId (key: userId, type: key, attributes: [userId])
- productName (key: productName, type: fulltext, attributes: [productName])

Permissions:
- Document Security: Enabled
```

#### Collection: `sales`
```
Attributes:
- userId (string, 255, required)
- customerId (string, 255, required)
- items (string, 50000, required)
- totalCents (integer, required)
- paidCents (integer, required)
- paymentType (string, 50, required)
- createdAt (datetime, required)
- updatedAt (datetime, required)

Indexes:
- userId (key: userId, type: key, attributes: [userId])
- customerId (key: customerId, type: key, attributes: [customerId])
- createdAt (key: createdAt, type: key, attributes: [createdAt])

Permissions:
- Document Security: Enabled
```

#### Collection: `receivables`
```
Attributes:
- userId (string, 255, required)
- saleId (string, 255, required)
- customerId (string, 255, required)
- dueDate (datetime, required)
- amountCents (integer, required)
- paidCents (integer, required, default: 0)
- status (string, 50, required)
- createdAt (datetime, required)
- updatedAt (datetime, required)

Indexes:
- userId (key: userId, type: key, attributes: [userId])
- customerId (key: customerId, type: key, attributes: [customerId])
- status (key: status, type: key, attributes: [status])

Permissions:
- Document Security: Enabled
```

#### Collection: `inventory_movements`
```
Attributes:
- userId (string, 255, required)
- itemId (string, 255, required)
- type (string, 20, required)
- quantity (integer, required)
- reason (string, 255)
- notes (string, 1000)
- createdAt (datetime, required)

Indexes:
- userId (key: userId, type: key, attributes: [userId])
- itemId (key: itemId, type: key, attributes: [itemId])

Permissions:
- Document Security: Enabled
```

### 3. Configurar API Key

1. No console Appwrite, vá em "Settings" → "API Keys"
2. Clique em "Create API Key"
3. Nome: `Migration Script`
4. Scopes: Selecione todos os de `databases.*`
5. Copie a **API Key** (só aparece uma vez!)

### 4. Configurar Variáveis de Ambiente

Atualize `web/.env.local`:

```env
# Appwrite Configuration
VITE_APPWRITE_ENDPOINT=https://cloud.appwrite.io/v1
VITE_APPWRITE_PROJECT_ID=seu-project-id-aqui
VITE_APPWRITE_DATABASE_ID=bloquinho

# Collections IDs (copie do console)
VITE_APPWRITE_COLLECTION_PROFILES=users_profiles
VITE_APPWRITE_COLLECTION_CUSTOMERS=customers
VITE_APPWRITE_COLLECTION_INVENTORY=inventory_items
VITE_APPWRITE_COLLECTION_SALES=sales
VITE_APPWRITE_COLLECTION_RECEIVABLES=receivables
VITE_APPWRITE_COLLECTION_MOVEMENTS=inventory_movements

# Provider (firebase ou appwrite)
VITE_DB_PROVIDER=appwrite
```

Para o script de migração, crie `.env` na raiz:

```env
APPWRITE_ENDPOINT=https://cloud.appwrite.io/v1
APPWRITE_PROJECT_ID=seu-project-id-aqui
APPWRITE_API_KEY=sua-api-key-aqui
APPWRITE_DATABASE_ID=bloquinho
```

### 5. Executar Migração de Dados

```bash
# Instalar dependências do script
cd tools
npm install firebase-admin node-appwrite

# Executar migração
node migrate-to-appwrite.js
```

O script irá:
1. ✅ Exportar todos os dados do Firebase
2. ✅ Salvar backup em `tools/export/`
3. ✅ Importar dados para o Appwrite
4. ✅ Mostrar progresso e estatísticas

### 6. Testar a Aplicação

```bash
cd web
npm install
npm run dev
```

Acesse http://localhost:5173 e teste:
- ✅ Login/Cadastro
- ✅ Listar clientes
- ✅ Criar venda
- ✅ Visualizar estoque
- ✅ Relatórios

## 🔄 Migração Gradual (Opcional)

Se preferir migrar aos poucos:

1. Mantenha `VITE_DB_PROVIDER=firebase` no `.env.local`
2. Teste o Appwrite em ambiente de desenvolvimento
3. Quando estiver confiante, mude para `VITE_DB_PROVIDER=appwrite`

## 🆘 Troubleshooting

### Erro: "Project not found"
- Verifique se o `VITE_APPWRITE_PROJECT_ID` está correto
- Confirme que o endpoint está correto (cloud vs self-hosted)

### Erro: "Collection not found"
- Verifique se todos os IDs das collections estão corretos
- Confirme que as collections foram criadas no database correto

### Erro: "Missing required attribute"
- Verifique se todos os atributos obrigatórios foram criados
- Confirme que os tipos de dados estão corretos

### Erro de permissão
- Verifique se "Document Security" está habilitado
- Confirme que o usuário está autenticado

## 📊 Comparação de Custos

| Recurso | Firebase (Spark) | Appwrite Cloud (Free) |
|---------|------------------|----------------------|
| Usuários | 10k/mês | Ilimitado |
| Database Reads | 50k/dia | 75k/mês |
| Database Writes | 20k/dia | 75k/mês |
| Storage | 1 GB | 2 GB |
| Bandwidth | 10 GB/mês | 10 GB/mês |

## ✅ Checklist Final

- [ ] Projeto criado no Appwrite
- [ ] Database e collections configuradas
- [ ] Variáveis de ambiente configuradas
- [ ] Dados migrados com sucesso
- [ ] Aplicação testada e funcionando
- [ ] Backup do Firebase mantido
- [ ] Documentação atualizada

## 🎉 Próximos Passos

1. Configurar domínio customizado (se aplicável)
2. Configurar backup automático
3. Monitorar uso e performance
4. Considerar self-hosted para maior controle

## 📚 Recursos

- [Documentação Appwrite](https://appwrite.io/docs)
- [Console Appwrite Cloud](https://cloud.appwrite.io)
- [Discord Appwrite](https://appwrite.io/discord)
- [GitHub Appwrite](https://github.com/appwrite/appwrite)

## 💡 Dicas

- Mantenha backup do Firebase por 30 dias
- Teste extensivamente antes de desativar Firebase
- Use o console Appwrite para monitorar queries
- Configure alertas de uso no Appwrite Cloud
