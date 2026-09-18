"use client";

import { useEffect, useState } from "react";
import { AnimatePresence, motion } from "framer-motion";
import {
  collection,
  doc,
  onSnapshot,
  orderBy,
  query,
  runTransaction,
  serverTimestamp,
  updateDoc,
} from "firebase/firestore";
import { db } from "@/lib/firebase/client";
import { EMPTY_PARTY, partySummary, rupees, totalPeople } from "@/lib/pricing";
import { TOTAL_SLOTS } from "@/lib/event";
import { SLOTS_COLLECTION, SLOTS_DOC_ID, readConfirmedHeads } from "@/lib/slots";
import type { Ticket, TicketStatus } from "@/lib/types";

const STATUS_LABEL: Record<TicketStatus, string> = {
  pending: "Pending",
  verified: "Verified",
  rejected: "Rejected",
  checked_in: "Checked In",
};

const STATUS_COLOR: Record<TicketStatus, string> = {
  pending: "var(--warning)",
  verified: "var(--success)",
  rejected: "var(--danger)",
  checked_in: "var(--success)",
};

export function AttendeeList({ ticket }: { ticket: Ticket }) {
  if (!Array.isArray(ticket.attendees) || ticket.attendees.length === 0) return null;

  return (
    <div className="text-xs mt-2 space-y-0.5">
      {ticket.attendees.map((a, i) => (
        <p key={i}>
          <span className="text-[var(--muted)] capitalize">{a.category}: </span>
          <span className="text-[var(--foreground)]">{a.name}</span>
          {typeof a.age === "number" && !Number.isNaN(a.age) && (
            <span className="text-[var(--muted)]"> ({a.age} yrs)</span>
          )}
          {a.phone && <span className="text-[var(--muted)]"> · {a.phone}</span>}
        </p>
      ))}
    </div>
  );
}

export default function AdminTransactions() {
  const [items, setItems] = useState<Ticket[]>([]);
  const [busyId, setBusyId] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    const q = query(collection(db, "tickets"), orderBy("createdAt", "desc"));
    const unsub = onSnapshot(q, (snap) => {
      setItems(snap.docs.map((d) => ({ id: d.id, ...d.data() }) as Ticket));
      setLoading(false);
    });
    return () => unsub();
  }, []);

  /**
   * Approving a booking both verifies the ticket and books its heads against
   * the public slot counter, in one transaction — so two admins approving at
   * the same moment can never lose a count.
   */
  async function verify(id: string) {
    setBusyId(id);
    setError("");
    try {
      await runTransaction(db, async (tx) => {
        const ticketRef = doc(db, "tickets", id);
        const slotsRef = doc(db, SLOTS_COLLECTION, SLOTS_DOC_ID);
        const ticketSnap = await tx.get(ticketRef);
        const slotsSnap = await tx.get(slotsRef);

        if (!ticketSnap.exists()) throw new Error("MISSING");
        const ticket = ticketSnap.data() as Ticket;
        if (ticket.status !== "pending") throw new Error("NOT_PENDING");

        const heads = totalPeople(ticket.party ?? EMPTY_PARTY);
        const confirmed = slotsSnap.exists() ? readConfirmedHeads(slotsSnap.data()) : 0;

        tx.update(ticketRef, { status: "verified", verifiedAt: serverTimestamp() });
        tx.set(
          slotsRef,
          {
            confirmedHeads: confirmed + heads,
            totalSlots: TOTAL_SLOTS,
            updatedAt: serverTimestamp(),
          },
          { merge: true }
        );
      });
    } catch (err) {
      const reason = err instanceof Error ? err.message : "";
      setError(
        reason === "NOT_PENDING"
          ? "That booking was already handled by someone else."
          : "Could not approve this booking. Please try again."
      );
    } finally {
      setBusyId(null);
    }
  }

  async function reject(id: string) {
    setBusyId(id);
    try {
      await updateDoc(doc(db, "tickets", id), { status: "rejected" });
    } finally {
      setBusyId(null);
    }
  }

  if (loading) {
    return (
      <div className="flex justify-center mt-16">
        <div className="w-6 h-6 rounded-full border-2 border-[var(--border)] border-t-[var(--gold-2)] animate-spin" />
      </div>
    );
  }

  if (items.length === 0) {
    return <p className="text-center text-[var(--muted)] text-sm mt-16">No bookings yet.</p>;
  }

  return (
    <div className="flex flex-col gap-4">
      {error && (
        <p className="text-xs text-[var(--danger)] border border-[var(--danger)]/40 rounded-lg px-3 py-2">
          {error}
        </p>
      )}
      <AnimatePresence>
        {items.map((t) => (
          <motion.div
            key={t.id}
            layout
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.3 }}
            className="gold-border rounded-xl p-4 flex flex-col gap-3"
          >
            <div>
              <div className="flex items-start justify-between gap-3">
                <p className="text-sm font-medium">{t.name}</p>
                <span className="font-display gold-text text-lg whitespace-nowrap">
                  {rupees(t.amount ?? 0)}
                </span>
              </div>
              <p className="text-[11px] uppercase tracking-wide text-[var(--marigold)] mt-0.5">
                {partySummary(t.party ?? EMPTY_PARTY)}
              </p>
              <p className="text-xs text-[var(--muted)] mt-1">{t.email}</p>
              <p className="text-xs text-[var(--muted)]">{t.phone}</p>
              {t.instagram && (
                <p className="text-xs text-[var(--muted)]">
                  Instagram: @{t.instagram.replace(/^@/, "")}
                </p>
              )}

              <AttendeeList ticket={t} />

              <p className="text-xs mt-2 tracking-wide">
                TXN: <span className="text-[var(--foreground)]">{t.transactionId}</span>
              </p>
              {t.referralCode && (
                <p className="text-xs tracking-wide">
                  Referral: <span className="text-[var(--foreground)]">{t.referralCode}</span>
                </p>
              )}
            </div>

            {t.status === "pending" ? (
              <div className="flex gap-3">
                <button
                  onClick={() => verify(t.id)}
                  disabled={busyId === t.id}
                  className="flex-1 rounded-lg py-2 text-xs uppercase tracking-wide gold-btn disabled:opacity-50"
                >
                  Approve
                </button>
                <button
                  onClick={() => reject(t.id)}
                  disabled={busyId === t.id}
                  className="flex-1 rounded-lg py-2 text-xs uppercase tracking-wide border border-[var(--danger)] text-[var(--danger)] hover:bg-[var(--danger)]/10 disabled:opacity-50"
                >
                  Reject
                </button>
              </div>
            ) : (
              <span
                className="text-xs uppercase tracking-wide w-fit"
                style={{ color: STATUS_COLOR[t.status] }}
              >
                {STATUS_LABEL[t.status]}
              </span>
            )}
          </motion.div>
        ))}
      </AnimatePresence>
    </div>
  );
}
