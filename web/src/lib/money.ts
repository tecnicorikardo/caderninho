export function toCents(value: unknown): number {
  // Número direto (ex: vindo de e.target.valueAsNumber)
  if (typeof value === "number" && Number.isFinite(value)) return Math.round(value * 100);
  if (typeof value === "string") {
    const s = value.trim();
    if (!s) return 0;
    // Se tem vírgula como separador decimal (formato BR: "1.234,56")
    if (s.includes(",")) {
      const normalized = s.replace(/\./g, "").replace(",", ".");
      const n = Number(normalized);
      if (Number.isFinite(n)) return Math.round(n * 100);
    }
    // Sem vírgula: pode ser "100", "100.50" (ponto decimal), "1000.00"
    // NÃO remover o ponto — ele é decimal aqui
    const n = Number(s);
    if (Number.isFinite(n)) return Math.round(n * 100);
  }
  return 0;
}

export function formatMoney(cents: number): string {
  return (cents / 100).toLocaleString("pt-BR", { style: "currency", currency: "BRL" });
}

