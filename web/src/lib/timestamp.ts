/**
 * Helpers para lidar com timestamps compatíveis com Supabase (ISO string)
 * e legado Firebase (objeto Timestamp).
 */
import type { AppTimestamp } from "./types";

/** Converte qualquer AppTimestamp para Date */
export function toDate(ts: AppTimestamp | null | undefined): Date {
  if (!ts) return new Date(0);
  if (typeof ts === "string") return new Date(ts);
  if (typeof ts === "object" && "toDate" in ts) return (ts as any).toDate();
  if (typeof ts === "object" && "seconds" in ts) return new Date((ts as any).seconds * 1000);
  return new Date(0);
}

/** Converte qualquer AppTimestamp para milissegundos */
export function toMillis(ts: AppTimestamp | null | undefined): number {
  return toDate(ts).getTime();
}

/** Retorna ISO string atual (substitui serverTimestamp()) */
export function nowISO(): string {
  return new Date().toISOString();
}
