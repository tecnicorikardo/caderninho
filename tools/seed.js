/**
 * Seed script — cria 100 produtos e 50 clientes fictícios
 * Uso: node tools/seed.js <UID_DO_USUARIO>
 * Ex:  node tools/seed.js abc123xyz
 */

const admin = require("firebase-admin");
const path = require("path");

const serviceAccount = require(path.join(__dirname, "../bloquinhodigital-firebase-adminsdk-fbsvc-6e47d7a045.json"));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: "bloquinhodigital",
});

const db = admin.firestore();

const uid = process.argv[2];
if (!uid) {
  console.error("❌  Informe o UID: node tools/seed.js <UID>");
  process.exit(1);
}

// ─── Dados fictícios ────────────────────────────────────────────────────────

const BRANDS = ["Natura", "Avon", "Casa & Estilo", "Outra"];
const CATEGORIES = ["Perfumaria", "Skincare", "Maquiagem", "Cabelos", "Corpo", "Higiene"];

const PRODUCT_NAMES = [
  "Perfume Essencial Feminino","Perfume Homem","Desodorante Aerosol","Creme Hidratante Corporal",
  "Shampoo Nutrição","Condicionador Reparação","Máscara Capilar","Sérum Facial","Protetor Solar FPS50",
  "Base Líquida","Batom Matte","Rímel Volume","Sombra Quarteto","Blush Natural","Iluminador Facial",
  "Esfoliante Corporal","Óleo Corporal","Loção Pós-Banho","Sabonete Líquido","Gel de Banho",
  "Creme para Mãos","Perfume Infantil","Colônia Refrescante","Água de Colônia","Desodorante Roll-on",
  "Creme Anti-Idade","Tônico Facial","Demaquilante","Água Micelar","Primer Facial",
  "Pó Compacto","Contorno Facial","Lápis Olhos","Delineador Líquido","Gloss Labial",
  "Esmalte Cremoso","Removedor de Esmalte","Creme para Pés","Talco Perfumado","Sabonete em Barra",
  "Shampoo Anticaspa","Condicionador Hidratação","Leave-in Protetor","Finalizador Capilar","Óleo Capilar",
  "Perfume Floral","Perfume Oriental","Perfume Cítrico","Perfume Amadeirado","Perfume Aquático",
  "Creme Facial Noturno","Gel Hidratante Facial","Mousse de Limpeza","Esfoliante Facial","Máscara Facial",
  "Sérum Vitamina C","Sérum Retinol","Creme Contorno dos Olhos","Protetor Labial","Bálsamo Labial",
  "Pó Facial Translúcido","Corretivo Líquido","Corretivo em Bastão","Fixador de Maquiagem","Removedor Bifásico",
  "Shampoo Cachos","Condicionador Cachos","Creme de Pentear","Gel Modelador","Mousse Capilar",
  "Spray Fixador","Ampola Capilar","Queratina Líquida","Reconstrutor Capilar","Hidratação Intensiva",
  "Perfume Masculino Intenso","Perfume Feminino Suave","Colônia Infantil","Desodorante Creme","Antitranspirante",
  "Loção Hidratante Facial","Gel de Limpeza Facial","Sabonete Facial","Tônico Adstringente","Creme BB",
  "Creme CC","Primer Olhos","Sombra Glitter","Paleta de Sombras","Pincel Maquiagem",
  "Esponja Aplicadora","Removedor de Maquiagem","Lenço Demaquilante","Água Termal","Névoa Facial",
  "Creme Corporal Nutritivo","Manteiga Corporal","Gel Refrescante","Creme Massagem","Óleo Relaxante",
];

