"use client";

import { useEffect, useState } from "react";
import { AnimatePresence, motion } from "framer-motion";
import { collection, onSnapshot, orderBy, query } from "firebase/firestore";
import { db } from "@/lib/firebase/client";
import { EMPTY_PARTY, partySummary } from "@/lib/pricing";
import { emailToUsername } from "@/lib/username";
import { toWhatsAppNumber } from "@/lib/invite";
import { STATUS_COLOR, STATUS_LABEL } from "@/components/AdminTransactions";
import WhatsAppInvite from "@/components/WhatsAppInvite";
import type { Ticket } from "@/lib/types";

/**
 * One row per ticket, each with its own WhatsApp invite button — built for
 * working down the list by hand. Nothing is sent from here: the button opens
 * WhatsApp with the message typed out and the admin presses send.
 */
export default function AdminInvites() {
  const [items, setItems] = useState<Ticket[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const q = query(collection(db, "tickets"), orderBy("createdAt", "desc"));
    const unsub = onSnapshot(q, (snap) => {
      setItems(snap.docs.map((d) => ({ id: d.id, ...d.data() }) as Ticket));
      setLoading(false);
    });
    return () => unsub();
  }, []);

  if (loading) {
    return (
      <div className="flex justify-center mt-16">
        <div className="w-6 h-6 rounded-full border-2 border-[var(--border)] border-t-[var(--gold-2)] animate-spin" />
      </div>
    );
  }

  if (items.length === 0) {
    return <p className="text-center text-[var(--muted)] text-sm mt-16">No bookings to invite yet.</p>;
  }

  const reachable = items.filter((t) => toWhatsAppNumber(t.phone)).length;

  return (
    <div className="flex flex-col gap-4">
      <p className="text-xs text-[var(--muted)] leading-relaxed">
        {reachable} of {items.length} {items.length === 1 ? "booking" : "bookings"} have a WhatsApp
        number. Each button opens the chat with the invite typed out — you press send.
      </p>

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
            <div className="flex items-start justify-between gap-3">
              <div className="min-w-0">
                <p className="text-sm font-medium truncate">{t.name}</p>
                <p className="text-[11px] uppercase tracking-wide text-[var(--marigold)] mt-0.5">
                  {partySummary(t.party ?? EMPTY_PARTY)}
                </p>
                <p className="text-xs text-[var(--muted)] mt-1">
                  @{t.username || emailToUsername(t.email)}
                </p>
                <p className="text-xs text-[var(--muted)]">{t.phone || "No phone on this booking"}</p>
              </div>
              <span
                className="text-[10px] uppercase tracking-[0.15em] whitespace-nowrap"
                style={{ color: STATUS_COLOR[t.status] }}
              >
                {STATUS_LABEL[t.status]}
              </span>
            </div>

            {toWhatsAppNumber(t.phone) ? (
              <WhatsAppInvite ticket={t} label="Invite on WhatsApp" />
            ) : (
              <span className="text-xs text-[var(--muted)] opacity-70">
                No WhatsApp number — invite this one by phone.
              </span>
            )}
          </motion.div>
        ))}
      </AnimatePresence>
    </div>
  );
}
