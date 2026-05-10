/**
 * Script de Migração: Firebase → Appwrite
 * 
 * Este script exporta dados do Firebase e importa para o Appwrite.
 * 
 * Uso:
 * 1. Configure as variáveis de ambiente
 * 2. Execute: node tools/migrate-to-appwrite.js
 */

const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });
const admin = require('firebase-admin');
const { Client, Databases, ID } = require('node-appwrite');
const fs = require('fs');

// ============================================================================
// CONFIGURAÇÃO
// ============================================================================

// Firebase
const serviceAccount = require('../bloquinhodigital-firebase-adminsdk-fbsvc-6e47d7a045.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const firestore = admin.firestore();

// Appwrite
const client = new Client()
  .setEndpoint(process.env.APPWRITE_ENDPOINT || 'https://cloud.appwrite.io/v1')
  .setProject(process.env.APPWRITE_PROJECT_ID)
  .setKey(process.env.APPWRITE_API_KEY);

const databases = new Databases(client);

const DATABASE_ID = process.env.APPWRITE_DATABASE_ID || 'bloquinho';

const COLLECTIONS = {
  PROFILES: 'users_profiles',
  CUSTOMERS: 'customers',
  INVENTORY: 'inventory_items',
  SALES: 'sales',
  RECEIVABLES: 'receivables',
  MOVEMENTS: 'inventory_movements',
};

// ============================================================================
// HELPERS
// ============================================================================

function convertTimestamp(timestamp) {
  if (!timestamp) return new Date().toISOString();
  if (timestamp._seconds) {
    return new Date(timestamp._seconds * 1000).toISOString();
  }
  if (timestamp.toDate) {
    return timestamp.toDate().toISOString();
  }
  return new Date().toISOString();
}

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// ============================================================================
// EXPORTAÇÃO DO FIREBASE
// ============================================================================

async function exportFirebaseCollection(collectionPath) {
  console.log(`\n📦 Exportando ${collectionPath}...`);
  
  const snapshot = await firestore.collectionGroup(collectionPath).get();
  const documents = [];
  
  snapshot.forEach(doc => {
    const data = doc.data();
    const userId = doc.ref.parent.parent?.id || 'unknown';
    
    documents.push({
      id: doc.id,
      userId,
      ...data,
    });
  });
  
  console.log(`   ✓ ${documents.length} documentos exportados`);
  return documents;
}

async function exportAllFirebaseData() {
  console.log('\n🔥 EXPORTANDO DADOS DO FIREBASE\n');
  
  const data = {
    customers: await exportFirebaseCollection('customers'),
    inventory: await exportFirebaseCollection('inventory'),
    sales: await exportFirebaseCollection('sales'),
    receivables: await exportFirebaseCollection('receivables'),
    movements: await exportFirebaseCollection('inventory_movements'),
  };
  
  // Exportar profiles (coleção raiz)
  console.log('\n📦 Exportando users...');
  const usersSnapshot = await firestore.collection('users').get();
  data.profiles = [];
  
  usersSnapshot.forEach(doc => {
    data.profiles.push({
      id: doc.id,
      userId: doc.id,
      ...doc.data(),
    });
  });
  
  console.log(`   ✓ ${data.profiles.length} perfis exportados`);
  
  // Salvar em arquivo
  const exportDir = path.join(__dirname, 'export');
  if (!fs.existsSync(exportDir)) {
    fs.mkdirSync(exportDir, { recursive: true });
  }
  
  const exportFile = path.join(exportDir, `firebase-export-${Date.now()}.json`);
  fs.writeFileSync(exportFile, JSON.stringify(data, null, 2));
  
  console.log(`\n💾 Dados salvos em: ${exportFile}`);
  
  return data;
}

// ============================================================================
// IMPORTAÇÃO PARA APPWRITE
// ============================================================================

async function importToAppwrite(collectionId, documents, transform) {
  console.log(`\n📥 Importando para ${collectionId}...`);
  
  let success = 0;
  let errors = 0;
  
  for (const doc of documents) {
    try {
      const transformed = transform ? transform(doc) : doc;
      
      await databases.createDocument(
        DATABASE_ID,
        collectionId,
        doc.id || ID.unique(),
        transformed
      );
      
      success++;
      process.stdout.write(`\r   ✓ ${success}/${documents.length} documentos importados`);
      
      // Rate limiting
      await sleep(100);
      
    } catch (error) {
      errors++;
      console.error(`\n   ✗ Erro ao importar documento ${doc.id}:`, error.message);
    }
  }
  
  console.log(`\n   📊 Sucesso: ${success} | Erros: ${errors}`);
}

// ============================================================================
// TRANSFORMAÇÕES
// ============================================================================

function transformProfile(doc) {
  return {
    userId: doc.userId,
    createdAt: convertTimestamp(doc.createdAt),
    updatedAt: convertTimestamp(doc.updatedAt),
    onboardedAt: doc.onboardedAt ? convertTimestamp(doc.onboardedAt) : null,
    growthLevel: doc.growthLevel || null,
    brandMargins: doc.brandMargins ? JSON.stringify(doc.brandMargins) : null,
    planStatus: doc.planStatus || 'free',
    themeColor: doc.themeColor || null,
  };
}

function transformCustomer(doc) {
  return {
    userId: doc.userId,
    name: doc.name || '',
    phone: doc.phone || '',
    phoneNormalized: doc.phoneNormalized || '',
    email: doc.email || null,
    address: doc.address || null,
    balanceCents: doc.balanceCents || 0,
    createdAt: convertTimestamp(doc.createdAt),
    updatedAt: convertTimestamp(doc.updatedAt),
  };
}

function transformInventory(doc) {
  return {
    userId: doc.userId,
    productId: doc.productId || '',
    sku: doc.sku || null,
    productName: doc.productName || '',
    brand: doc.brand || '',
    quantity: doc.quantity || 0,
    costPriceCents: doc.costPriceCents || 0,
    sellingPriceCents: doc.sellingPriceCents || 0,
    expiryDate: convertTimestamp(doc.expiryDate),
    imageUrl: doc.imageUrl || null,
    createdAt: convertTimestamp(doc.createdAt),
    updatedAt: convertTimestamp(doc.updatedAt),
  };
}

function transformSale(doc) {
  return {
    userId: doc.userId,
    customerId: doc.customerId || '',
    items: JSON.stringify(doc.items || []),
    totalCents: doc.totalCents || 0,
    paidCents: doc.paidCents || 0,
    paymentType: doc.paymentType || 'cash',
    createdAt: convertTimestamp(doc.createdAt),
    updatedAt: convertTimestamp(doc.updatedAt),
  };
}

function transformReceivable(doc) {
  return {
    userId: doc.userId,
    saleId: doc.saleId || '',
    customerId: doc.customerId || '',
    dueDate: convertTimestamp(doc.dueDate),
    amountCents: doc.amountCents || 0,
    paidCents: doc.paidCents || 0,
    status: doc.status || 'pending',
    createdAt: convertTimestamp(doc.createdAt),
    updatedAt: convertTimestamp(doc.updatedAt),
  };
}

function transformMovement(doc) {
  return {
    userId: doc.userId,
    itemId: doc.itemId || '',
    type: doc.type || 'in',
    quantity: doc.quantity || 0,
    reason: doc.reason || '',
    notes: doc.notes || null,
    createdAt: convertTimestamp(doc.createdAt),
  };
}

// ============================================================================
// MAIN
// ============================================================================

async function main() {
  console.log('\n🚀 MIGRAÇÃO FIREBASE → APPWRITE\n');
  console.log('================================\n');
  
  try {
    // Validar configuração
    if (!process.env.APPWRITE_PROJECT_ID || !process.env.APPWRITE_API_KEY) {
      throw new Error('Configure APPWRITE_PROJECT_ID e APPWRITE_API_KEY nas variáveis de ambiente');
    }
    
    // Exportar do Firebase
    const data = await exportAllFirebaseData();
    
    console.log('\n\n☁️  IMPORTANDO PARA APPWRITE\n');
    
    // Importar para Appwrite
    await importToAppwrite(COLLECTIONS.PROFILES, data.profiles, transformProfile);
    await importToAppwrite(COLLECTIONS.CUSTOMERS, data.customers, transformCustomer);
    await importToAppwrite(COLLECTIONS.INVENTORY, data.inventory, transformInventory);
    await importToAppwrite(COLLECTIONS.SALES, data.sales, transformSale);
    await importToAppwrite(COLLECTIONS.RECEIVABLES, data.receivables, transformReceivable);
    await importToAppwrite(COLLECTIONS.MOVEMENTS, data.movements, transformMovement);
    
    console.log('\n\n✅ MIGRAÇÃO CONCLUÍDA COM SUCESSO!\n');
    
  } catch (error) {
    console.error('\n\n❌ ERRO NA MIGRAÇÃO:', error.message);
    console.error(error);
    process.exit(1);
  }
}

// Executar
main().then(() => {
  console.log('\n👋 Finalizando...\n');
  process.exit(0);
});
