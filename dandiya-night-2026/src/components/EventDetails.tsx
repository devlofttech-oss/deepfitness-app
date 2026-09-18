"use client";

import Link from "next/link";
import { motion } from "framer-motion";
import { useAuth } from "@/lib/firebase/AuthProvider";
import { useIsRegistrationOpen } from "@/lib/launch";
import {
  ABOUT,
  CONTACT_PHONES,
  EVENT_AT,
  EVENT_DATE,
  EVENT_NAME,
  EVENT_SUBTAGLINE,
  EVENT_TAGLINE,
  EVENT_TIME,
  HIGHLIGHTS,
  PRESENTER,
  VENUE_ADDRESS,
  VENUE_NAME,
  VENUE_MAP_URL,
} from "@/lib/event";
import { KID_AGE_LIMIT, LATE_PRICE_NOTE, PRICE_TABLE, RATE, isLatePricing, rupees } from "@/lib/pricing";
import Countdown from "@/components/Countdown";
import SlotsLeft from "@/components/SlotsLeft";
import {
  CalendarIcon,
  ClockIcon,
  DandiyaIcon,
  GhungrooIcon,
  HIGHLIGHT_ICONS,
  KalashIcon,
  LotusIcon,
  Mandala,
  MarigoldIcon,
  PaisleyIcon,
  PhoneIcon,
  PinIcon,
  RangoliCorner,
  SectionDivider,
} from "@/components/Ornaments";

/** The four rules people most need before they book — full list lives on /rules. */
const KEY_RULES = [
  "Bookings are non-refundable, non-cancellable and non-transferable.",
  "Outside dandiya sticks, food, drinks, alcohol and cigarettes are not allowed. Sticks are provided at the venue.",
  `Kids below ${KID_AGE_LIMIT} are admitted only with parents — ID proof is mandatory for age verification.`,
  "Traditional or decent wear is appreciated. No vulgar behaviour will be tolerated.",
];

