import { COLLECTIONS, DATABASE_ID, databases, ID, Query } from "@/lib/supabase";

type DemoCustomer = {
  name: string;
  phone: string;
  email: string;
  address: string;
};

type DemoInventoryItem = {
  productName: string;
  brand: string;
  sku: string;
  quantity: number;
  costPriceCents: number;
  sellingPriceCents: number;
  expiryDays: number;
};

export type DemoSeedResult = {
  customersCreated: number;
  customersSkipped: number;
  productsCreated: number;
  productsSkipped: number;
};

const DEMO_CUSTOMERS: DemoCustomer[] = [
  { name: "Cliente Teste Codex 01", phone: "(21) 97000-0001", email: "cliente01@teste.local", address: "Rua das Flores, 101" },
  { name: "Cliente Teste Codex 02", phone: "(21) 97000-0002", email: "cliente02@teste.local", address: "Avenida Central, 202" },
  { name: "Cliente Teste Codex 03", phone: "(21) 97000-0003", email: "cliente03@teste.local", address: "Rua do Sol, 303" },
  { name: "Cliente Teste Codex 04", phone: "(21) 97000-0004", email: "cliente04@teste.local", address: "Rua das Acacias, 404" },
  { name: "Cliente Teste Codex 05", phone: "(21) 97000-0005", email: "cliente05@teste.local", address: "Estrada Nova, 505" },
  { name: "Cliente Teste Codex 06", phone: "(21) 97000-0006", email: "cliente06@teste.local", address: "Rua Bela Vista, 606" },
  { name: "Cliente Teste Codex 07", phone: "(21) 97000-0007", email: "cliente07@teste.local", address: "Travessa Alegre, 707" },
  { name: "Cliente Teste Codex 08", phone: "(21) 97000-0008", email: "cliente08@teste.local", address: "Rua Primavera, 808" },
  { name: "Cliente Teste Codex 09", phone: "(21) 97000-0009", email: "cliente09@teste.local", address: "Avenida Brasil, 909" },
  { name: "Cliente Teste Codex 10", phone: "(21) 97000-0010", email: "cliente10@teste.local", address: "Rua Horizonte, 1000" },
];

const DEMO_INVENTORY: DemoInventoryItem[] = [
  { productName: "Sabonete Tododia Alecrim", brand: "Natura", sku: "TESTE-NAT-001", quantity: 12, costPriceCents: 450, sellingPriceCents: 790, expiryDays: 180 },
  { productName: "Hidratante Ekos Castanha", brand: "Natura", sku: "TESTE-NAT-002", quantity: 6, costPriceCents: 2850, sellingPriceCents: 4590, expiryDays: 240 },
  { productName: "Batom Matte Vermelho", brand: "Avon", sku: "TESTE-AVO-001", quantity: 10, costPriceCents: 890, sellingPriceCents: 1590, expiryDays: 365 },
  { productName: "Mascara de Cilios Volume", brand: "Avon", sku: "TESTE-AVO-002", quantity: 8, costPriceCents: 1290, sellingPriceCents: 2290, expiryDays: 300 },
  { productName: "Aromatizador Lavanda", brand: "Casa & Estilo", sku: "TESTE-CAS-001", quantity: 5, costPriceCents: 1490, sellingPriceCents: 2490, expiryDays: 120 },
  { productName: "Vela Perfumada Baunilha", brand: "Casa & Estilo", sku: "TESTE-CAS-002", quantity: 7, costPriceCents: 990, sellingPriceCents: 1990, expiryDays: 400 },
  { productName: "Perfume Kaiak Feminino", brand: "Natura", sku: "TESTE-NAT-003", quantity: 3, costPriceCents: 6990, sellingPriceCents: 10990, expiryDays: 540 },
  { productName: "Creme Facial Renew", brand: "Avon", sku: "TESTE-AVO-003", quantity: 4, costPriceCents: 3490, sellingPriceCents: 5990, expiryDays: 210 },
  { productName: "Sabonete Liquido Erva Doce", brand: "Natura", sku: "TESTE-NAT-004", quantity: 9, costPriceCents: 1190, sellingPriceCents: 2190, expiryDays: 150 },
  { productName: "Kit Presente Teste", brand: "Outra", sku: "TESTE-OUT-001", quantity: 2, costPriceCents: 4990, sellingPriceCents: 7990, expiryDays: 270 },
];

function normalizeKey(value: unknown) {
  return String(value ?? "").trim().toLowerCase();
}

function phoneDigits(value: string) {
  return value.replace(/\D/g, "");
}

function expiryDate(daysAhead: number) {
  const date = new Date();
  date.setDate(date.getDate() + daysAhead);
  date.setHours(0, 0, 0, 0);
  return date.toISOString();
}

export async function seedDemoData(uid: string): Promise<DemoSeedResult> {
  const [customersRes, inventoryRes] = await Promise.all([
    databases.listDocuments(DATABASE_ID, COLLECTIONS.CUSTOMERS, [
      Query.equal("userId", uid),
      Query.limit(1000),
    ]),
    databases.listDocuments(DATABASE_ID, COLLECTIONS.INVENTORY, [
      Query.equal("userId", uid),
      Query.limit(1000),
    ]),
  ]);

  const existingCustomers = new Set(
    customersRes.documents.map(customer => normalizeKey(customer.name)),
  );
  const existingProducts = new Set(
    inventoryRes.documents.map(item => normalizeKey(item.sku || item.productName)),
  );

  const result: DemoSeedResult = {
    customersCreated: 0,
    customersSkipped: 0,
    productsCreated: 0,
    productsSkipped: 0,
  };

  for (const customer of DEMO_CUSTOMERS) {
    const key = normalizeKey(customer.name);
    if (existingCustomers.has(key)) {
      result.customersSkipped += 1;
      continue;
    }

    const now = new Date().toISOString();
    await databases.createDocument(DATABASE_ID, COLLECTIONS.CUSTOMERS, ID.unique(), {
      userId: uid,
      name: customer.name,
      phone: customer.phone,
      phoneNormalized: phoneDigits(customer.phone),
      email: customer.email,
      address: customer.address,
      balanceCents: 0,
      createdAt: now,
      updatedAt: now,
    });
    existingCustomers.add(key);
    result.customersCreated += 1;
  }

  for (const item of DEMO_INVENTORY) {
    const key = normalizeKey(item.sku || item.productName);
    if (existingProducts.has(key)) {
      result.productsSkipped += 1;
      continue;
    }

    const now = new Date().toISOString();
    await databases.createDocument(DATABASE_ID, COLLECTIONS.INVENTORY, ID.unique(), {
      userId: uid,
      productId: `demo_${normalizeKey(item.sku).replace(/[^a-z0-9]+/g, "_")}`,
      sku: item.sku,
      productName: item.productName,
      brand: item.brand,
      quantity: item.quantity,
      costPriceCents: item.costPriceCents,
      sellingPriceCents: item.sellingPriceCents,
      expiryDate: expiryDate(item.expiryDays),
      imageUrl: null,
      createdAt: now,
      updatedAt: now,
    });
    existingProducts.add(key);
    result.productsCreated += 1;
  }

  return result;
}
