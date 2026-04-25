import { useMemo, useState } from "react";
import * as XLSX from "xlsx";
import { collection, doc, serverTimestamp, writeBatch } from "firebase/firestore";
import { db } from "@/lib/firebase";
import { toCents } from "@/lib/money";
import type { Customer, Product, InventoryItem } from "@/lib/types";

function normalizePhone(phone: string): string {
  return phone.replace(/\D/g, "");
}

function stableHash(input: string): string {
  let h = 2166136261;
  for (let i = 0; i < input.length; i += 1) {
    h ^= input.charCodeAt(i);
    h = Math.imul(h, 16777619);
  }
  return (h >>> 0).toString(36);
}

function getCellString(value: unknown): string {
  if (value == null) return "";
  return String(value).trim();
}

function parseSheet(rows: unknown[][]) {
  const [headerRow, ...dataRows] = rows;
  const headers = (headerRow ?? []).map((h) => getCellString(h));
  return dataRows
    .filter((r) => r.some((c) => getCellString(c) !== ""))
    .map((r) => {
      const obj: Record<string, unknown> = {};
      headers.forEach((h, idx) => {
        if (!h) return;
        obj[h] = r[idx];
      });
      return obj;
    });
}

async function commitBatches(writes: Array<(batch: ReturnType<typeof writeBatch>) => void>) {
  const chunkSize = 400;
  for (let i = 0; i < writes.length; i += chunkSize) {
    const batch = writeBatch(db);
    const chunk = writes.slice(i, i + chunkSize);
    for (const apply of chunk) apply(batch);
    await batch.commit();
  }
}