export default function EventDetails() {
  const { user } = useAuth();
  const { open } = useIsRegistrationOpen();
  const ctaHref = user ? "/book" : "/signup";
  const late = isLatePricing();

  return (
    <main className="flex-1 w-full max-w-lg mx-auto px-6 py-8 pb-32 relative overflow-hidden">
      <Mandala
        className="pointer-events-none absolute -top-20 -right-24 w-64 h-64 text-[var(--gold-3)] opacity-[0.10]"
        spin={160}
      />

      {/* Poster header */}
      <motion.div
        initial={{ opacity: 0, scale: 0.97 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ duration: 0.5 }}
        className="gold-border rounded-2xl p-6 text-center pattern-weave relative overflow-hidden"
      >
        <RangoliCorner className="pointer-events-none absolute top-0 left-0 w-20 h-20 text-[var(--gold-3)] opacity-25" />
        <RangoliCorner className="pointer-events-none absolute top-0 right-0 w-20 h-20 text-[var(--gold-3)] opacity-25 scale-x-[-1]" />

        <p className="text-[10px] uppercase tracking-[0.4em] text-[var(--gold-3)]">
          {PRESENTER}
        </p>
        <h1 className="font-display gold-text text-4xl mt-2 leading-tight">{EVENT_NAME}</h1>
        <div className="my-4 flex items-center justify-center gap-3 text-[var(--gold-2)]">
          <span className="h-px w-8 bg-gradient-to-r from-transparent to-[var(--gold-3)]" />
          <DandiyaIcon size={20} />
          <span className="h-px w-8 bg-gradient-to-l from-transparent to-[var(--gold-3)]" />
        </div>
        <p className="font-display text-lg">{EVENT_TAGLINE}</p>
        <p className="text-[10px] uppercase tracking-[0.3em] text-[var(--marigold)] mt-1.5">
          {EVENT_SUBTAGLINE}
        </p>
        <div className="mt-4 flex items-center justify-center gap-4 text-[var(--gold-3)] opacity-80">
          <PaisleyIcon size={16} />
          <KalashIcon size={18} />
          <GhungrooIcon size={16} />
          <PaisleyIcon size={16} className="scale-x-[-1]" />
        </div>
      </motion.div>

      <motion.div
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.12, duration: 0.5 }}
        className="flex flex-wrap gap-2 mt-4"
      >
        <span className="text-[10px] uppercase tracking-wide bg-[var(--surface-2)] border border-[var(--border)] rounded-full px-3 py-1.5">
          Garba &amp; Dandiya
        </span>
        <span className="text-[10px] uppercase tracking-wide bg-[var(--surface-2)] border border-[var(--border)] rounded-full px-3 py-1.5">
          Open-air field
        </span>
        <span className="text-[10px] uppercase tracking-wide bg-[var(--surface-2)] border border-[var(--border)] rounded-full px-3 py-1.5">
          All ages welcome
        </span>
      </motion.div>

      {/* When & where */}
      <motion.div
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.2, duration: 0.5 }}
        className="flex flex-col gap-3 mt-6 text-sm"
      >
        <div className="flex items-center gap-3 text-[var(--muted)]">
          <span className="text-[var(--gold-3)]">
            <CalendarIcon size={16} />
          </span>
          <span className="text-[var(--foreground)]">{EVENT_DATE}</span>
        </div>
        <div className="flex items-center gap-3 text-[var(--muted)]">
          <span className="text-[var(--gold-3)]">
            <ClockIcon size={16} />
          </span>
          <span className="text-[var(--foreground)]">{EVENT_TIME}</span>
        </div>
        <a
          href={VENUE_MAP_URL}
          target="_blank"
          rel="noopener noreferrer"
          className="flex items-start gap-3 text-[var(--muted)] hover:text-[var(--gold-1)] transition-colors"
        >
          <span className="text-[var(--gold-3)] mt-0.5">
            <PinIcon size={16} />
          </span>
          <span>
            <span className="text-[var(--foreground)] underline underline-offset-2">
              {VENUE_NAME}
            </span>
            <span className="block text-xs mt-0.5 leading-relaxed">{VENUE_ADDRESS}</span>
          </span>
        </a>
      </motion.div>

      <motion.div
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.28, duration: 0.5 }}
        className="gold-border rounded-2xl p-5 mt-6"
      >
        <Countdown target={EVENT_AT} />
      </motion.div>

      <SectionDivider icon={LotusIcon} className="mt-8" />

      {/* About */}
      <motion.section
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.34, duration: 0.5 }}
        className="mt-8"
      >
        <h2 className="text-[10px] uppercase tracking-[0.3em] text-[var(--gold-3)] mb-2">
          About the night
        </h2>
        <p className="text-sm text-[var(--foreground)]/90 leading-relaxed">{ABOUT}</p>
      </motion.section>

      {/* Highlights */}
      <motion.section
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.42, duration: 0.5 }}
        className="mt-8"
      >
        <h2 className="text-[10px] uppercase tracking-[0.3em] text-[var(--gold-3)] mb-3">
          Highlights
        </h2>
        <div className="grid grid-cols-2 gap-3">
          {HIGHLIGHTS.map((label) => {
            const Icon = HIGHLIGHT_ICONS[label] ?? MarigoldIcon;
            return (
              <div
                key={label}
                className="gold-border rounded-xl p-4 flex flex-col items-center gap-2 text-center"
              >
                <span className="text-[var(--gold-2)]">
                  <Icon size={22} />
                </span>
                <span className="text-xs leading-snug">{label}</span>
              </div>
            );
          })}
        </div>
      </motion.section>

      <SectionDivider icon={KalashIcon} className="mt-8" />

      {/* Prices */}
      <motion.section
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.5, duration: 0.5 }}
        className="mt-8"
      >
        <h2 className="text-[10px] uppercase tracking-[0.3em] text-[var(--gold-3)] mb-3">
          Entry prices
        </h2>
        <div className="gold-border rounded-2xl divide-y divide-[var(--border)]">
          {PRICE_TABLE.map((row) => (
            <div key={row.label} className="flex items-start justify-between gap-4 px-4 py-3">
              <span className="text-sm">
                {row.label}
                {row.note && (
                  <span className="block text-[11px] text-[var(--muted)] mt-0.5">{row.note}</span>
                )}
              </span>
              <span className="font-display gold-text text-lg whitespace-nowrap">
                {rupees(row.price)}
              </span>
            </div>
          ))}
        </div>

        <div
          className="mt-3 rounded-xl px-4 py-3 text-xs leading-relaxed"
          style={{
            background: "rgba(245, 165, 36, 0.10)",
            border: "1px solid rgba(245, 165, 36, 0.35)",
            color: "var(--marigold)",
          }}
        >
          <span className="uppercase tracking-wide font-semibold">Important · </span>
          {late
            ? `Late pricing is live — every entry is ${rupees(899)} per person.`
            : LATE_PRICE_NOTE}
        </div>

        <p className="text-[11px] text-[var(--muted)] mt-3 leading-relaxed">
          Pick who is coming on the booking page and the total is worked out for you — couples,
          families and student groups are bundled automatically at the best rate.
        </p>
      </motion.section>

      {/* Good to know */}
      <motion.section
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.53, duration: 0.5 }}
        className="mt-8"
      >
        <h2 className="text-[10px] uppercase tracking-[0.3em] text-[var(--gold-3)] mb-3">
          Good to know
        </h2>
        <div className="gold-border rounded-2xl p-4">
          <ul className="flex flex-col gap-2">
            {KEY_RULES.map((rule) => (
              <li key={rule} className="flex gap-2.5 text-xs text-[var(--muted)] leading-relaxed">
                <span className="text-[var(--gold-3)] mt-[3px] leading-none">◆</span>
                <span>{rule}</span>
              </li>
            ))}
          </ul>
          <Link
            href="/rules"
            className="mt-4 inline-block text-[11px] uppercase tracking-[0.2em] text-[var(--gold-1)] underline underline-offset-4"
          >
            Read all rules &rarr;
          </Link>
        </div>
      </motion.section>

      {/* Slots + contact */}
      <motion.section
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.56, duration: 0.5 }}
        className="mt-8 gold-border rounded-2xl p-5 text-center relative overflow-hidden"
      >
        <RangoliCorner className="pointer-events-none absolute top-0 left-0 w-16 h-16 text-[var(--gold-3)] opacity-20" />
        <RangoliCorner className="pointer-events-none absolute top-0 right-0 w-16 h-16 text-[var(--gold-3)] opacity-20 scale-x-[-1]" />

        <SlotsLeft variant="card" />

        <div className="flex flex-wrap items-center justify-center gap-2 mt-5">
          {CONTACT_PHONES.map((phone) => (
            <a
              key={phone}
              href={`tel:+91${phone}`}
              className="flex items-center gap-2 text-xs border border-[var(--border)] rounded-full px-4 py-2 hover:border-[var(--gold-3)] transition-colors"
            >
              <span className="text-[var(--gold-3)]">
                <PhoneIcon size={14} />
              </span>
              {phone}
            </a>
          ))}
        </div>
      </motion.section>

      {/* Sticky CTA */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.6, duration: 0.5 }}
        className="fixed bottom-0 left-0 right-0 border-t border-[var(--border)] px-6 py-4 backdrop-blur"
        style={{ background: "rgba(27, 4, 9, 0.92)" }}
      >
        <div className="max-w-lg mx-auto flex items-center justify-between gap-4">
          <div>
            <p className="text-[10px] uppercase tracking-wide text-[var(--muted)]">Entry from</p>
            <p className="font-display gold-text text-xl leading-tight">
              {rupees(late ? 899 : RATE.kid)}
            </p>
          </div>
          {open ? (
            <motion.div whileHover={{ scale: 1.04 }} whileTap={{ scale: 0.96 }}>
              <Link
                href={ctaHref}
                className="gold-btn inline-block rounded-xl px-8 py-3 text-sm uppercase tracking-wide"
              >
                Book Now
              </Link>
            </motion.div>
          ) : (
            <span className="gold-border rounded-xl px-8 py-3 text-sm uppercase tracking-wide text-[var(--muted)] opacity-60 cursor-not-allowed select-none">
              Opens Soon
            </span>
          )}
        </div>
      </motion.div>
    </main>
  );
}
