/**
 * aiContext.ts
 * Busca um resumo dos dados do usuario no Supabase
 * e monta o contexto para a Bia (assistente IA).
 */
import { databases, DATABASE_ID, COLLECTIONS, Query } from "@/lib/supabase";
import { formatMoney } from "@/lib/money";
import { toDate } from "@/lib/timestamp";
import type { Receivable, Sale, InventoryItem, Customer } from "@/lib/types";

export async function buildUserContext(uid: string): Promise<string> {
  try {
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1).toISOString();

    // Busca paralela de todos os dados necessarios
    const [salesRes, receivablesRes, inventoryRes, customersRes, profileRes] = await Promise.all([
      databases.listDocuments(DATABASE_ID, COLLECTIONS.SALES, [
        Query.equal("userId", uid),
        Query.greaterThanEqual("createdAt", startOfMonth),
        Query.limit(500),
      ]),
      databases.listDocuments(DATABASE_ID, COLLECTIONS.RECEIVABLES, [
        Query.equal("userId", uid),
        Query.limit(500),
      ]),
      databases.listDocuments(DATABASE_ID, COLLECTIONS.INVENTORY, [
        Query.equal("userId", uid),
        Query.limit(500),
      ]),
      databases.listDocuments(DATABASE_ID, COLLECTIONS.CUSTOMERS, [
        Query.equal("userId", uid),
        Query.limit(500),
      ]),
      databases.listDocuments(DATABASE_ID, COLLECTIONS.PROFILES, [
        Query.equal("userId", uid),
        Query.limit(1),
      ]),
    ]);

    // ── Vendas do mes ────────────────────────────────────────────────────────
    const sales = salesRes.documents as unknown as (Sale & { $id: string })[];
    const totalVendasMes = sales.reduce((s, v) => s + (v.totalCents ?? 0), 0);
    const totalRecebidoMes = sales.reduce((s, v) => s + (v.paidCents ?? 0), 0);
    const vendasFiado = sales.filter(v => v.paymentType === "fiado").length;
    const vendasParcelado = sales.filter(v => v.paymentType === "installments").length;

    // Comissao por marca no mes
    const comissaoPorMarca: Record<string, number> = {};
    for (const sale of sales) {
      const items = typeof sale.items === "string" ? JSON.parse(sale.items || "[]") : (sale.items ?? []);
      for (const item of items as any[]) {
        const brand = item.brand || "Outra";
        const comissao = ((item.unitPriceCents ?? 0) - (item.unitCostCents ?? 0)) * (item.quantity ?? 1);
        comissaoPorMarca[brand] = (comissaoPorMarca[brand] ?? 0) + comissao;
      }
    }
    const totalComissaoMes = Object.values(comissaoPorMarca).reduce((s, v) => s + v, 0);

    // ── Recebimentos / Fiado ─────────────────────────────────────────────────
    const receivables = receivablesRes.documents as unknown as (Receivable & { $id: string })[];
    const abertas = receivables.filter(r => r.status !== "paid");
    const totalFiado = abertas.reduce((s, r) => s + (r.amountCents - r.paidCents), 0);
    const vencidas = abertas.filter(r => {
      const due = toDate(r.dueDate);
      return due < now;
    });
    const totalVencido = vencidas.reduce((s, r) => s + (r.amountCents - r.paidCents), 0);
    const venceHoje = abertas.filter(r => {
      const due = toDate(r.dueDate);
      return due.toDateString() === now.toDateString();
    });
    const totalHoje = venceHoje.reduce((s, r) => s + (r.amountCents - r.paidCents), 0);

    // Clientes com fiado
    const customers = customersRes.documents as unknown as (Customer & { $id: string })[];
    const clientesComFiado = customers.filter(c => (c.balanceCents ?? 0) > 0);

    // ── Estoque ──────────────────────────────────────────────────────────────
    const inventory = inventoryRes.documents as unknown as (InventoryItem & { $id: string })[];
    const totalItens = inventory.reduce((s, i) => s + (i.quantity ?? 0), 0);
    const vencendoEm7Dias = inventory.filter(i => {
      try {
        const exp = toDate(i.expiryDate);
        const diff = (exp.getTime() - now.getTime()) / (1000 * 60 * 60 * 24);
        return diff >= 0 && diff <= 7;
      } catch { return false; }
    });
    const vencidos = inventory.filter(i => {
      try {
        const exp = toDate(i.expiryDate);
        return exp < now && (i.quantity ?? 0) > 0;
      } catch { return false; }
    });

    // ── Perfil ───────────────────────────────────────────────────────────────
    const profile = profileRes.documents[0];
    const plano = profile?.planStatus === "pro" ? "Pro" : "Gratuito";
    const brandMargins = profile?.brandMargins
      ? JSON.parse(profile.brandMargins as string)
      : [];

    // ── Monta o contexto ─────────────────────────────────────────────────────
    const mesAtual = now.toLocaleDateString("pt-BR", { month: "long", year: "numeric" });

    let ctx = `\n\n=== DADOS REAIS DA REVENDEDORA (${mesAtual}) ===\n`;
    ctx += `Plano: ${plano}\n`;
    ctx += `Total de clientes: ${customers.length}\n\n`;

    ctx += `VENDAS DO MES:\n`;
    ctx += `- Total vendido: ${formatMoney(totalVendasMes)}\n`;
    ctx += `- Total recebido: ${formatMoney(totalRecebidoMes)}\n`;
    ctx += `- Vendas no fiado: ${vendasFiado}\n`;
    ctx += `- Vendas parceladas: ${vendasParcelado}\n`;
    ctx += `- Numero de vendas: ${sales.length}\n\n`;

    ctx += `COMISSAO DO MES:\n`;
    ctx += `- Total de comissao: ${formatMoney(totalComissaoMes)}\n`;
    if (Object.keys(comissaoPorMarca).length > 0) {
      ctx += `- Por marca:\n`;
      for (const [marca, valor] of Object.entries(comissaoPorMarca).sort((a, b) => b[1] - a[1])) {
        ctx += `  * ${marca}: ${formatMoney(valor)}\n`;
      }
    }
    if (brandMargins.length > 0) {
      ctx += `- Margens configuradas: ${brandMargins.map((b: any) => `${b.brand} ${b.marginPercent}%`).join(", ")}\n`;
    }
    ctx += `\n`;

    ctx += `FIADO E RECEBIMENTOS:\n`;
    ctx += `- Total a receber: ${formatMoney(totalFiado)}\n`;
    ctx += `- Clientes com fiado: ${clientesComFiado.length}\n`;
    if (clientesComFiado.length > 0) {
      ctx += `- Maiores devedores: ${clientesComFiado
        .sort((a, b) => (b.balanceCents ?? 0) - (a.balanceCents ?? 0))
        .slice(0, 3)
        .map(c => `${c.name} (${formatMoney(c.balanceCents ?? 0)})`)
        .join(", ")}\n`;
    }
    ctx += `- Parcelas vencidas: ${vencidas.length} (${formatMoney(totalVencido)})\n`;
    ctx += `- Vence hoje: ${venceHoje.length} parcelas (${formatMoney(totalHoje)})\n\n`;

    ctx += `ESTOQUE:\n`;
    ctx += `- Total de itens em estoque: ${totalItens} unidades\n`;
    ctx += `- Produtos diferentes: ${inventory.length}\n`;
    if (vencendoEm7Dias.length > 0) {
      ctx += `- ATENCAO: ${vencendoEm7Dias.length} produto(s) vencendo nos proximos 7 dias: ${vencendoEm7Dias.map(i => i.productName).join(", ")}\n`;
    }
    if (vencidos.length > 0) {
      ctx += `- ATENCAO: ${vencidos.length} produto(s) VENCIDOS ainda em estoque: ${vencidos.map(i => i.productName).join(", ")}\n`;
    }
    ctx += `\n=== FIM DOS DADOS ===\n`;

    return ctx;
  } catch (err) {
    console.error("aiContext error:", err);
    return "\n[Nao foi possivel carregar os dados da conta no momento]\n";
  }
}
