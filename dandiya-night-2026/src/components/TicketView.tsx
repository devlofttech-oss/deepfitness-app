"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { AnimatePresence, motion } from "framer-motion";
import { collection, onSnapshot, orderBy, query, where } from "firebase/firestore";
import { db } from "@/lib/firebase/client";
import { useAuth } from "@/lib/firebase/AuthProvider";
import PageShell from "@/components/PageShell";
import TicketReveal from "@/components/TicketReveal";
import GoldButton from "@/components/GoldButton";
import { EMPTY_PARTY, partySummary, rupees } from "@/lib/pricing";
import { formatDateTime } from "@/lib/timestamps";
import type { Ticket, TicketStatus } from "@/lib/types";

const STATUS_LABEL: Record<TicketStatus, string> = {
  pending: "Pending",
  verified: "Confirmed",
  rejected: "Not verified",
  checked_in: "Checked in",
};

const STATUS_COLOR: Record<TicketStatus, string> = {
  pending: "var(--warning)",
  verified: "var(--success)",
  rejected: "var(--danger)",
  checked_in: "var(--success)",
};

function ChevronIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" aria-hidden>
      <path d="M9 5l7 7-7 7" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

export default function TicketView() {
  const { user } = useAuth();
  const [tickets, setTickets] = useState<Ticket[] | undefined>(undefined);
  const [openId, setOpenId] = useState<string | null>(null);

  useEffect(() => {
    if (!user) return;
    const q = query(
      collection(db, "tickets"),
      where("userId", "==", user.uid),
      orderBy("createdAt", "desc")
    );
    const unsub = onSnapshot(q, (snap) => {
      setTickets(snap.docs.map((d) => ({ id: d.id, ...d.data() }) as Ticket));
    });
    return () => unsub();
  }, [user]);

  if (tickets === undefined) {
    return (
      <PageShell className="items-center justify-center">
        <div className="w-6 h-6 rounded-full border-2 border-[var(--border)] border-t-[var(--gold-2)] animate-spin" />
      </PageShell>
    );
  }

  if (tickets.length === 0) {
    return (
      <PageShell className="items-center justify-center text-center">
        <p className="text-[var(--muted)] mb-6">You do not have a pass yet.</p>
        <Link
          href="/event"
          className="gold-btn rounded-xl px-8 py-3 text-sm uppercase tracking-wide"
        >
          Book Now
        </Link>
      </PageShell>
    );
  }

  const open = openId ? tickets.find((t) => t.id === openId) : undefined;

  // One pass open: the QR and everything about that booking.
  if (open) {
    return (
      <PageShell wide>
        <button
          type="button"
          onClick={() => setOpenId(null)}
          className="self-start text-[11px] uppercase tracking-[0.2em] text-[var(--muted)] hover:text-[var(--gold-1)] transition-colors mb-5"
        >
          &larr; All passes
        </button>
        <TicketReveal key={open.id} ticket={open} />
      </PageShell>
    );
  }

  // Otherwise the list, newest first.
  return (
    <PageShell wide>
      <h2 className="font-display gold-text text-3xl text-center mb-2">
        {tickets.length === 1 ? "My Pass" : "My Passes"}
      </h2>
      <p className="text-center text-xs text-[var(--muted)] mb-8">
        Tap a booking to open its QR code and details.
      </p>

      <div className="flex flex-col gap-3">
        <AnimatePresence initial={false}>
          {tickets.map((ticket, i) => {
            const party = ticket.party ?? EMPTY_PARTY;
            return (
              <motion.button
                key={ticket.id}
                type="button"
                layout
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: i * 0.05, duration: 0.3 }}
                whileTap={{ scale: 0.99 }}
                onClick={() => setOpenId(ticket.id)}
                className="gold-border rounded-xl p-4 text-left flex items-center gap-4 hover:border-[var(--gold-3)] transition-colors"
              >
                <span className="flex-1 min-w-0">
                  <span className="flex items-center gap-2">
                    <span
                      className="w-1.5 h-1.5 rounded-full shrink-0"
                      style={{ background: STATUS_COLOR[ticket.status] }}
                    />
                    <span
                      className="text-[10px] uppercase tracking-[0.2em]"
                      style={{ color: STATUS_COLOR[ticket.status] }}
                    >
                      {STATUS_LABEL[ticket.status]}
                    </span>
                  </span>
                  <span className="block text-sm mt-1.5">{partySummary(party)}</span>
                  {formatDateTime(ticket.createdAt) && (
                    <span className="block text-[11px] text-[var(--muted)] mt-0.5">
                      Booked {formatDateTime(ticket.createdAt)}
                    </span>
                  )}
                </span>
                <span className="font-display gold-text text-lg whitespace-nowrap">
                  {rupees(ticket.amount ?? 0)}
                </span>
                <span className="text-[var(--gold-3)] shrink-0">
                  <ChevronIcon />
                </span>
              </motion.button>
            );
          })}
        </AnimatePresence>
      </div>

      <div className="mt-8">
        <Link href="/book" className="block">
          <GoldButton type="button" variant="outline">
            Book Another Pass
          </GoldButton>
        </Link>
      </div>

      <p className="text-[11px] text-[var(--muted)] text-center mt-4 leading-relaxed">
        {tickets.filter((t) => t.status === "pending").length > 0
          ? "Pending bookings update here on their own once we verify the payment."
          : "Each pass is scanned once at the gate and admits everyone on that booking."}
      </p>
    </PageShell>
  );
}

