import * as XLSX from "xlsx";
import { collection, getDocs, serverTimestamp, writeBatch, doc } from "firebase/firestore";
import { db } from "@/lib/firebase";
import { toCents } from "@/lib/money";
import type { Customer, InventoryItem } from "@/lib/types";

// helpers
function getCellString(v: unknown): string { if (v == null) return ""; return String(v).trim(); }
function stableHash(s: string): string { let h = 2166136261; for (let i = 0; i < s.length; i++) { h ^= s.charCodeAt(i); h = Math.imul(h, 16777619); } return (h >>> 0).toString(36); }

export function downloadTemplate() {
  const wb = XLSX.utils.book_new();
  const wsC = XLSX.utils.aoa_to_sheet([["nome*","telefone*","email","endereco"],["Maria Silva","(11) 99999-1111","maria@email.com","Rua das Flores, 10"]]);
  wsC["!cols"] = [{wch:30},{wch:20},{wch:30},{wch:35}];
  XLSX.utils.book_append_sheet(wb, wsC, "Clientes");
  const wsP = XLSX.utils.aoa_to_sheet([["nome*","marca*","quantidade*","preco_custo*","preco_venda*","validade* (AAAA-MM-DD)","codigo"],["Perfume Essencial","Natura",10,45.00,65.00,"2026-12-01","SKU-001"],["Desodorante Aerosol","Avon",5,12.50,18.00,"2026-08-15","SKU-002"]]);
  wsP["!cols"] = [{wch:35},{wch:18},{wch:14},{wch:16},{wch:16},{wch:24},{wch:14}];
  XLSX.utils.book_append_sheet(wb, wsP, "Produtos");
  XLSX.writeFile(wb, "modelo_bloquinho_digital.xlsx");
}

export async function exportData(uid: string) {
  const [custSnap, invSnap] = await Promise.all([getDocs(collection(db, "users", uid, "customers")), getDocs(collection(db, "users", uid, "inventory"))]);
  const wb = XLSX.utils.book_new();
  const custRows: unknown[][] = [["nome*","telefone*","email","endereco"]];
  custSnap.docs.forEach(d => { const c = d.data() as Customer; custRows.push([c.name, c.phone, c.email ?? "", c.address ?? ""]); });
  const wsC = XLSX.utils.aoa_to_sheet(custRows);
  wsC["!cols"] = [{wch:30},{wch:20},{wch:30},{wch:35}];
  XLSX.utils.book_append_sheet(wb, wsC, "Clientes");
  const invRows: unknown[][] = [["nome*","marca*","quantidade*","preco_custo*","preco_venda*","validade* (AAAA-MM-DD)","codigo"]];
  invSnap.docs.forEach(d => { const i = d.data() as InventoryItem; const exp = i.expiryDate?.toDate?.()?.toISOString().split("T")[0] ?? ""; invRows.push([i.productName, i.brand, i.quantity, (i.costPriceCents/100).toFixed(2), (i.sellingPriceCents/100).toFixed(2), exp, i.sku ?? ""]); });
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
  if (!wb.Sheets["Clientes"] && !wb.Sheets["Produtos"]) throw new Error("Planilha invalida. Use o modelo com abas Clientes e Produtos.");
  const errors: string[] = [];
  let customers = 0, products = 0;
  if (wb.Sheets["Clientes"]) {
    const rows = XLSX.utils.sheet_to_json(wb.Sheets["Clientes"], { header: 1 }) as unknown[][];
    const [hdr, ...data] = rows;
    const hdrs = (hdr ?? []).map(h => getCellString(h));
    const ni = hdrs.findIndex(h => h.startsWith("nome")), pi = hdrs.findIndex(h => h.startsWith("telefone"));
    data.filter(r => r.some(c => getCellString(c))).forEach((r, i) => { if (!getCellString(r[ni]) || !getCellString(r[pi])) errors.push(`Clientes linha ${i+2}: nome e telefone obrigatorios`); else customers++; });
  }
  if (wb.Sheets["Produtos"]) {
    const rows = XLSX.utils.sheet_to_json(wb.Sheets["Produtos"], { header: 1 }) as unknown[][];
    const [hdr, ...data] = rows;
    const hdrs = (hdr ?? []).map(h => getCellString(h));
    const ni = hdrs.findIndex(h => h.startsWith("nome")), bi = hdrs.findIndex(h => h.startsWith("marca")), qi = hdrs.findIndex(h => h.startsWith("quantidade"));
    data.filter(r => r.some(c => getCellString(c))).forEach((r, i) => { if (!getCellString(r[ni]) || !getCellString(r[bi]) || !Number(r[qi])) errors.push(`Produtos linha ${i+2}: nome, marca e quantidade obrigatorios`); else products++; });
  }
  return { preview: { customers, products, errors }, wb };
}

