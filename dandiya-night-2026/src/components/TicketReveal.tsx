"use client";

import { useEffect, useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import Image from "next/image";
import QRCode from "qrcode";
import type { Ticket, TicketStatus } from "@/lib/types";
import { EMPTY_PARTY, partySummary, rupees } from "@/lib/pricing";
import type { Category } from "@/lib/pricing";
import {
  EVENT_DATE,
  EVENT_NAME,
  EVENT_TIME,
  PRESENTER,
  VENUE_MAP_URL,
  VENUE_NAME,
} from "@/lib/event";
import { formatDateTime } from "@/lib/timestamps";
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

/** Per-person labels; CATEGORY_LABEL is plural, for the counters. */
const PERSON_LABEL: Record<Category, string> = {
  adult: "Adult",
  kid: "Kid",
  student: "Student",
};

function Row({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-start justify-between gap-4 text-xs">
      <span className="text-[var(--muted)]">{label}</span>
      <span className="text-[var(--foreground)] text-right">{value}</span>
    </div>
  );
}

export default function TicketReveal({ ticket }: { ticket: Ticket }) {
  const [qrDataUrl, setQrDataUrl] = useState<string | null>(null);
  const [detailsOpen, setDetailsOpen] = useState(false);

  const copy = statusCopy[ticket.status];
  const party = ticket.party ?? EMPTY_PARTY;
  const attendees = Array.isArray(ticket.attendees) ? ticket.attendees : [];

  useEffect(() => {
    // Nothing to draw unless the booking is verified; the QR only renders in
    // that state, so leaving any stale value alone is harmless.
    if (ticket.status !== "verified") return;
    let cancelled = false;
    QRCode.toDataURL(ticket.id, {
      width: 400,
      margin: 2,
      color: { dark: "#000000", light: "#ffffff" },
    }).then((url) => {
      if (!cancelled) setQrDataUrl(url);
    });
    return () => {
      cancelled = true;
    };
  }, [ticket.id, ticket.status]);

  return (
    <div className="w-full flex flex-col items-center gap-4">
      <motion.div
        initial={{ opacity: 0, rotateX: -12, y: 16 }}
        animate={{ opacity: 1, rotateX: 0, y: 0 }}
        transition={{ duration: 0.6, ease: "easeOut" }}
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

          {ticket.status === "verified" && qrDataUrl && (
            <motion.div
              initial={{ opacity: 0, scale: 0.85 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ delay: 0.2, duration: 0.5 }}
              className="mt-2 bg-white rounded-xl p-3"
            >
              <Image src={qrDataUrl} alt="Your pass QR code" width={260} height={260} />
            </motion.div>
          )}

          {ticket.status === "checked_in" && (
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

          {(ticket.status === "verified" || ticket.status === "checked_in") && (
            <div className="w-full flex flex-col gap-2 mt-4 pt-4 border-t border-dashed border-[var(--border)]">
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
            </div>
          )}

          <div className="w-full flex items-center justify-between text-[10px] text-[var(--muted)] mt-3 pt-3 border-t border-dashed border-[var(--border)] tracking-wide">
            <span>TXN: {ticket.transactionId}</span>
            <span className="text-[var(--gold-2)]">{rupees(ticket.amount ?? 0)}</span>
          </div>

          <button
            type="button"
            onClick={() => setDetailsOpen((open) => !open)}
            aria-expanded={detailsOpen}
            className="text-[11px] uppercase tracking-[0.2em] text-[var(--gold-1)] underline underline-offset-4 mt-1"
          >
            {detailsOpen ? "Hide details" : "View all details"}
          </button>

          <AnimatePresence initial={false}>
            {detailsOpen && (
              <motion.div
                key="details"
                initial={{ opacity: 0, height: 0 }}
                animate={{ opacity: 1, height: "auto" }}
                exit={{ opacity: 0, height: 0 }}
                transition={{ duration: 0.25, ease: "easeOut" }}
                className="w-full overflow-hidden"
              >
                <div className="flex flex-col gap-4 pt-4 mt-1 border-t border-dashed border-[var(--border)] text-left">
                  <div className="flex flex-col gap-1.5">
                    <p className="text-[10px] uppercase tracking-[0.25em] text-[var(--gold-3)]">
                      Booked by
                    </p>
                    <Row label="Name" value={ticket.name} />
                    {ticket.username && <Row label="Username" value={`@${ticket.username}`} />}
                    <Row label="Phone" value={ticket.phone} />
                    {ticket.instagram && (
                      <Row label="Instagram" value={`@${ticket.instagram.replace(/^@/, "")}`} />
                    )}
                  </div>

                  <div className="flex flex-col gap-1.5">
                    <p className="text-[10px] uppercase tracking-[0.25em] text-[var(--gold-3)]">
                      Who is coming
                    </p>
                    {attendees.length === 0 && (
                      <p className="text-xs text-[var(--muted)]">No names on this booking.</p>
                    )}
                    {attendees.map((attendee, i) => (
                      <div key={i} className="flex items-start justify-between gap-4 text-xs">
                        <span className="text-[var(--foreground)]">
                          {attendee.name}
                          {attendee.phone && (
                            <span className="block text-[var(--muted)]">{attendee.phone}</span>
                          )}
                        </span>
                        <span className="text-[var(--muted)] text-right whitespace-nowrap">
                          {PERSON_LABEL[attendee.category] ?? attendee.category}
                          {typeof attendee.age === "number" && !Number.isNaN(attendee.age)
                            ? ` · ${attendee.age} yrs`
                            : ""}
                        </span>
                      </div>
                    ))}
                  </div>

                  <div className="flex flex-col gap-1.5">
                    <p className="text-[10px] uppercase tracking-[0.25em] text-[var(--gold-3)]">
                      Payment
                    </p>
                    <Row label="Amount" value={rupees(ticket.amount ?? 0)} />
                    <Row label="Transaction ID" value={ticket.transactionId} />
                    {formatDateTime(ticket.createdAt) && (
                      <Row label="Booked" value={formatDateTime(ticket.createdAt)} />
                    )}
                    {formatDateTime(ticket.verifiedAt) && (
                      <Row label="Verified" value={formatDateTime(ticket.verifiedAt)} />
                    )}
                    {formatDateTime(ticket.checkedInAt) && (
                      <Row label="Checked in" value={formatDateTime(ticket.checkedInAt)} />
                    )}
                    <Row label="Pass ID" value={ticket.id} />
                  </div>
                </div>
              </motion.div>
            )}
          </AnimatePresence>

          {ticket.status === "rejected" && (
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
