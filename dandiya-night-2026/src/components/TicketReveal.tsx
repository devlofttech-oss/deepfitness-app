"use client";

import { motion } from "framer-motion";
import Image from "next/image";
import type { TicketStatus } from "@/lib/types";
import { partySummary, rupees, type PartyCounts } from "@/lib/pricing";
import {
  EVENT_DATE,
  EVENT_NAME,
  EVENT_TIME,
  PRESENTER,
  VENUE_MAP_URL,
  VENUE_NAME,
} from "@/lib/event";
import { CalendarIcon, ClockIcon, DandiyaIcon, PinIcon, Toran } from "@/components/Ornaments";

const statusCopy: Record<TicketStatus, { title: string; sub: string; color: string }> = {
  pending: {
    title: "Verification Pending",
    sub: "We are checking your payment. This usually takes a few hours.",
    color: "var(--warning)",
  },
  verified: {
    title: "You Are In",
    sub: "Show this QR code at the gate to check in. One scan, the whole group enters.",
    color: "var(--success)",
  },
  rejected: {
    title: "Payment Not Verified",
    sub: "We could not confirm your transaction. Please book again with the correct ID.",
    color: "var(--danger)",
  },
  checked_in: {
    title: "Checked In",
    sub: "You have already entered the venue. Enjoy the night.",
    color: "var(--success)",
  },
};

export default function TicketReveal({
  status,
  qrDataUrl,
  transactionId,
  party,
  amount,
}: {
  status: TicketStatus;
  qrDataUrl: string | null;
  transactionId: string;
  party: PartyCounts;
  amount: number;
}) {
  const copy = statusCopy[status];

  return (
    <div className="w-full flex flex-col items-center gap-6">
      <motion.div
        initial={{ opacity: 0, rotateX: -18, y: 20 }}
        animate={{ opacity: 1, rotateX: 0, y: 0 }}
        transition={{ duration: 0.7, ease: "easeOut" }}
        className="gold-border rounded-2xl w-full overflow-hidden"
        style={{ perspective: 800 }}
      >
        <Toran className="w-full h-4 text-[var(--gold-3)] opacity-70" />

        <div className="p-7 flex flex-col items-center gap-4">
          <motion.div
            animate={{
              boxShadow: [`0 0 0px ${copy.color}`, `0 0 18px ${copy.color}`, `0 0 0px ${copy.color}`],
            }}
            transition={{ duration: 2.4, repeat: Infinity, ease: "easeInOut" }}
            className="w-2 h-2 rounded-full"
            style={{ background: copy.color }}
          />

          <div className="text-center">
            <p className="text-[9px] uppercase tracking-[0.4em] text-[var(--gold-3)]">
              {PRESENTER}
            </p>
            <p className="font-display gold-text text-2xl mt-1">{EVENT_NAME}</p>
          </div>

          <div className="flex items-center gap-3 text-[var(--gold-2)]">
            <span className="h-px w-8 bg-gradient-to-r from-transparent to-[var(--gold-3)]" />
            <DandiyaIcon size={18} />
            <span className="h-px w-8 bg-gradient-to-l from-transparent to-[var(--gold-3)]" />
          </div>

          <h2 className="font-display text-xl" style={{ color: copy.color }}>
            {copy.title}
          </h2>
          <span className="text-[10px] uppercase tracking-[0.2em] text-[var(--muted)] border border-[var(--border)] rounded-full px-3 py-1">
            {partySummary(party)}
          </span>
          <p className="text-xs text-[var(--muted)] max-w-xs text-center">{copy.sub}</p>

          {status === "verified" && qrDataUrl && (
            <motion.div
              initial={{ opacity: 0, scale: 0.85 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ delay: 0.3, duration: 0.5 }}
              className="mt-2 bg-white rounded-xl p-3"
            >
              <Image src={qrDataUrl} alt="Your pass QR code" width={260} height={260} />
            </motion.div>
          )}

          {status === "checked_in" && (
            <motion.div
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
              transition={{ type: "spring", stiffness: 200, damping: 12, delay: 0.2 }}
              className="mt-2 w-20 h-20 rounded-full flex items-center justify-center"
              style={{ background: "rgba(87, 211, 140, 0.12)", border: "1px solid var(--success)" }}
            >
              <svg width="36" height="36" viewBox="0 0 24 24" fill="none" aria-hidden>
                <path
                  d="M4 12l5 5L20 6"
                  stroke="var(--success)"
                  strokeWidth="2.5"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                />
              </svg>
            </motion.div>
          )}

          {(status === "verified" || status === "checked_in") && (
            <motion.div
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.4, duration: 0.5 }}
              className="w-full flex flex-col gap-2 mt-4 pt-4 border-t border-dashed border-[var(--border)]"
            >
              <div className="flex items-center gap-2.5 text-xs text-[var(--muted)]">
                <span className="text-[var(--gold-3)]">
                  <CalendarIcon size={14} />
                </span>
                <span className="text-[var(--foreground)]">{EVENT_DATE}</span>
              </div>
              <div className="flex items-center gap-2.5 text-xs text-[var(--muted)]">
                <span className="text-[var(--gold-3)]">
                  <ClockIcon size={14} />
                </span>
                <span className="text-[var(--foreground)]">{EVENT_TIME}</span>
              </div>
              <a
                href={VENUE_MAP_URL}
                target="_blank"
                rel="noopener noreferrer"
                className="flex items-center gap-2.5 text-xs text-[var(--muted)] hover:text-[var(--gold-1)] transition-colors w-fit"
              >
                <span className="text-[var(--gold-3)]">
                  <PinIcon size={14} />
                </span>
                <span className="text-[var(--foreground)] underline underline-offset-2">
                  {VENUE_NAME}
                </span>
              </a>
            </motion.div>
          )}

          <div className="w-full flex items-center justify-between text-[10px] text-[var(--muted)] mt-3 pt-3 border-t border-dashed border-[var(--border)] tracking-wide">
            <span>TXN: {transactionId}</span>
            <span className="text-[var(--gold-2)]">{rupees(amount)}</span>
          </div>

          {status === "rejected" && (
            <a
              href="/book"
              className="gold-btn rounded-xl px-8 py-2.5 text-xs uppercase tracking-wide mt-2"
            >
              Book Again
            </a>
          )}
        </div>
      </motion.div>
    </div>
  );
}
