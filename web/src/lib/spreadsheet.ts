import * as XLSX from "xlsx";
import { databases, DATABASE_ID, COLLECTIONS, Query } from "@/lib/appwrite";
import { ID, Permission, Role } from "appwrite";
import { toCents } from "@/lib/money";
import { toDate, nowISO } from "@/lib/timestamp";
import type { Customer, InventoryItem } from "@/lib/types";

function getCellString(v: unknown): string { if (v == null) return ""; return String(v).trim(); }
function stableHash(s: string): string { let h = 2166136261; for (let i = 0; i < s.length; i++) { h ^= s.charCodeAt(i); h = Math.imul(h, 16777619); } return (h >>> 0).toString(36); }
function userPerms(uid: string) {
  return [
    Permission.read(Role.user(uid)),
    Permission.update(Role.user(uid)),
    Permission.delete(Role.user(uid)),
  ];
}
const delay = (ms: number) => new Promise(res => setTimeout(res, ms));

// Busca TODOS os clientes de uma vez — evita N queries durante a importação
async function fetchExistingCustomers(uid: string): Promise<Map<string, string>> {
  const map = new Map<string, string>(); // phoneNormalized → $id
  let offset = 0;
  while (true) {
    const res = await databases.listDocuments(DATABASE_ID, COLLECTIONS.CUSTOMERS, [
      Query.equal("userId", uid), Query.limit(100), Query.offset(offset),
    ]);
    res.documents.forEach(d => map.set(d.phoneNormalized as string, d.$id));
    if (res.documents.length < 100) break;
    offset += 100;
  }
  return map;
}

// Busca TODOS os itens de inventário de uma vez
async function fetchExistingInventory(uid: string): Promise<Map<string, string>> {
  const map = new Map<string, string>(); // productId → $id
  let offset = 0;
  while (true) {
    const res = await databases.listDocuments(DATABASE_ID, COLLECTIONS.INVENTORY, [
      Query.equal("userId", uid), Query.limit(100), Query.offset(offset),
    ]);
    res.documents.forEach(d => map.set(d.productId as string, d.$id));
    if (res.documents.length < 100) break;
    offset += 100;
  }
  return map;
}

export function downloadTemplate() {
  const wb = XLSX.utils.book_new();
  const wsC = XLSX.utils.aoa_to_sheet([
    ["nome*","telefone*","email","endereco"],
    ["Maria Silva","(11) 99999-1111","maria@email.com","Rua das Flores, 10"],
  ]);
  wsC["!cols"] = [{wch:30},{wch:20},{wch:30},{wch:35}];
  XLSX.utils.book_append_sheet(wb, wsC, "Clientes");

  const wsP = XLSX.utils.aoa_to_sheet([
    ["nome*","marca*","quantidade*","preco_custo*","preco_venda*","validade* (AAAA-MM-DD)","codigo"],
    ["Perfume Essencial","Natura",10,45.00,65.00,"2026-12-01","SKU-001"],
    ["Desodorante Aerosol","Avon",5,12.50,18.00,"2026-08-15","SKU-002"],
  ]);
  wsP["!cols"] = [{wch:35},{wch:18},{wch:14},{wch:16},{wch:16},{wch:24},{wch:14}];
  XLSX.utils.book_append_sheet(wb, wsP, "Produtos");
  XLSX.writeFile(wb, "modelo_bloquinho_digital.xlsx");
}