export async function importFromWorkbook(uid: string, wb: XLSX.WorkBook): Promise<{ customers: number; products: number }> {
  const custCol = collection(db, "users", uid, "customers");
  const invCol = collection(db, "users", uid, "inventory");
  const prodCol = collection(db, "users", uid, "products");
  const writes: Array<(b: ReturnType<typeof writeBatch>) => void> = [];
  let custCount = 0, prodCount = 0;
  if (wb.Sheets["Clientes"]) {
    const rows = XLSX.utils.sheet_to_json(wb.Sheets["Clientes"], { header: 1 }) as unknown[][];
    const [hdr, ...data] = rows;
    const hdrs = (hdr ?? []).map(h => getCellString(h));
    const ni = hdrs.findIndex(h => h.startsWith("nome")), pi = hdrs.findIndex(h => h.startsWith("telefone")), ei = hdrs.findIndex(h => h.startsWith("email")), ai = hdrs.findIndex(h => h.startsWith("endereco"));
    for (const r of data.filter(r => r.some(c => getCellString(c)))) {
      const name = getCellString(r[ni]), phone = getCellString(r[pi]);
      if (!name || !phone) continue;
      const phoneNormalized = phone.replace(/\D/g, "");
      const ref = doc(custCol, `c_${phoneNormalized}`);
      writes.push(b => b.set(ref, { name, phone, phoneNormalized, email: getCellString(r[ei]) || null, address: getCellString(r[ai]) || null, balanceCents: 0, createdAt: serverTimestamp(), updatedAt: serverTimestamp() } as Customer, { merge: true }));
      custCount++;
    }
  }
  if (wb.Sheets["Produtos"]) {
    const rows = XLSX.utils.sheet_to_json(wb.Sheets["Produtos"], { header: 1 }) as unknown[][];
    const [hdr, ...data] = rows;
    const hdrs = (hdr ?? []).map(h => getCellString(h));
    const ni = hdrs.findIndex(h => h.startsWith("nome")), bi = hdrs.findIndex(h => h.startsWith("marca")), qi = hdrs.findIndex(h => h.startsWith("quantidade")), ci = hdrs.findIndex(h => h.startsWith("preco_custo")), si = hdrs.findIndex(h => h.startsWith("preco_venda")), ei = hdrs.findIndex(h => h.startsWith("validade")), ki = hdrs.findIndex(h => h.startsWith("codigo"));
    for (const r of data.filter(r => r.some(c => getCellString(c)))) {
      const name = getCellString(r[ni]), brand = getCellString(r[bi]), qty = Number(r[qi]);
      if (!name || !brand || !qty) continue;
      const code = getCellString(r[ki]);
      const productId = `p_${stableHash(`${brand}|${code}|${name}`.toLowerCase())}`;
      const expiryRaw = getCellString(r[ei]);
      const expiryDate = expiryRaw ? new Date(`${expiryRaw}T00:00:00`) : new Date(Date.now() + 365*86400000);
      const costCents = toCents(r[ci]), sellCents = toCents(r[si]);
      writes.push(b => b.set(doc(prodCol, productId), { name, brand, code: code||null, costPriceCents: costCents, sellingPriceCents: sellCents, createdAt: serverTimestamp(), updatedAt: serverTimestamp() }, { merge: true }));
      writes.push(b => b.set(doc(invCol, `i_${stableHash(`${productId}|${expiryRaw}|${qty}|${costCents}|${sellCents}`)}`), { productId, sku: code||null, productName: name, brand, quantity: qty, costPriceCents: costCents, sellingPriceCents: sellCents, expiryDate, createdAt: serverTimestamp(), updatedAt: serverTimestamp() } as Omit<InventoryItem,"expiryDate">&{expiryDate:Date}, { merge: true }));
      prodCount++;
    }
  }
  for (let i = 0; i < writes.length; i += 400) { const batch = writeBatch(db); writes.slice(i, i+400).forEach(fn => fn(batch)); await batch.commit(); }
  return { customers: custCount, products: prodCount };
}
