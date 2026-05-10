# Guia de Migração: Firebase → Appwrite

## Visão Geral

Este documento descreve a migração do Bloquinho Digital de Firebase para Appwrite.

## Por que Appwrite?

- ✅ Open-source e self-hosted
- ✅ Sem vendor lock-in
- ✅ Custos mais previsíveis
- ✅ API REST e SDKs modernos
- ✅ Suporte a realtime
- ✅ Autenticação completa
- ✅ Storage integrado

## Estrutura da Migração

### 1. Configuração Inicial

#### Instalação do Appwrite Cloud ou Self-Hosted

**Opção A: Appwrite Cloud (Recomendado para começar)**
1. Acesse https://cloud.appwrite.io
2. Crie uma conta gratuita
3. Crie um novo projeto
4. Anote o Project ID e Endpoint

**Opção B: Self-Hosted (Docker)**
```bash
docker run -d \
  --name appwrite \
  -p 80:80 -p 443:443 \
  -v appwrite-data:/storage \
  appwrite/appwrite:latest
```

#### Configuração do Projeto

1. No console do Appwrite, crie:
   - **Database**: `bloquinho`
   - **Collections** (veja estrutura abaixo)

### 2. Estrutura do Banco de Dados

#### Collections no Appwrite

**users_profiles**
- `userId` (string, required) - ID do usuário
- `businessName` (string)
- `phone` (string)
- `theme` (string)
- `onboarded` (boolean)
- `createdAt` (datetime)
- `updatedAt` (datetime)

**customers**
- `userId` (string, required, indexed)
- `name` (string, required)
- `phone` (string)
- `email` (string)
- `address` (string)
- `notes` (string)
- `active` (boolean, default: true)
- `createdAt` (datetime)
- `updatedAt` (datetime)

**inventory_items**
- `userId` (string, required, indexed)
- `name` (string, required)
- `sku` (string)
- `category` (string)
- `costCents` (integer)
- `priceCents` (integer)
- `stock` (integer, default: 0)
- `minStock` (integer)
- `imageBase64` (string)
- `active` (boolean, default: true)
- `createdAt` (datetime)
- `updatedAt` (datetime)

**sales**
- `userId` (string, required, indexed)
- `customerId` (string, indexed)
- `customerName` (string)
- `totalCents` (integer, required)
- `paymentType` (string, required)
- `items` (string, JSON array)
- `notes` (string)
- `createdAt` (datetime)
- `updatedAt` (datetime)

**receivables**
- `userId` (string, required, indexed)
- `customerId` (string, required, indexed)
- `type` (string, required) - 'debt' | 'loan'
- `amountCents` (integer, required)
- `paidCents` (integer, default: 0)
- `status` (string, required) - 'open' | 'partial' | 'paid'
- `dueDate` (datetime)
- `interestType` (string)
- `interestRate` (integer)
- `description` (string)
- `createdAt` (datetime)
- `updatedAt` (datetime)

**inventory_movements**
- `userId` (string, required, indexed)
- `itemId` (string, required, indexed)
- `type` (string, required) - 'in' | 'out'
- `quantity` (integer, required)
- `reason` (string)
- `notes` (string)
- `createdAt` (datetime)

### 3. Migração de Dados

#### Script de Exportação do Firebase

```javascript
// export-firebase-data.js
const admin = require('firebase-admin');
const fs = require('fs');

admin.initializeApp({
  credential: admin.credential.cert('./serviceAccountKey.json')
});

const db = admin.firestore();

async function exportCollection(collectionName) {
  const snapshot = await db.collection(collectionName).get();
  const data = [];
  
  snapshot.forEach(doc => {
    data.push({ id: doc.id, ...doc.data() });
  });
  
  fs.writeFileSync(
    `./export/${collectionName}.json`,
    JSON.stringify(data, null, 2)
  );
  
  console.log(`✓ Exported ${data.length} documents from ${collectionName}`);
}

async function exportAllData() {
  const collections = [
    'users',
    'customers',
    'inventory_items',
    'sales',
    'receivables',
    'inventory_movements'
  ];
  
  for (const collection of collections) {
    await exportCollection(collection);
  }
}

exportAllData().then(() => {
  console.log('Export completed!');
  process.exit(0);
});
```

#### Script de Importação para Appwrite

