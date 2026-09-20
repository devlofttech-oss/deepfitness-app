"use client";

import Image from "next/image";
import Link from "next/link";
import { motion } from "framer-motion";
import { useAuth } from "@/lib/firebase/AuthProvider";
import {
  CONTACT_PHONES,
  EVENT_DATE,
  EVENT_NAME,
  EVENT_TAGLINE,
  EVENT_TIME,
  PRESENTER,
  VENUE_SHORT,
} from "@/lib/event";
import SlotsLeft from "@/components/SlotsLeft";
import { DandiyaIcon } from "@/components/Ornaments";

export default function HeroClient() {
  const { user } = useAuth();

  return (
    <main className="flex-1 flex flex-col items-center justify-center px-6 pt-14 pb-20 text-center relative overflow-hidden">
      {/* The poster art carries its own lanterns, lights and mandala, so the
          hero drops the drawn ones and sits in the empty middle of the frame.
          The scrim keeps the type readable over the dancers at the bottom. */}
      <Image
        src="/background.png"
        alt=""
        fill
        priority
        sizes="100vw"
        className="object-cover object-center -z-20"
      />
      <div
        aria-hidden
        className="absolute inset-0 -z-10"
        style={{
          background:
            "linear-gradient(to bottom, rgba(27,4,9,0.62) 0%, rgba(27,4,9,0.45) 35%, rgba(27,4,9,0.78) 70%, rgba(27,4,9,0.94) 100%)",
        }}
      />

      <motion.p
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ duration: 0.6 }}
        className="text-[11px] uppercase tracking-[0.45em] text-[var(--gold-3)]"
      >
        {PRESENTER}
      </motion.p>

      <motion.h1
        initial={{ opacity: 0, y: 16 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.8, ease: "easeOut" }}
        className="font-display gold-text gold-emboss text-5xl sm:text-7xl leading-[1.05] mt-5"
      >
        {EVENT_NAME.replace(" 2026", "")}
        <span className="block text-4xl sm:text-6xl">2026</span>
      </motion.h1>

      <motion.div
        initial={{ opacity: 0, scale: 0.9 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ delay: 0.25, duration: 0.6 }}
        className="mt-6 flex items-center gap-3 text-[var(--gold-2)]"
      >
        <span className="h-px w-10 bg-gradient-to-r from-transparent to-[var(--gold-4)]" />
        <DandiyaIcon size={22} />
        <span className="h-px w-10 bg-gradient-to-l from-transparent to-[var(--gold-4)]" />
      </motion.div>

      <motion.p
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.4, duration: 0.6 }}
        className="font-display text-xl sm:text-2xl mt-6"
      >
        {EVENT_TAGLINE}
      </motion.p>

      <motion.div
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.55, duration: 0.6 }}
        className="mt-8 text-sm leading-relaxed"
      >
        <p className="text-[var(--foreground)]">
          {EVENT_DATE} &middot; {EVENT_TIME}
        </p>
        <p className="text-[var(--muted)] mt-1">{VENUE_SHORT}</p>
      </motion.div>

      <motion.div
        initial={{ opacity: 0, y: 14 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.7, duration: 0.6 }}
        className="mt-10 w-full max-w-xs"
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
        transition={{ delay: 0.85, duration: 0.6 }}
        className="mt-6"
      >
        <SlotsLeft />
      </motion.div>

      <motion.p
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 1, duration: 0.6 }}
        className="mt-10 text-xs text-[var(--foreground)]/75"
      >
        {CONTACT_PHONES.map((phone, i) => (
          <span key={phone}>
            {i > 0 && <span className="text-[var(--gold-4)]"> &middot; </span>}
            <a href={`tel:+91${phone}`} className="hover:text-[var(--gold-1)] transition-colors">
              {phone}
            </a>
          </span>
        ))}
      </motion.p>
    </main>
  );
}
