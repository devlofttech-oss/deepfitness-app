import { TOTAL_SLOTS } from "@/lib/event";

/**
 * A single public document — `stats/slots` — holds how many heads are already
 * confirmed, so the landing and event pages can show passes remaining without
 * exposing the tickets collection. It is written only by admins, inside the
 * same transaction that approves a booking (see AdminTransactions), and
 * re-synced from the real ticket data whenever an admin opens /admin.
 */
export const SLOTS_COLLECTION = "stats";
export const SLOTS_DOC_ID = "slots";

export interface SlotsDoc {
  confirmedHeads: number;
  totalSlots: number;
  updatedAt?: unknown;
}

export function slotsLeft(confirmedHeads: number): number {
  return Math.max(0, TOTAL_SLOTS - confirmedHeads);
}

export function readConfirmedHeads(data: unknown): number {
  if (!data || typeof data !== "object") return 0;
  const value = (data as { confirmedHeads?: unknown }).confirmedHeads;
  return typeof value === "number" && Number.isFinite(value) && value >= 0 ? value : 0;
}
