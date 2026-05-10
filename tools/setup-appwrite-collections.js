/**
 * Script para criar automaticamente as collections no Appwrite
 * 
 * Uso:
 * 1. Configure as variáveis de ambiente (.env)
 * 2. Execute: node tools/setup-appwrite-collections.js
 */

const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });
const { Client, Databases, Permission, Role } = require('node-appwrite');

// Configuração
const client = new Client()
  .setEndpoint(process.env.APPWRITE_ENDPOINT || 'https://cloud.appwrite.io/v1')
  .setProject(process.env.APPWRITE_PROJECT_ID)
  .setKey(process.env.APPWRITE_API_KEY);

const databases = new Databases(client);
const DATABASE_ID = process.env.APPWRITE_DATABASE_ID || 'bloquinho';

// ============================================================================
// DEFINIÇÕES DAS COLLECTIONS
// ============================================================================

const collections = [
  {
    id: 'users_profiles',
    name: 'Users Profiles',
    attributes: [
      { key: 'userId', type: 'string', size: 255, required: true },
      { key: 'createdAt', type: 'datetime', required: true },
      { key: 'updatedAt', type: 'datetime', required: true },
      { key: 'onboardedAt', type: 'datetime', required: false },
      { key: 'growthLevel', type: 'string', size: 50, required: false },
      { key: 'brandMargins', type: 'string', size: 5000, required: false },
      { key: 'planStatus', type: 'string', size: 20, required: false },
      { key: 'themeColor', type: 'string', size: 20, required: false },
    ],
    indexes: [
      { key: 'userId', type: 'key', attributes: ['userId'] },
    ],
  },
  {
    id: 'customers',
    name: 'Customers',
    attributes: [
      { key: 'userId', type: 'string', size: 255, required: true },
      { key: 'name', type: 'string', size: 255, required: true },
      { key: 'phone', type: 'string', size: 50, required: false },
      { key: 'phoneNormalized', type: 'string', size: 50, required: false },
      { key: 'email', type: 'string', size: 255, required: false },
      { key: 'address', type: 'string', size: 500, required: false },
      { key: 'balanceCents', type: 'integer', required: true },
      { key: 'createdAt', type: 'datetime', required: true },
      { key: 'updatedAt', type: 'datetime', required: true },
    ],
    indexes: [
      { key: 'userId', type: 'key', attributes: ['userId'] },
      { key: 'name', type: 'fulltext', attributes: ['name'] },
    ],
  },
  {
    id: 'inventory_items',
    name: 'Inventory Items',
    attributes: [
      { key: 'userId', type: 'string', size: 255, required: true },
      { key: 'productId', type: 'string', size: 255, required: true },
      { key: 'sku', type: 'string', size: 100, required: false },
      { key: 'productName', type: 'string', size: 255, required: true },
      { key: 'brand', type: 'string', size: 100, required: true },
      { key: 'quantity', type: 'integer', required: true },
      { key: 'costPriceCents', type: 'integer', required: true },
      { key: 'sellingPriceCents', type: 'integer', required: true },
      { key: 'expiryDate', type: 'datetime', required: true },
      { key: 'imageUrl', type: 'string', size: 100000, required: false },
      { key: 'createdAt', type: 'datetime', required: true },
      { key: 'updatedAt', type: 'datetime', required: true },
    ],
    indexes: [
      { key: 'userId', type: 'key', attributes: ['userId'] },
      { key: 'productName', type: 'fulltext', attributes: ['productName'] },
    ],
  },
  {
    id: 'sales',
    name: 'Sales',
    attributes: [
      { key: 'userId', type: 'string', size: 255, required: true },
      { key: 'customerId', type: 'string', size: 255, required: true },
      { key: 'items', type: 'string', size: 50000, required: true },
      { key: 'totalCents', type: 'integer', required: true },
      { key: 'paidCents', type: 'integer', required: true },
      { key: 'paymentType', type: 'string', size: 50, required: true },
      { key: 'createdAt', type: 'datetime', required: true },
      { key: 'updatedAt', type: 'datetime', required: true },
    ],
    indexes: [
      { key: 'userId', type: 'key', attributes: ['userId'] },
      { key: 'customerId', type: 'key', attributes: ['customerId'] },
      { key: 'createdAt', type: 'key', attributes: ['createdAt'] },
    ],
  },
  {
    id: 'receivables',
    name: 'Receivables',
    attributes: [
      { key: 'userId', type: 'string', size: 255, required: true },
      { key: 'saleId', type: 'string', size: 255, required: true },
      { key: 'customerId', type: 'string', size: 255, required: true },
      { key: 'dueDate', type: 'datetime', required: true },
      { key: 'amountCents', type: 'integer', required: true },
      { key: 'paidCents', type: 'integer', required: true },
      { key: 'status', type: 'string', size: 50, required: true },
      { key: 'createdAt', type: 'datetime', required: true },
      { key: 'updatedAt', type: 'datetime', required: true },
    ],
    indexes: [
      { key: 'userId', type: 'key', attributes: ['userId'] },
      { key: 'customerId', type: 'key', attributes: ['customerId'] },
      { key: 'status', type: 'key', attributes: ['status'] },
    ],
  },
  {
    id: 'inventory_movements',
    name: 'Inventory Movements',
    attributes: [
      { key: 'userId', type: 'string', size: 255, required: true },
      { key: 'itemId', type: 'string', size: 255, required: true },
      { key: 'type', type: 'string', size: 20, required: true },
      { key: 'quantity', type: 'integer', required: true },
      { key: 'reason', type: 'string', size: 255, required: false },
      { key: 'notes', type: 'string', size: 1000, required: false },
      { key: 'createdAt', type: 'datetime', required: true },
    ],
    indexes: [
      { key: 'userId', type: 'key', attributes: ['userId'] },
      { key: 'itemId', type: 'key', attributes: ['itemId'] },
    ],
  },
];

