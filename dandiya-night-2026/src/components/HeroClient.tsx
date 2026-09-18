"use client";

import Link from "next/link";
import { motion } from "framer-motion";
import { useAuth } from "@/lib/firebase/AuthProvider";
import { greetingFor } from "@/lib/greeting";
import {
  CONTACT_PHONES,
  EVENT_DATE,
  EVENT_NAME,
  EVENT_SUBTAGLINE,
  EVENT_TAGLINE,
  EVENT_TIME,
  PRESENTER,
  VENUE_SHORT,
} from "@/lib/event";
import SlotsLeft from "@/components/SlotsLeft";
import {
  CalendarIcon,
  ClockIcon,
  DandiyaIcon,
  DiyaIcon,
  GarbaScene,
  Mandala,
  PaisleyIcon,
  PeacockIcon,
  PhoneIcon,
  PinIcon,
  RangoliCorner,
} from "@/components/Ornaments";

export default function HeroClient() {
  const { user, profile } = useAuth();

  return (
    <main className="flex-1 flex flex-col items-center px-6 pt-10 pb-16 text-center relative overflow-hidden">
      {/* Backdrop: two slow mandalas and a warm floor glow */}
      <Mandala
        className="pointer-events-none absolute -top-24 -right-28 w-80 h-80 text-[var(--gold-3)] opacity-[0.13]"
        spin={140}
      />
      <Mandala
        className="pointer-events-none absolute -bottom-32 -left-28 w-72 h-72 text-[var(--marigold)] opacity-[0.10]"
        spin={190}
      />
      <RangoliCorner className="pointer-events-none absolute top-0 left-0 w-24 h-24 text-[var(--gold-3)] opacity-25" />
      <RangoliCorner className="pointer-events-none absolute top-0 right-0 w-24 h-24 text-[var(--gold-3)] opacity-25 scale-x-[-1]" />

      {profile && (
        <motion.p
          initial={{ opacity: 0, y: -8 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="text-[11px] uppercase tracking-[0.25em] text-[var(--muted)] mb-6"
        >
          {greetingFor(profile.name)}
        </motion.p>
      )}

      <motion.p
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ duration: 0.6 }}
        className="text-[11px] uppercase tracking-[0.45em] text-[var(--gold-3)]"
      >
        {PRESENTER}
      </motion.p>

      <motion.div
        initial={{ opacity: 0, scale: 0.9 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ delay: 0.15, duration: 0.6 }}
        className="my-5 flex items-center gap-3 text-[var(--gold-2)]"
      >
        <PaisleyIcon size={20} className="scale-x-[-1]" />
        <span className="h-px w-8 bg-gradient-to-r from-transparent to-[var(--gold-3)]" />
        <DandiyaIcon size={26} />
        <span className="h-px w-8 bg-gradient-to-l from-transparent to-[var(--gold-3)]" />
        <PaisleyIcon size={20} />
      </motion.div>

      <motion.h1
        initial={{ opacity: 0, y: 18 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.9, ease: "easeOut" }}
        className="font-display gold-text text-5xl sm:text-7xl leading-[1.05]"
      >
        {EVENT_NAME.replace(" 2026", "")}
        <span className="block text-4xl sm:text-6xl">2026</span>
      </motion.h1>

      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.45, duration: 0.6 }}
        className="mt-6 space-y-2"
      >
        <p className="font-display text-xl sm:text-2xl text-[var(--foreground)]">
          {EVENT_TAGLINE}
        </p>
        <p className="text-[11px] uppercase tracking-[0.35em] text-[var(--marigold)]">
          {EVENT_SUBTAGLINE}
        </p>
      </motion.div>

      <motion.div
        initial={{ opacity: 0, y: 12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.6, duration: 0.6 }}
        className="mt-8 flex flex-col items-center gap-2.5 text-sm"
      >
        <span className="flex items-center gap-2.5 text-[var(--foreground)]">
          <span className="text-[var(--gold-3)]">
            <CalendarIcon size={16} />
          </span>
          {EVENT_DATE}
        </span>
        <span className="flex items-center gap-2.5 text-[var(--foreground)]">
          <span className="text-[var(--gold-3)]">
            <ClockIcon size={16} />
          </span>
          {EVENT_TIME}
        </span>
        <span className="flex items-center gap-2.5 text-[var(--muted)]">
          <span className="text-[var(--gold-3)]">
            <PinIcon size={16} />
          </span>
          {VENUE_SHORT}
        </span>
      </motion.div>

      <motion.div
        initial={{ opacity: 0, scale: 0.94 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ delay: 0.75, duration: 0.7, ease: "easeOut" }}
        className="mt-8 w-full max-w-sm"
      >
        <GarbaScene className="w-full h-auto text-[var(--gold-2)]" />
      </motion.div>

      <motion.div
        initial={{ opacity: 0, y: 16 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.9, duration: 0.6 }}
        className="mt-6 w-full max-w-xs"
      >
        <Link
          href={user ? "/ticket" : "/event"}
          className="gold-btn block w-full rounded-xl px-10 py-3.5 text-sm uppercase tracking-wide text-center"
        >
          {user ? "My Pass" : "Book Your Pass"}
        </Link>
      </motion.div>

      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 1.05, duration: 0.6 }}
        className="mt-8"
      >
        <SlotsLeft />
      </motion.div>

      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 1.2, duration: 0.6 }}
        className="mt-10 flex flex-col items-center gap-3"
      >
        <span className="text-[10px] uppercase tracking-[0.3em] text-[var(--muted)]">
          Call us
        </span>
        <div className="flex flex-wrap items-center justify-center gap-2">
          {CONTACT_PHONES.map((phone) => (
            <a
              key={phone}
              href={`tel:+91${phone}`}
              className="flex items-center gap-2 text-xs text-[var(--foreground)] border border-[var(--border)] rounded-full px-4 py-2 hover:border-[var(--gold-3)] transition-colors"
            >
              <span className="text-[var(--gold-3)]">
                <PhoneIcon size={14} />
              </span>
              {phone}
            </a>
          ))}
        </div>
      </motion.div>

      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 1.35, duration: 0.6 }}
        className="mt-12 flex flex-col items-center gap-3 text-[var(--gold-2)]"
      >
        <div className="flex items-center gap-3">
          <DiyaIcon size={18} />
          <span className="font-display gold-text text-2xl">Let&rsquo;s Garba!</span>
          <DiyaIcon size={18} />
        </div>
        <PeacockIcon size={30} className="opacity-60" />
      </motion.div>
    </main>
  );
}