const FIRST_NAMES = [
  "Ana","Maria","João","Pedro","Lucas","Juliana","Fernanda","Carlos","Marcos","Beatriz",
  "Gabriela","Rafael","Rodrigo","Camila","Larissa","Felipe","Thiago","Amanda","Letícia","Bruno",
  "Patrícia","Eduardo","Gustavo","Vanessa","Renata","Diego","Vinícius","Aline","Tatiana","Henrique",
  "Mariana","Leonardo","Fabiana","André","Cristina","Paulo","Sandra","Roberto","Luciana","Marcelo",
  "Priscila","Daniel","Natália","Fábio","Débora","Sérgio","Adriana","Ricardo","Mônica","Alexandre",
];

const LAST_NAMES = [
  "Silva","Santos","Oliveira","Souza","Lima","Pereira","Costa","Ferreira","Rodrigues","Almeida",
  "Nascimento","Carvalho","Araújo","Gomes","Martins","Ribeiro","Barbosa","Rocha","Cardoso","Correia",
];

function rand(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function randItem(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

function randomPhone() {
  const ddd = rand(11, 99);
  const num = `9${rand(10000000, 99999999)}`;
  return `(${ddd}) ${num.slice(0,5)}-${num.slice(5)}`;
}

function randomExpiry() {
  const months = rand(3, 36);
  const d = new Date();
  d.setMonth(d.getMonth() + months);
  return admin.firestore.Timestamp.fromDate(d);
}

function randomCents(min, max) {
  return rand(min, max) * 100;
}

// ─── Seed ───────────────────────────────────────────────────────────────────

async function seedCustomers() {
  console.log("👥  Criando 50 clientes...");
  const col = db.collection("users").doc(uid).collection("customers");
  const batch = db.batch();
  const now = admin.firestore.FieldValue.serverTimestamp();

  for (let i = 0; i < 50; i++) {
    const firstName = FIRST_NAMES[i];
    const lastName = randItem(LAST_NAMES);
    const name = `${firstName} ${lastName}`;
    const phone = randomPhone();
    const phoneNormalized = phone.replace(/\D/g, "");

    const ref = col.doc();
    batch.set(ref, {
      name,
      phone,
      phoneNormalized,
      email: `${firstName.toLowerCase()}.${lastName.toLowerCase()}${rand(1,99)}@email.com`,
      address: `Rua ${randItem(["das Flores","dos Pinheiros","Central","Brasil","São Paulo"])}, ${rand(1,999)}`,
      balanceCents: 0,
      createdAt: now,
      updatedAt: now,
    });
  }

  await batch.commit();
  console.log("✅  50 clientes criados.");
}

async function seedProducts() {
  console.log("📦  Criando 100 produtos no inventário...");
  const col = db.collection("users").doc(uid).collection("inventory");
  const now = admin.firestore.FieldValue.serverTimestamp();

  // Firestore batch limit = 500, mas vamos usar 2 batches de 50
  const batch1 = db.batch();
  const batch2 = db.batch();

  for (let i = 0; i < 100; i++) {
    const name = PRODUCT_NAMES[i] || `Produto ${i + 1}`;
    const brand = randItem(BRANDS);
    const cost = randomCents(5, 80);
    const selling = Math.round(cost * (1 + rand(20, 60) / 100));
    const quantity = rand(1, 50);
    const expiryDate = randomExpiry();
    const code = `SKU-${String(i + 1).padStart(4, "0")}`;

    const ref = col.doc();
    const data = {
      productId: ref.id,
      sku: code,
      productName: name,
      brand,
      quantity,
      costPriceCents: cost,
      sellingPriceCents: selling,
      expiryDate,
      createdAt: now,
      updatedAt: now,
    };

    if (i < 50) {
      batch1.set(ref, data);
    } else {
      batch2.set(ref, data);
    }
  }

  await batch1.commit();
  await batch2.commit();
  console.log("✅  100 produtos criados.");
}

async function main() {
  console.log(`\n🚀  Iniciando seed para UID: ${uid}\n`);
  await seedCustomers();
  await seedProducts();
  console.log("\n🎉  Seed concluído! Recarregue o sistema para ver os dados.\n");
  process.exit(0);
}

main().catch((err) => {
  console.error("❌  Erro:", err.message);
  process.exit(1);
});
