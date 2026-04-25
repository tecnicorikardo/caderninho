/* eslint-disable no-console */
const fs = require("node:fs");
const path = require("node:path");

function parseArgs(argv) {
  const args = {
    projectId: null,
    confirm: null,
    serviceAccount: null,
    deleteAuth: false,
    deleteFirestore: false,
    deleteStorage: false,
  };

  for (let i = 2; i < argv.length; i += 1) {
    const token = argv[i];

    if (token === "--projectId") args.projectId = argv[++i];
    else if (token === "--confirm") args.confirm = argv[++i];
    else if (token === "--serviceAccount") args.serviceAccount = argv[++i];
    else if (token === "--deleteAuth") args.deleteAuth = true;
    else if (token === "--deleteFirestore") args.deleteFirestore = true;
    else if (token === "--deleteStorage") args.deleteStorage = true;
    else if (token === "--help" || token === "-h") args.help = true;
    else throw new Error(`Argumento desconhecido: ${token}`);
  }

  return args;
}

function printHelp() {
  console.log(`
Uso:
  node wipe.js --projectId <id> --confirm <id> [--serviceAccount <path>]
              [--deleteFirestore] [--deleteAuth] [--deleteStorage]

Exemplo:
  node wipe.js --projectId bloquinhodigital --confirm bloquinhodigital --deleteFirestore --deleteAuth
`);
}

function resolveServiceAccountPath(input) {
  if (!input) return null;
  return path.isAbsolute(input) ? input : path.resolve(process.cwd(), input);
}

async function deleteAllAuthUsers(auth, projectId) {
  let pageToken = undefined;
  let total = 0;

  console.log(`[Auth] Listando usuários... (${projectId})`);

  do {
    const result = await auth.listUsers(1000, pageToken);
    const uids = result.users.map((u) => u.uid);

    if (uids.length > 0) {
      const del = await auth.deleteUsers(uids);
      total += del.successCount;
      console.log(`[Auth] Deletados: +${del.successCount} (falhas: ${del.failureCount})`);
    }

    pageToken = result.pageToken;
  } while (pageToken);

  console.log(`[Auth] Concluído. Total deletado: ${total}`);
}

async function deleteAllFirestoreData(firestore, projectId) {
  console.log(`[Firestore] Listando coleções raiz... (${projectId})`);
  const collections = await firestore.listCollections();

  if (collections.length === 0) {
    console.log("[Firestore] Nenhuma coleção encontrada.");
    return;
  }

  for (const col of collections) {
    console.log(`[Firestore] Apagando coleção: ${col.id}`);

    if (typeof firestore.recursiveDelete === "function") {
      const bulkWriter = firestore.bulkWriter();
      bulkWriter.onWriteError((err) => {
        console.error("[Firestore] Erro ao deletar:", err);
        return false;
      });

      await firestore.recursiveDelete(col, bulkWriter);
      await bulkWriter.close();
    } else {
      throw new Error(
        "Firestore.recursiveDelete não está disponível nesta versão do SDK. Use o Firebase CLI (firestore:delete) ou atualize firebase-admin.",
      );
    }
  }

  console.log("[Firestore] Concluído.");
}

async function deleteAllStorageObjects(storage, projectId) {
  const bucket = storage.bucket();
  console.log(`[Storage] Apagando objetos do bucket: ${bucket.name} (${projectId})`);
  await bucket.deleteFiles({ force: true });
  console.log("[Storage] Concluído.");
}

async function main() {
  const args = parseArgs(process.argv);

  if (args.help) {
    printHelp();
    return;
  }

  if (!args.projectId) throw new Error("--projectId é obrigatório");
  if (!args.confirm) throw new Error("--confirm é obrigatório");
  if (args.confirm !== args.projectId) {
    throw new Error("--confirm deve ser exatamente igual ao --projectId (proteção contra projeto errado)");
  }

  if (!args.deleteAuth && !args.deleteFirestore && !args.deleteStorage) {
    throw new Error("Selecione ao menos uma ação: --deleteAuth, --deleteFirestore, --deleteStorage");
  }

  const serviceAccountPath = resolveServiceAccountPath(args.serviceAccount);

  const { initializeApp, applicationDefault, cert } = require("firebase-admin/app");
  const { getAuth } = require("firebase-admin/auth");
  const { getFirestore } = require("firebase-admin/firestore");
  const { getStorage } = require("firebase-admin/storage");

  if (serviceAccountPath) {
    const json = JSON.parse(fs.readFileSync(serviceAccountPath, "utf8"));
    initializeApp({ credential: cert(json), projectId: args.projectId });
  } else {
    initializeApp({ credential: applicationDefault(), projectId: args.projectId });
  }

  console.log(`[Init] projectId=${args.projectId}`);

  const firestore = getFirestore();
  const auth = getAuth();
  const storage = getStorage();

  if (args.deleteFirestore) await deleteAllFirestoreData(firestore, args.projectId);
  if (args.deleteAuth) await deleteAllAuthUsers(auth, args.projectId);
  if (args.deleteStorage) await deleteAllStorageObjects(storage, args.projectId);
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