export default function ImportWizard({
  uid,
  onDone,
  onBack,
}: {
  uid: string;
  onDone: () => void;
  onBack: () => void;
}) {
  const [file, setFile] = useState<File | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [summary, setSummary] = useState<{ customers: number; products: number; inventory: number } | null>(null);

  const accept = useMemo(() => ".xlsx,.xls,.csv", []);

  async function parseAndSummarize(selected: File) {
    const buffer = await selected.arrayBuffer();
    const wb = XLSX.read(buffer, { type: "array" });
    const customersSheet = wb.Sheets["Clientes"];
    const productsSheet = wb.Sheets["Produtos"];
    const inventorySheet = wb.Sheets["Estoque"];

    if (!customersSheet && !productsSheet && !inventorySheet) {
      throw new Error("Planilha inválida. Use o modelo com abas Clientes/Produtos/Estoque.");
    }

    const customersRows = customersSheet ? (XLSX.utils.sheet_to_json(customersSheet, { header: 1 }) as unknown[][]) : [];
    const productsRows = productsSheet ? (XLSX.utils.sheet_to_json(productsSheet, { header: 1 }) as unknown[][]) : [];
    const inventoryRows = inventorySheet ? (XLSX.utils.sheet_to_json(inventorySheet, { header: 1 }) as unknown[][]) : [];

    const customers = customersRows.length > 1 ? parseSheet(customersRows) : [];
    const products = productsRows.length > 1 ? parseSheet(productsRows) : [];
    const inventory = inventoryRows.length > 1 ? parseSheet(inventoryRows) : [];

    setSummary({ customers: customers.length, products: products.length, inventory: inventory.length });
    return { customers, products, inventory };
  }

  async function onFileChange(e: React.ChangeEvent<HTMLInputElement>) {
    const selected = e.target.files?.[0] ?? null;
    setError(null);
    setFile(selected);
    setSummary(null);

    if (!selected) return;
    try {
      await parseAndSummarize(selected);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Falha ao ler a planilha.");
    }
  }

  async function doImport() {
    if (!file) return;
    setBusy(true);
    setError(null);
    try {
      const { customers, products, inventory } = await parseAndSummarize(file);

      const customersCol = collection(db, "users", uid, "customers");
      const productsCol = collection(db, "users", uid, "products");
      const inventoryCol = collection(db, "users", uid, "inventory");

      const productIdByKey = new Map<string, string>();
      const writes: Array<(batch: ReturnType<typeof writeBatch>) => void> = [];

      for (const row of customers) {
        const name = getCellString(row["name*"] ?? row["name"]);
        const phone = getCellString(row["phone*"] ?? row["phone"]);
        if (!name || !phone) continue;

        const phoneNormalized = normalizePhone(phone);
        const id = `c_${phoneNormalized}`;
        const ref = doc(customersCol, id);

        const data: Customer = {
          name,
          phone,
          phoneNormalized,
          email: getCellString(row["email"]) || null,
          address: getCellString(row["address"]) || null,
          balanceCents: 0,
          createdAt: serverTimestamp(),
          updatedAt: serverTimestamp(),
        };

        writes.push((b) => b.set(ref, data, { merge: true }));
      }

      for (const row of products) {
        const name = getCellString(row["name*"] ?? row["name"]);
        const brand = getCellString(row["brand*"] ?? row["brand"]);
        if (!name || !brand) continue;

        const code = getCellString(row["code"]) || "";
        const key = `${brand}|${code}|${name}`.toLowerCase();
        const id = `p_${stableHash(key)}`;
        productIdByKey.set(key, id);

        const ref = doc(productsCol, id);
        const data: Product = {
          name,
          brand,
          code: code || null,
          costPriceCents: toCents(row["costPrice"]),
          sellingPriceCents: toCents(row["sellingPrice"]),
          createdAt: serverTimestamp(),
          updatedAt: serverTimestamp(),
        };

        writes.push((b) => b.set(ref, data, { merge: true }));
      }

      for (const row of inventory) {
        const productCode = getCellString(row["productCode"]);
        const productName = getCellString(row["productName*"] ?? row["productName"]);
        const brand = getCellString(row["brand*"] ?? row["brand"]);
        const quantity = Number(row["quantity*"] ?? row["quantity"]);
        const expiryRaw = getCellString(row["expiryDate* (YYYY-MM-DD)"] ?? row["expiryDate"]);

        if (!productName || !brand || !quantity || !expiryRaw) continue;

        const key = `${brand}|${productCode}|${productName}`.toLowerCase();
        const productId = productIdByKey.get(key) ?? `p_${stableHash(`${brand}||${productName}`.toLowerCase())}`;
        if (!productIdByKey.has(key)) {
          productIdByKey.set(key, productId);
          const prodRef = doc(productsCol, productId);
          writes.push((b) =>
            b.set(
              prodRef,
              {
                name: productName,
                brand,
                code: productCode || null,
                createdAt: serverTimestamp(),
                updatedAt: serverTimestamp(),
              } satisfies Partial<Product>,
              { merge: true },
            ),
          );
        }

        const expiryDate = new Date(`${expiryRaw}T00:00:00`);
        const invKey = `${productId}|${expiryRaw}|${quantity}|${row["costPrice*"]}|${row["sellingPrice*"]}`;
        const invId = `i_${stableHash(invKey)}`;
        const ref = doc(inventoryCol, invId);

        const data: Omit<InventoryItem, "expiryDate"> & { expiryDate: Date } = {
          productId,
          sku: null,
          productName,
          brand,
          quantity: Number.isFinite(quantity) ? quantity : 0,
          costPriceCents: toCents(row["costPrice*"] ?? row["costPrice"]),
          sellingPriceCents: toCents(row["sellingPrice*"] ?? row["sellingPrice"]),
          expiryDate,
          createdAt: serverTimestamp(),
          updatedAt: serverTimestamp(),
        };

        writes.push((b) => b.set(ref, data, { merge: true }));
      }

      await commitBatches(writes);
      onDone();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Falha ao importar.");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="rounded-xl bg-white border p-5">
      <h2 className="text-lg font-semibold">Importação</h2>
      <p className="text-sm text-gray-700 mt-1">
        Envie a planilha (XLSX) com abas <span className="font-medium">Clientes</span>,{" "}
        <span className="font-medium">Produtos</span> e <span className="font-medium">Estoque</span>.
      </p>

      <div className="mt-4">
        <input type="file" accept={accept} onChange={onFileChange} />
      </div>

      {summary ? (
        <div className="mt-4 text-sm text-gray-800">
          <div>Clientes: {summary.customers}</div>
          <div>Produtos: {summary.products}</div>
          <div>Estoque: {summary.inventory}</div>
        </div>
      ) : null}

      {error ? <p className="mt-4 text-sm text-red-700">{error}</p> : null}

      <div className="mt-5 flex gap-3">
        <button className="rounded-lg border px-4 py-3 min-h-12" onClick={onBack} disabled={busy}>
          Voltar
        </button>
        <button
          className="rounded-lg bg-gray-900 text-white px-4 py-3 min-h-12 disabled:opacity-60"
          onClick={doImport}
          disabled={busy || !file}
        >
          {busy ? "Importando…" : "Importar"}
        </button>
      </div>
    </div>
  );
}

