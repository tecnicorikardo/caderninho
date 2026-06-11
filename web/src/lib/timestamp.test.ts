import { describe, it, expect } from "vitest";
import { toDate, toMillis, nowISO } from "./timestamp";

describe("timestamp.ts - toDate", () => {
  it("converte ISO string para Date", () => {
    const iso = "2026-06-11T10:00:00.000Z";
    const date = toDate(iso);
    expect(date).toBeInstanceOf(Date);
    expect(date.toISOString()).toBe(iso);
  });

  it("converte objeto Timestamp (Firebase legado) para Date", () => {
    const firebaseTimestamp = {
      seconds: 1609459200, // 2021-01-01 00:00:00 UTC
      nanoseconds: 0,
    };
    const date = toDate(firebaseTimestamp);
    expect(date).toBeInstanceOf(Date);
    expect(date.getTime()).toBe(1609459200000);
  });

  it("converte objeto com método toDate para Date", () => {
    const mockTimestamp = {
      toDate: () => new Date("2026-06-11T10:00:00.000Z"),
    };
    const date = toDate(mockTimestamp as any);
    expect(date).toBeInstanceOf(Date);
    expect(date.toISOString()).toBe("2026-06-11T10:00:00.000Z");
  });

  it("retorna Date epoch (1970) para valores nulos", () => {
    expect(toDate(null).getTime()).toBe(0);
    expect(toDate(undefined).getTime()).toBe(0);
  });
});

describe("timestamp.ts - toMillis", () => {
  it("converte ISO string para milissegundos", () => {
    const iso = "2026-06-11T10:00:00.000Z";
    const millis = toMillis(iso);
    expect(millis).toBe(new Date(iso).getTime());
  });

  it("converte objeto Timestamp para milissegundos", () => {
    const firebaseTimestamp = {
      seconds: 1609459200,
      nanoseconds: 0,
    };
    const millis = toMillis(firebaseTimestamp);
    expect(millis).toBe(1609459200000);
  });

  it("retorna 0 para valores nulos", () => {
    expect(toMillis(null)).toBe(0);
    expect(toMillis(undefined)).toBe(0);
  });
});

describe("timestamp.ts - nowISO", () => {
  it("retorna string ISO válida", () => {
    const iso = nowISO();
    expect(typeof iso).toBe("string");
    expect(iso).toMatch(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$/);
  });

  it("retorna timestamp recente (dentro de 1 segundo)", () => {
    const before = Date.now();
    const iso = nowISO();
    const after = Date.now();
    const isoMillis = new Date(iso).getTime();
    expect(isoMillis).toBeGreaterThanOrEqual(before);
    expect(isoMillis).toBeLessThanOrEqual(after);
  });
});
