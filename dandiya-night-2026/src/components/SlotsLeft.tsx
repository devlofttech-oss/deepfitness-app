"use client";

import { useEffect, useState } from "react";
import { motion } from "framer-motion";
import { doc, onSnapshot } from "firebase/firestore";
import { db } from "@/lib/firebase/client";
import { TOTAL_SLOTS } from "@/lib/event";
import { SLOTS_COLLECTION, SLOTS_DOC_ID, readConfirmedHeads, slotsLeft } from "@/lib/slots";

export type SlotsVariant = "pill" | "card";

/**
 * Presentational half — `confirmed: null` means the counter could not be read,
 * and the copy falls back to the static capacity line rather than showing a
 * wrong number.
 */
export function SlotsLeftView({
  confirmed,
  variant = "pill",
}: {
  confirmed: number | null;
  variant?: SlotsVariant;
}) {
  const left = confirmed === null ? null : slotsLeft(confirmed);
  const soldOut = left === 0;
  const filledPct =
    confirmed === null ? 0 : Math.min(100, Math.round((confirmed / TOTAL_SLOTS) * 100));

  if (variant === "pill") {
    return (
      <span className="inline-flex items-center gap-2 text-[11px] uppercase tracking-[0.2em] text-[var(--marigold)] border border-[var(--border)] rounded-full px-4 py-2">
        {left === null ? (
          <>Limited slots &middot; only {TOTAL_SLOTS} passes</>
        ) : soldOut ? (
          <>Sold out &middot; all {TOTAL_SLOTS} passes taken</>
        ) : (
          <>
            <motion.span
              key={left}
              initial={{ scale: 0.7, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              transition={{ type: "spring", stiffness: 320, damping: 18 }}
              className="font-display text-base leading-none text-[var(--gold-1)]"
            >
              {left}
            </motion.span>
            of {TOTAL_SLOTS} passes left
          </>
        )}
      </span>
    );
  }

  return (
    <div className="text-center">
      <motion.p
        key={left ?? "static"}
        initial={{ opacity: 0, y: 6 }}
        animate={{ opacity: 1, y: 0 }}
        className="font-display gold-text text-2xl"
      >
        {left === null
          ? `Only ${TOTAL_SLOTS} passes`
          : soldOut
            ? "Sold out"
            : `${left} of ${TOTAL_SLOTS} passes left`}
      </motion.p>
      <p className="text-xs text-[var(--muted)] mt-1">
        {soldOut
          ? "Call us to check for cancellations or late releases."
          : "Once they are gone, they are gone. Book early."}
      </p>

      {confirmed !== null && (
        <div className="mt-4">
          <div className="h-1.5 rounded-full bg-[var(--surface-2)] overflow-hidden">
            <motion.div
              className="h-full rounded-full"
              initial={{ width: 0 }}
              animate={{ width: `${filledPct}%` }}
              transition={{ duration: 0.6, ease: "easeOut" }}
              style={{ background: "linear-gradient(90deg, #c9962f, #f7e6ac)" }}
            />
          </div>
          <p className="text-[10px] text-[var(--muted)] mt-1.5 uppercase tracking-wide">
            {confirmed} confirmed
          </p>
        </div>
      )}
    </div>
  );
}

/**
 * Live "passes left" readout, counting down as admins approve bookings. Reads
 * the public counter written by AdminTransactions; see src/lib/slots.ts.
 */
export default function SlotsLeft({ variant = "pill" }: { variant?: SlotsVariant }) {
  const [confirmed, setConfirmed] = useState<number | null>(null);

  useEffect(() => {
    const unsub = onSnapshot(
      doc(db, SLOTS_COLLECTION, SLOTS_DOC_ID),
      (snap) => setConfirmed(snap.exists() ? readConfirmedHeads(snap.data()) : 0),
      () => setConfirmed(null)
    );
    return () => unsub();
  }, []);

  return <SlotsLeftView confirmed={confirmed} variant={variant} />;
}