// ============================================================================
// FUNÇÕES
// ============================================================================

async function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function createCollection(collectionDef) {
  console.log(`\n📦 Criando collection: ${collectionDef.name}`);
  
  try {
    // Criar collection
    const collection = await databases.createCollection(
      DATABASE_ID,
      collectionDef.id,
      collectionDef.name,
      [
        Permission.read(Role.any()),
        Permission.create(Role.users()),
        Permission.update(Role.users()),
        Permission.delete(Role.users()),
      ],
      true // documentSecurity
    );
    
    console.log(`   ✓ Collection criada: ${collection.$id}`);
    
    // Aguardar um pouco antes de criar atributos
    await sleep(1000);
    
    // Criar atributos
    for (const attr of collectionDef.attributes) {
      try {
        console.log(`   → Criando atributo: ${attr.key}`);
        
        if (attr.type === 'string') {
          await databases.createStringAttribute(
            DATABASE_ID,
            collectionDef.id,
            attr.key,
            attr.size,
            attr.required,
            attr.default,
            false // array
          );
        } else if (attr.type === 'integer') {
          await databases.createIntegerAttribute(
            DATABASE_ID,
            collectionDef.id,
            attr.key,
            attr.required,
            attr.min,
            attr.max,
            attr.default,
            false // array
          );
        } else if (attr.type === 'datetime') {
          await databases.createDatetimeAttribute(
            DATABASE_ID,
            collectionDef.id,
            attr.key,
            attr.required,
            attr.default,
            false // array
          );
        }
        
        // Aguardar entre atributos
        await sleep(500);
        
      } catch (error) {
        console.error(`   ✗ Erro ao criar atributo ${attr.key}:`, error.message);
      }
    }
    
    console.log(`   ✓ Atributos criados`);
    
    // Aguardar antes de criar índices
    await sleep(2000);
    
    // Criar índices
    for (const index of collectionDef.indexes) {
      try {
        console.log(`   → Criando índice: ${index.key}`);
        
        await databases.createIndex(
          DATABASE_ID,
          collectionDef.id,
          index.key,
          index.type,
          index.attributes,
          index.orders || []
        );
        
        await sleep(500);
        
      } catch (error) {
        console.error(`   ✗ Erro ao criar índice ${index.key}:`, error.message);
      }
    }
    
    console.log(`   ✓ Índices criados`);
    console.log(`   ✅ Collection ${collectionDef.name} configurada com sucesso!`);
    
  } catch (error) {
    console.error(`   ❌ Erro ao criar collection ${collectionDef.name}:`, error.message);
    throw error;
  }
}

async function createDatabase() {
  console.log(`\n🗄️  Criando database: ${DATABASE_ID}`);
  
  try {
    const database = await databases.create(DATABASE_ID, 'Bloquinho Digital');
    console.log(`   ✓ Database criado: ${database.$id}`);
  } catch (error) {
    if (error.code === 409) {
      console.log(`   ℹ️  Database já existe`);
    } else {
      throw error;
    }
  }
}

async function main() {
  console.log('\n🚀 SETUP APPWRITE COLLECTIONS\n');
  console.log('================================\n');
  
  try {
    // Validar configuração
    if (!process.env.APPWRITE_PROJECT_ID || !process.env.APPWRITE_API_KEY) {
      throw new Error('Configure APPWRITE_PROJECT_ID e APPWRITE_API_KEY nas variáveis de ambiente');
    }
    
    console.log(`📍 Endpoint: ${process.env.APPWRITE_ENDPOINT || 'https://cloud.appwrite.io/v1'}`);
    console.log(`📍 Project: ${process.env.APPWRITE_PROJECT_ID}`);
    console.log(`📍 Database: ${DATABASE_ID}`);
    
    // Criar database
    await createDatabase();
    await sleep(2000);
    
    // Criar collections
    for (const collectionDef of collections) {
      await createCollection(collectionDef);
      await sleep(2000);
    }
    
    console.log('\n\n✅ SETUP CONCLUÍDO COM SUCESSO!\n');
    console.log('Próximos passos:');
    console.log('1. Configure as variáveis de ambiente no web/.env.local');
    console.log('2. Execute o script de migração: node tools/migrate-to-appwrite.js');
    console.log('3. Teste a aplicação: cd web && npm run dev\n');
    
  } catch (error) {
    console.error('\n\n❌ ERRO NO SETUP:', error.message);
    console.error(error);
    process.exit(1);
  }
}

// Executar
main().then(() => {
  console.log('\n👋 Finalizando...\n');
  process.exit(0);
});
