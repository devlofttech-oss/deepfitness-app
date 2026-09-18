"use client";

import { useEffect, useState } from "react";
import { collection, doc, onSnapshot, serverTimestamp, setDoc } from "firebase/firestore";
import { db } from "@/lib/firebase/client";
import { TOTAL_SLOTS } from "@/lib/event";
import { EMPTY_PARTY, rupees, totalPeople } from "@/lib/pricing";
import { SLOTS_COLLECTION, SLOTS_DOC_ID, readConfirmedHeads, slotsLeft } from "@/lib/slots";
import type { Ticket } from "@/lib/types";

interface Stats {
  pending: number;
  confirmedHeads: number;
  pendingHeads: number;
  collected: number;
}

const ZERO: Stats = { pending: 0, confirmedHeads: 0, pendingHeads: 0, collected: 0 };

export default function AdminStats() {
  const [stats, setStats] = useState<Stats>(ZERO);
  const [loaded, setLoaded] = useState(false);
  const [published, setPublished] = useState<number | null>(null);

  useEffect(() => {
    const unsub = onSnapshot(collection(db, "tickets"), (snap) => {
      const next = { ...ZERO };
      snap.docs.forEach((d) => {
        const t = { id: d.id, ...d.data() } as Ticket;
        const heads = totalPeople(t.party ?? EMPTY_PARTY);
        if (t.status === "pending") {
          next.pending += 1;
          next.pendingHeads += heads;
        }
        if (t.status === "verified" || t.status === "checked_in") {
          next.confirmedHeads += heads;
          next.collected += t.amount ?? 0;
        }
      });
      setStats(next);
      setLoaded(true);
    });
    return () => unsub();
  }, []);

  useEffect(() => {
    const unsub = onSnapshot(
      doc(db, SLOTS_COLLECTION, SLOTS_DOC_ID),
      (snap) => setPublished(snap.exists() ? readConfirmedHeads(snap.data()) : 0),
      () => setPublished(null)
    );
    return () => unsub();
  }, []);

  // The public counter is written when a booking is approved; if it ever drifts
  // (a ticket deleted from the console, an approval that failed half way), an
  // admin opening this page puts it back in step with the real tickets.
  useEffect(() => {
    if (!loaded || published === null || published === stats.confirmedHeads) return;
    setDoc(
      doc(db, SLOTS_COLLECTION, SLOTS_DOC_ID),
      {
        confirmedHeads: stats.confirmedHeads,
        totalSlots: TOTAL_SLOTS,
        updatedAt: serverTimestamp(),
      },
      { merge: true }
    ).catch(() => {});
  }, [loaded, published, stats.confirmedHeads]);

  const left = slotsLeft(stats.confirmedHeads);
  const filled = Math.min(100, Math.round((stats.confirmedHeads / TOTAL_SLOTS) * 100));

  const cells = [
    { label: "Confirmed", value: String(stats.confirmedHeads) },
    { label: "Slots left", value: String(left) },
    { label: "Pending", value: `${stats.pending} (${stats.pendingHeads})` },
    { label: "Collected", value: rupees(stats.collected) },
  ];

  return (
    <div className="gold-border rounded-2xl p-4 mb-6">
      <div className="grid grid-cols-2 gap-x-4 gap-y-3">
        {cells.map((c) => (
          <div key={c.label}>
            <p className="text-[10px] uppercase tracking-[0.2em] text-[var(--muted)]">{c.label}</p>
            <p className="font-display gold-text text-xl tabular-nums leading-tight">{c.value}</p>
          </div>
        ))}
      </div>

      <div className="mt-4">
        <div className="h-1.5 rounded-full bg-[var(--surface-2)] overflow-hidden">
          <div
            className="h-full rounded-full transition-[width] duration-500"
            style={{
              width: `${filled}%`,
              background: "linear-gradient(90deg, #c9962f, #f7e6ac)",
            }}
          />
        </div>
        <p className="text-[10px] text-[var(--muted)] mt-1.5">
          {stats.confirmedHeads} of {TOTAL_SLOTS} passes confirmed
          {published !== null && published !== stats.confirmedHeads && " · syncing public counter…"}
        </p>
      </div>
    </div>
  );
}