export async function exportData(uid: string) {
  const [custRes, invRes] = await Promise.all([
    databases.listDocuments(DATABASE_ID, COLLECTIONS.CUSTOMERS, [Query.equal("userId", uid), Query.limit(1000)]),
    databases.listDocuments(DATABASE_ID, COLLECTIONS.INVENTORY, [Query.equal("userId", uid), Query.limit(1000)]),
  ]);

  const wb = XLSX.utils.book_new();

  const custRows: unknown[][] = [["nome*","telefone*","email","endereco"]];
  custRes.documents.forEach(d => {
    const c = d as unknown as Customer;
    custRows.push([c.name, c.phone, c.email ?? "", c.address ?? ""]);
  });
  const wsC = XLSX.utils.aoa_to_sheet(custRows);
  wsC["!cols"] = [{wch:30},{wch:20},{wch:30},{wch:35}];
  XLSX.utils.book_append_sheet(wb, wsC, "Clientes");

  const invRows: unknown[][] = [["nome*","marca*","quantidade*","preco_custo*","preco_venda*","validade* (AAAA-MM-DD)","codigo"]];
  invRes.documents.forEach(d => {
    const i = d as unknown as InventoryItem;
    const exp = toDate(i.expiryDate).toISOString().split("T")[0];
    invRows.push([i.productName, i.brand, i.quantity, (i.costPriceCents/100).toFixed(2), (i.sellingPriceCents/100).toFixed(2), exp, i.sku ?? ""]);
  });
  const wsI = XLSX.utils.aoa_to_sheet(invRows);
  wsI["!cols"] = [{wch:35},{wch:18},{wch:14},{wch:16},{wch:16},{wch:24},{wch:14}];
  XLSX.utils.book_append_sheet(wb, wsI, "Produtos");

  const date = new Date().toISOString().split("T")[0];
  XLSX.writeFile(wb, `bloquinho_digital_${date}.xlsx`);
}

export type ImportPreview = { customers: number; products: number; errors: string[] };

export async function parseImportFile(file: File): Promise<{ preview: ImportPreview; wb: XLSX.WorkBook }> {
  const buffer = await file.arrayBuffer();
  const wb = XLSX.read(buffer, { type: "array" });
  if (!wb.Sheets["Clientes"] && !wb.Sheets["Produtos"])
    throw new Error("Planilha invalida. Use o modelo com abas Clientes e Produtos.");

  const errors: string[] = [];
  let customers = 0, products = 0;

  if (wb.Sheets["Clientes"]) {
    const rows = XLSX.utils.sheet_to_json(wb.Sheets["Clientes"], { header: 1 }) as unknown[][];
    const [hdr, ...data] = rows;
    const hdrs = (hdr ?? []).map(h => getCellString(h));
    const ni = hdrs.findIndex(h => h.startsWith("nome"));
    const pi = hdrs.findIndex(h => h.startsWith("telefone"));
    data.filter(r => r.some(c => getCellString(c))).forEach((r, i) => {
      if (!getCellString(r[ni]) || !getCellString(r[pi]))
        errors.push(`Clientes linha ${i+2}: nome e telefone obrigatorios`);
      else customers++;
    });
  }

  if (wb.Sheets["Produtos"]) {
    const rows = XLSX.utils.sheet_to_json(wb.Sheets["Produtos"], { header: 1 }) as unknown[][];
    const [hdr, ...data] = rows;
    const hdrs = (hdr ?? []).map(h => getCellString(h));
    const ni = hdrs.findIndex(h => h.startsWith("nome"));
    const bi = hdrs.findIndex(h => h.startsWith("marca"));
    const qi = hdrs.findIndex(h => h.startsWith("quantidade"));
    data.filter(r => r.some(c => getCellString(c))).forEach((r, i) => {
      if (!getCellString(r[ni]) || !getCellString(r[bi]) || !Number(r[qi]))
        errors.push(`Produtos linha ${i+2}: nome, marca e quantidade obrigatorios`);
      else products++;
    });
  }

  return { preview: { customers, products, errors }, wb };
}

