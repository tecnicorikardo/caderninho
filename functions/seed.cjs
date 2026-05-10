/**
 * Seed script — cria 100 produtos e 50 clientes fictícios
 * Uso: node functions/seed.cjs <UID>
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
  console.error("Informe o UID: node functions/seed.cjs <UID>");
  process.exit(1);
}

const BRANDS = ["Natura", "Avon", "Casa & Estilo", "Outra"];

const PRODUCT_NAMES = [
  "Perfume Essencial Feminino","Perfume Homem","Desodorante Aerosol","Creme Hidratante Corporal",
  "Shampoo Nutricao","Condicionador Reparacao","Mascara Capilar","Serum Facial","Protetor Solar FPS50",
  "Base Liquida","Batom Matte","Rimel Volume","Sombra Quarteto","Blush Natural","Iluminador Facial",
  "Esfoliante Corporal","Oleo Corporal","Locao Pos-Banho","Sabonete Liquido","Gel de Banho",
  "Creme para Maos","Perfume Infantil","Colonia Refrescante","Agua de Colonia","Desodorante Roll-on",
  "Creme Anti-Idade","Tonico Facial","Demaquilante","Agua Micelar","Primer Facial",
  "Po Compacto","Contorno Facial","Lapis Olhos","Delineador Liquido","Gloss Labial",
  "Esmalte Cremoso","Removedor de Esmalte","Creme para Pes","Talco Perfumado","Sabonete em Barra",
  "Shampoo Anticaspa","Condicionador Hidratacao","Leave-in Protetor","Finalizador Capilar","Oleo Capilar",
  "Perfume Floral","Perfume Oriental","Perfume Citrico","Perfume Amadeirado","Perfume Aquatico",
  "Creme Facial Noturno","Gel Hidratante Facial","Mousse de Limpeza","Esfoliante Facial","Mascara Facial",
  "Serum Vitamina C","Serum Retinol","Creme Contorno dos Olhos","Protetor Labial","Balsamo Labial",
  "Po Facial Translucido","Corretivo Liquido","Corretivo em Bastao","Fixador de Maquiagem","Removedor Bifasico",
  "Shampoo Cachos","Condicionador Cachos","Creme de Pentear","Gel Modelador","Mousse Capilar",
  "Spray Fixador","Ampola Capilar","Queratina Liquida","Reconstrutor Capilar","Hidratacao Intensiva",
  "Perfume Masculino Intenso","Perfume Feminino Suave","Colonia Infantil","Desodorante Creme","Antitranspirante",
  "Locao Hidratante Facial","Gel de Limpeza Facial","Sabonete Facial","Tonico Adstringente","Creme BB",
  "Creme CC","Primer Olhos","Sombra Glitter","Paleta de Sombras","Pincel Maquiagem",
  "Esponja Aplicadora","Removedor de Maquiagem","Lenco Demaquilante","Agua Termal","Nevoa Facial",
  "Creme Corporal Nutritivo","Manteiga Corporal","Gel Refrescante","Creme Massagem","Oleo Relaxante",
];

const FIRST_NAMES = [
  "Ana","Maria","Joao","Pedro","Lucas","Juliana","Fernanda","Carlos","Marcos","Beatriz",
  "Gabriela","Rafael","Rodrigo","Camila","Larissa","Felipe","Thiago","Amanda","Leticia","Bruno",
  "Patricia","Eduardo","Gustavo","Vanessa","Renata","Diego","Vinicius","Aline","Tatiana","Henrique",
  "Mariana","Leonardo","Fabiana","Andre","Cristina","Paulo","Sandra","Roberto","Luciana","Marcelo",
  "Priscila","Daniel","Natalia","Fabio","Debora","Sergio","Adriana","Ricardo","Monica","Alexandre",
];

const LAST_NAMES = [
  "Silva","Santos","Oliveira","Souza","Lima","Pereira","Costa","Ferreira","Rodrigues","Almeida",
  "Nascimento","Carvalho","Araujo","Gomes","Martins","Ribeiro","Barbosa","Rocha","Cardoso","Correia",
];

const rand = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min;
const randItem = (arr) => arr[Math.floor(Math.random() * arr.length)];

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

async function seedCustomers() {
  console.log("Criando 50 clientes...");
  const col = db.collection("users").doc(uid).collection("customers");
  const batch = db.batch();
  const now = admin.firestore.FieldValue.serverTimestamp();

  for (let i = 0; i < 50; i++) {
    const firstName = FIRST_NAMES[i];
    const lastName = randItem(LAST_NAMES);
    const name = `${firstName} ${lastName}`;
    const phone = randomPhone();
    const ref = col.doc();
    batch.set(ref, {
      name,
      phone,
      phoneNormalized: phone.replace(/\D/g, ""),
      email: `${firstName.toLowerCase()}${rand(1,99)}@email.com`,
      address: `Rua ${randItem(["das Flores","dos Pinheiros","Central","Brasil"])}, ${rand(1,999)}`,
      balanceCents: 0,
      createdAt: now,
      updatedAt: now,
    });
  }
  await batch.commit();
  console.log("50 clientes criados.");
}

async function seedProducts() {
  console.log("Criando 100 produtos...");
  const col = db.collection("users").doc(uid).collection("inventory");
  const now = admin.firestore.FieldValue.serverTimestamp();
  const batch1 = db.batch();
  const batch2 = db.batch();

  for (let i = 0; i < 100; i++) {
    const name = PRODUCT_NAMES[i] || `Produto ${i + 1}`;
    const brand = randItem(BRANDS);
    const cost = rand(5, 80) * 100;
    const selling = Math.round(cost * (1 + rand(20, 60) / 100));
    const ref = col.doc();
    const data = {
      productId: ref.id,
      sku: `SKU-${String(i + 1).padStart(4, "0")}`,
      productName: name,
      brand,
      quantity: rand(1, 50),
      costPriceCents: cost,
      sellingPriceCents: selling,
      expiryDate: randomExpiry(),
      createdAt: now,
      updatedAt: now,
    };
    if (i < 50) batch1.set(ref, data);
    else batch2.set(ref, data);
  }

  await batch1.commit();
  await batch2.commit();
  console.log("100 produtos criados.");
}

async function main() {
  console.log(`\nSeed para UID: ${uid}\n`);
  await seedCustomers();
  await seedProducts();
  console.log("\nSeed concluido! Recarregue o sistema.\n");
  process.exit(0);
}

main().catch((err) => {
  console.error("Erro:", err.message);
  process.exit(1);
});