```javascript
// import-to-appwrite.js
const sdk = require('node-appwrite');
const fs = require('fs');

const client = new sdk.Client()
  .setEndpoint(process.env.APPWRITE_ENDPOINT)
  .setProject(process.env.APPWRITE_PROJECT_ID)
  .setKey(process.env.APPWRITE_API_KEY);

const databases = new sdk.Databases(client);

async function importCollection(collectionName, appwriteCollectionId) {
  const data = JSON.parse(
    fs.readFileSync(`./export/${collectionName}.json`, 'utf8')
  );
  
  for (const doc of data) {
    try {
      await databases.createDocument(
        'bloquinho', // database ID
        appwriteCollectionId,
        doc.id,
        doc
      );
      console.log(`✓ Imported document ${doc.id}`);
    } catch (error) {
      console.error(`✗ Error importing ${doc.id}:`, error.message);
    }
  }
}

async function importAllData() {
  const mappings = {
    'users': 'users_profiles',
    'customers': 'customers',
    'inventory_items': 'inventory_items',
    'sales': 'sales',
    'receivables': 'receivables',
    'inventory_movements': 'inventory_movements'
  };
  
  for (const [firebaseCollection, appwriteCollection] of Object.entries(mappings)) {
    console.log(`\nImporting ${firebaseCollection}...`);
    await importCollection(firebaseCollection, appwriteCollection);
  }
}

importAllData().then(() => {
  console.log('\nImport completed!');
  process.exit(0);
});
```

### 4. Configuração de Permissões

No Appwrite Console, para cada collection:

1. **Permissions de Leitura**: `user:[USER_ID]`
2. **Permissions de Escrita**: `user:[USER_ID]`
3. **Permissions de Atualização**: `user:[USER_ID]`
4. **Permissions de Exclusão**: `user:[USER_ID]`

Ou use a configuração automática:
- Document Security: **Enabled**
- Default Permissions: **None** (cada usuário só acessa seus próprios dados)

### 5. Migração de Autenticação

#### Opções de Migração de Usuários

**Opção A: Migração Manual (Recomendado)**
- Usuários fazem login novamente no Appwrite
- Dados são migrados automaticamente no primeiro login

**Opção B: Migração em Lote**
- Exportar usuários do Firebase Auth
- Criar contas no Appwrite via API
- Enviar e-mails de redefinição de senha

### 6. Variáveis de Ambiente

Atualize `web/.env.local`:

```env
# Appwrite Configuration
VITE_APPWRITE_ENDPOINT=https://cloud.appwrite.io/v1
VITE_APPWRITE_PROJECT_ID=seu-project-id
VITE_APPWRITE_DATABASE_ID=bloquinho

# Collections IDs
VITE_APPWRITE_COLLECTION_PROFILES=users_profiles
VITE_APPWRITE_COLLECTION_CUSTOMERS=customers
VITE_APPWRITE_COLLECTION_INVENTORY=inventory_items
VITE_APPWRITE_COLLECTION_SALES=sales
VITE_APPWRITE_COLLECTION_RECEIVABLES=receivables
VITE_APPWRITE_COLLECTION_MOVEMENTS=inventory_movements
```

### 7. Checklist de Migração

- [ ] Criar projeto no Appwrite
- [ ] Criar database e collections
- [ ] Configurar permissões
- [ ] Instalar SDK do Appwrite no projeto
- [ ] Criar camada de abstração
- [ ] Migrar autenticação
- [ ] Migrar operações de leitura
- [ ] Migrar operações de escrita
- [ ] Exportar dados do Firebase
- [ ] Importar dados no Appwrite
- [ ] Testar todas as funcionalidades
- [ ] Atualizar documentação
- [ ] Deploy da nova versão

### 8. Rollback

Caso necessário reverter:
1. Manter código Firebase em branch separada
2. Restaurar variáveis de ambiente antigas
3. Fazer deploy da versão anterior

### 9. Vantagens da Nova Arquitetura

- **Custo**: Plano gratuito mais generoso
- **Controle**: Self-hosted quando necessário
- **Performance**: Queries otimizadas
- **Flexibilidade**: API REST + SDKs
- **Realtime**: WebSocket nativo
- **Storage**: Integrado e simples

### 10. Próximos Passos

1. Revisar este guia
2. Criar projeto no Appwrite
3. Executar migração em ambiente de desenvolvimento
4. Testar extensivamente
5. Migrar produção

## Suporte

- Documentação Appwrite: https://appwrite.io/docs
- Discord Appwrite: https://appwrite.io/discord
- GitHub Issues: https://github.com/appwrite/appwrite/issues
