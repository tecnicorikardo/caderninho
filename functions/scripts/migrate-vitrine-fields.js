#!/usr/bin/env node

/**
 * Migra dados para o modulo de Vitrine Digital.
 *
 * Atualiza:
 * - users/{uid}: storeSlug, is_active, storeName, phone
 * - users/{uid}/products/{productId}: userId, showInWeb
 *
 * Uso:
 *   node scripts/migrate-vitrine-fields.js --dry-run
 *   node scripts/migrate-vitrine-fields.js
 *   node scripts/migrate-vitrine-fields.js --limit=100
 */

const fs = require('node:fs');
const path = require('node:path');
const admin = require('firebase-admin');

function parseArgs(argv) {
  const args = {
    dryRun: false,
    limit: null,
  };

  for (const item of argv) {
    if (item === '--dry-run') {
      args.dryRun = true;
      continue;
    }
    if (item.startsWith('--limit=')) {
      const raw = item.split('=')[1];
      const parsed = Number.parseInt(raw, 10);
      if (Number.isFinite(parsed) && parsed > 0) {
        args.limit = parsed;
      }
    }
  }

  return args;
}

function slugify(value) {
  const ascii = String(value || '')
    .trim()
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '');

  return ascii
    .replace(/[^a-z0-9\s-]/g, '')
    .replace(/[\s_]+/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-+|-+$/g, '');
}

function safeText(value) {
  return String(value || '').trim();
}

async function commitBatch({ db, dryRun, updates }) {
  if (updates.length === 0) return;
  if (dryRun) return;

  let batch = db.batch();
  let count = 0;

  for (const item of updates) {
    batch.set(item.ref, item.data, { merge: true });
    count += 1;
    if (count === 400) {
      await batch.commit();
      batch = db.batch();
      count = 0;
    }
  }

  if (count > 0) {
    await batch.commit();
  }
}

async function main() {
  const { dryRun, limit } = parseArgs(process.argv.slice(2));
  const projectId =
    process.env.GCLOUD_PROJECT ||
    process.env.FIREBASE_PROJECT_ID ||
    resolveProjectIdFromFirebaserc();

  const useEmulator = Boolean(process.env.FIRESTORE_EMULATOR_HOST);
  const hasExplicitCreds = Boolean(process.env.GOOGLE_APPLICATION_CREDENTIALS);

  if (!projectId) {
    throw new Error(
      'Projeto Firebase nao identificado. Defina FIREBASE_PROJECT_ID ou configure .firebaserc.',
    );
  }

  if (!useEmulator && !hasExplicitCreds) {
    throw new Error(
      'Credencial ausente. Defina GOOGLE_APPLICATION_CREDENTIALS com o JSON de service account ou use FIRESTORE_EMULATOR_HOST.',
    );
  }

  const appOptions = { projectId };
  if (!useEmulator) {
    appOptions.credential = admin.credential.applicationDefault();
  }

  admin.initializeApp(appOptions);
  const db = admin.firestore();

  let query = db.collection('users').orderBy('__name__');
  if (limit) query = query.limit(limit);
  const usersSnap = await query.get();

  let usersTouched = 0;
  let productsTouched = 0;
  const updates = [];

  for (const userDoc of usersSnap.docs) {
    const userData = userDoc.data() || {};
    const uid = userDoc.id;
    const settingsDoc = await userDoc.ref.collection('settings').doc('store_profile').get();
    const settings = settingsDoc.data() || {};

    const baseName =
      safeText(userData.storeName) ||
      safeText(settings.storeName) ||
      safeText(userData.displayName) ||
      `loja-${uid.slice(0, 8)}`;

    const currentSlug = safeText(userData.storeSlug) || safeText(settings.storeSlug);
    const nextSlug = slugify(currentSlug || baseName || `loja-${uid.slice(0, 8)}`);
    const currentIsActive = userData.is_active;
    const settingsIsActive = settings.isActive;
    const nextIsActive =
      typeof currentIsActive === 'boolean'
        ? currentIsActive
        : typeof settingsIsActive === 'boolean'
        ? settingsIsActive
        : true;

    const nextPhone = safeText(userData.phone) || safeText(settings.phone);
    const nextStoreName = safeText(userData.storeName) || safeText(settings.storeName) || baseName;

    const userNeedsUpdate =
      safeText(userData.storeSlug) !== nextSlug ||
      userData.is_active !== nextIsActive ||
      safeText(userData.phone) !== nextPhone ||
      safeText(userData.storeName) !== nextStoreName;

    const settingsNeedsUpdate =
      safeText(settings.storeSlug) !== nextSlug ||
      settings.isActive !== nextIsActive ||
      safeText(settings.phone) !== nextPhone ||
      safeText(settings.storeName) !== nextStoreName;

    if (userNeedsUpdate) {
      updates.push({
        ref: userDoc.ref,
        data: {
          storeSlug: nextSlug,
          is_active: nextIsActive,
          storeName: nextStoreName,
          phone: nextPhone,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
      });
      usersTouched += 1;
    }

    if (settingsNeedsUpdate) {
      updates.push({
        ref: userDoc.ref.collection('settings').doc('store_profile'),
        data: {
          storeSlug: nextSlug,
          isActive: nextIsActive,
          storeName: nextStoreName,
          phone: nextPhone,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
      });
    }

    const productsSnap = await userDoc.ref.collection('products').get();
    for (const productDoc of productsSnap.docs) {
      const product = productDoc.data() || {};
      const nextShowInWeb =
        typeof product.showInWeb === 'boolean' ? product.showInWeb : false;
      const nextUserId = safeText(product.userId) || uid;

      const productNeedsUpdate =
        product.showInWeb !== nextShowInWeb || safeText(product.userId) !== nextUserId;

      if (productNeedsUpdate) {
        updates.push({
          ref: productDoc.ref,
          data: {
            showInWeb: nextShowInWeb,
            userId: nextUserId,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
        });
        productsTouched += 1;
      }
    }
  }

  await commitBatch({ db, dryRun, updates });

  const mode = dryRun ? 'DRY RUN' : 'APLICADO';
  console.log(`[${mode}] usuarios analisados: ${usersSnap.size}`);
  console.log(`[${mode}] usuarios atualizados: ${usersTouched}`);
  console.log(`[${mode}] produtos atualizados: ${productsTouched}`);
  console.log(`[${mode}] total de operacoes: ${updates.length}`);
}

function resolveProjectIdFromFirebaserc() {
  const candidates = [
    path.resolve(process.cwd(), '../.firebaserc'),
    path.resolve(process.cwd(), '.firebaserc'),
    path.resolve(process.cwd(), '../../.firebaserc'),
  ];

  for (const candidate of candidates) {
    if (!fs.existsSync(candidate)) continue;
    try {
      const raw = fs.readFileSync(candidate, 'utf8');
      const parsed = JSON.parse(raw);
      if (parsed?.projects?.default) {
        return String(parsed.projects.default).trim();
      }
    } catch (_) {
      // Ignora parse error e tenta proximo caminho.
    }
  }
  return '';
}

main().catch((error) => {
  console.error('Falha na migracao:', error);
  process.exitCode = 1;
});