export async function importFromWorkbook(
  uid: string,
  wb: XLSX.WorkBook,
  onProgress?: (label: string, current: number, total: number) => void
): Promise<{ customers: number; products: number }> {
  const now = nowISO();
  let custCount = 0, prodCount = 0;

  // Busca dados existentes de uma vez (2 queries totais, não N queries)
  onProgress?.("Verificando dados existentes…", 0, 1);
  const [existingCustomers, existingInventory] = await Promise.all([
    fetchExistingCustomers(uid),
    fetchExistingInventory(uid),
  ]);

  if (wb.Sheets["Clientes"]) {
    const rows = XLSX.utils.sheet_to_json(wb.Sheets["Clientes"], { header: 1 }) as unknown[][];
    const [hdr, ...data] = rows;
    const hdrs = (hdr ?? []).map(h => getCellString(h));
    const ni = hdrs.findIndex(h => h.startsWith("nome"));
    const pi = hdrs.findIndex(h => h.startsWith("telefone"));
    const ei = hdrs.findIndex(h => h.startsWith("email"));
    const ai = hdrs.findIndex(h => h.startsWith("endereco"));

    const validRows = data.filter(r => {
      const name = getCellString(r[ni]);
      const phone = getCellString(r[pi]);
      return r.some(c => getCellString(c)) && name && phone;
    });

    for (let i = 0; i < validRows.length; i++) {
      const r = validRows[i];
      const name = getCellString(r[ni]);
      const phone = getCellString(r[pi]);
      const phoneNormalized = phone.replace(/\D/g, "");

      const existingId = existingCustomers.get(phoneNormalized);
      if (existingId) {
        await databases.updateDocument(DATABASE_ID, COLLECTIONS.CUSTOMERS, existingId, {
          name, phone, phoneNormalized,
          email: getCellString(r[ei]) || null,
          address: getCellString(r[ai]) || null,
          updatedAt: now,
        });
      } else {
        await databases.createDocument(DATABASE_ID, COLLECTIONS.CUSTOMERS, ID.unique(), {
          userId: uid, name, phone, phoneNormalized,
          email: getCellString(r[ei]) || null,
          address: getCellString(r[ai]) || null,
          balanceCents: 0, createdAt: now, updatedAt: now,
        }, userPerms(uid));
      }

      custCount++;
      onProgress?.("Importando clientes…", custCount, validRows.length);
      // Delay entre cada inserção para respeitar rate limit
      await delay(100);
    }
  }

  if (wb.Sheets["Produtos"]) {
    const rows = XLSX.utils.sheet_to_json(wb.Sheets["Produtos"], { header: 1 }) as unknown[][];
    const [hdr, ...data] = rows;
    const hdrs = (hdr ?? []).map(h => getCellString(h));
    const ni = hdrs.findIndex(h => h.startsWith("nome"));
    const bi = hdrs.findIndex(h => h.startsWith("marca"));
    const qi = hdrs.findIndex(h => h.startsWith("quantidade"));
    const ci = hdrs.findIndex(h => h.startsWith("preco_custo"));
    const si = hdrs.findIndex(h => h.startsWith("preco_venda"));
    const ei = hdrs.findIndex(h => h.startsWith("validade"));
    const ki = hdrs.findIndex(h => h.startsWith("codigo"));

    const validRows = data.filter(r => {
      const name = getCellString(r[ni]);
      const brand = getCellString(r[bi]);
      const qty = Number(r[qi]);
      return r.some(c => getCellString(c)) && name && brand && qty;
    });

    for (let i = 0; i < validRows.length; i++) {
      const r = validRows[i];
      const name = getCellString(r[ni]);
      const brand = getCellString(r[bi]);
      const qty = Number(r[qi]);
      const code = getCellString(r[ki]);
      const expiryRaw = getCellString(r[ei]);
      const expiryDate = expiryRaw
        ? new Date(`${expiryRaw}T00:00:00`).toISOString()
        : new Date(Date.now() + 365 * 86400000).toISOString();
      const costCents = toCents(r[ci]);
      const sellCents = toCents(r[si]);
      const productId = `p_${stableHash(`${brand}|${code}|${name}`.toLowerCase())}`;

      const existingId = existingInventory.get(productId);
      if (existingId) {
        await databases.updateDocument(DATABASE_ID, COLLECTIONS.INVENTORY, existingId, {
          productName: name, brand, quantity: qty,
          costPriceCents: costCents, sellingPriceCents: sellCents,
          expiryDate, sku: code || null, updatedAt: now,
        });
      } else {
        await databases.createDocument(DATABASE_ID, COLLECTIONS.INVENTORY, ID.unique(), {
          userId: uid, productId, sku: code || null,
          productName: name, brand, quantity: qty,
          costPriceCents: costCents, sellingPriceCents: sellCents,
          expiryDate, createdAt: now, updatedAt: now,
        }, userPerms(uid));
      }

      prodCount++;
      onProgress?.("Importando produtos…", prodCount, validRows.length);
      // Delay entre cada inserção para respeitar rate limit
      await delay(100);
    }
  }

  return { customers: custCount, products: prodCount };
}
