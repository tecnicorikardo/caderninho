import { describe, it, expect } from "vitest";
import { toCents, formatMoney } from "./money";

describe("money.ts - toCents", () => {
  it("converte número para centavos", () => {
    expect(toCents(10)).toBe(1000);
    expect(toCents(1.5)).toBe(150);
    expect(toCents(0.01)).toBe(1);
  });

  it("converte string com vírgula (formato BR) para centavos", () => {
    expect(toCents("1.234,56")).toBe(123456);
    expect(toCents("10,50")).toBe(1050);
    expect(toCents("0,99")).toBe(99);
  });

  it("converte string com ponto decimal (formato US) para centavos", () => {
    expect(toCents("100.50")).toBe(10050);
    expect(toCents("1000.00")).toBe(100000);
    expect(toCents("10.5")).toBe(1050);
  });

  it("converte string vazia para 0", () => {
    expect(toCents("")).toBe(0);
    expect(toCents("   ")).toBe(0);
  });

  it("converte valores inválidos para 0", () => {
    expect(toCents(null)).toBe(0);
    expect(toCents(undefined)).toBe(0);
    expect(toCents(NaN)).toBe(0);
    expect(toCents(Infinity)).toBe(0);
    expect(toCents("abc")).toBe(0);
  });

  it("arredonda corretamente", () => {
    expect(toCents(10.555)).toBe(1056); // Arredonda para cima
    expect(toCents(10.554)).toBe(1055); // Arredonda para baixo
  });
});

describe("money.ts - formatMoney", () => {
  it("formata centavos em reais (formato BR)", () => {
    // Usa regex para ignorar espaços não-quebráveis que podem variar
    expect(formatMoney(1000)).toMatch(/R\$\s*10,00/);
    expect(formatMoney(1050)).toMatch(/R\$\s*10,50/);
    expect(formatMoney(123456)).toMatch(/R\$\s*1\.234,56/);
  });

  it("formata valores pequenos", () => {
    expect(formatMoney(1)).toMatch(/R\$\s*0,01/);
    expect(formatMoney(99)).toMatch(/R\$\s*0,99/);
  });

  it("formata zero", () => {
    expect(formatMoney(0)).toMatch(/R\$\s*0,00/);
  });

  it("formata valores negativos", () => {
    expect(formatMoney(-1000)).toMatch(/-R\$\s*10,00/);
    expect(formatMoney(-1050)).toMatch(/-R\$\s*10,50/);
  });
});
