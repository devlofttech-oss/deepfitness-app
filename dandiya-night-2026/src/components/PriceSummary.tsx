"use client";

import { AnimatePresence, motion } from "framer-motion";
import { LATE_PRICE_NOTE, rupees, type Quote } from "@/lib/pricing";

export default function PriceSummary({ quote }: { quote: Quote }) {
  if (quote.people === 0) return null;

  return (
    <motion.div
      layout
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      className="gold-border rounded-2xl p-4 pattern-weave"
    >
      <p className="text-[10px] uppercase tracking-[0.25em] text-[var(--gold-3)] mb-3">
        Your total
      </p>

      <div className="flex flex-col gap-2">
        <AnimatePresence initial={false}>
          {quote.lines.map((line) => (
            <motion.div
              key={line.label}
              layout
              initial={{ opacity: 0, x: -6 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: 6 }}
              transition={{ duration: 0.2 }}
              className="flex items-start justify-between gap-4 text-xs"
            >
              <span className="text-[var(--foreground)]/90">
                {line.label}
                <span className="text-[var(--muted)]">
                  {line.qty > 1 ? ` × ${line.qty}` : ""} @ {rupees(line.unit)}
                </span>
                {line.note && (
                  <span className="block text-[10px] text-[var(--muted)] mt-0.5">{line.note}</span>
                )}
              </span>
              <span className="tabular-nums whitespace-nowrap">{rupees(line.amount)}</span>
            </motion.div>
          ))}
        </AnimatePresence>
      </div>

      <div className="flex items-center justify-between mt-4 pt-3 border-t border-[var(--border)]">
        <span className="text-xs uppercase tracking-wide text-[var(--muted)]">
          {quote.people} {quote.people === 1 ? "person" : "people"}
        </span>
        <motion.span
          key={quote.total}
          initial={{ scale: 0.92, opacity: 0.6 }}
          animate={{ scale: 1, opacity: 1 }}
          transition={{ type: "spring", stiffness: 320, damping: 18 }}
          className="font-display gold-text text-3xl tabular-nums"
        >
          {rupees(quote.total)}
        </motion.span>
      </div>

      <p className="text-[10px] text-[var(--muted)] mt-3 leading-relaxed">
        {quote.late
          ? "Late pricing is in effect — a flat rate applies per person."
          : `Bundles are applied automatically at the best rate. ${LATE_PRICE_NOTE}`}
      </p>
    </motion.div>
  );
}
