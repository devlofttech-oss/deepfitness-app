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
        /* Portrait art in a landscape window crops hard. Phones keep the
           centre; wider screens anchor to the bottom so the dancers stay in
           frame instead of being cut away. */
        className="object-cover object-center md:object-bottom -z-20"
      />
      <div
        aria-hidden
        className="absolute inset-0 -z-10"
        style={{
          background:
            "linear-gradient(to bottom, rgba(27,4,9,0.62) 0%, rgba(27,4,9,0.45) 35%, rgba(27,4,9,0.78) 70%, rgba(27,4,9,0.94) 100%)",
        }}
      />
      {/* On desktop the whole frame is crowd, so the text column gets its own
          pool of shadow while the dancers stay lit at the edges. */}
      <div
        aria-hidden
        className="absolute inset-0 -z-10 hidden md:block"
        style={{
          background:
            "radial-gradient(ellipse 42% 72% at 50% 50%, rgba(27,4,9,0.80) 0%, rgba(27,4,9,0.55) 55%, rgba(27,4,9,0) 100%)",
        }}
      />

      <motion.p
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ duration: 0.6 }}
        className="text-base sm:text-lg uppercase tracking-[0.38em] text-[var(--gold-1)] font-medium"
        style={{ textShadow: "0 0 18px rgba(245, 190, 90, 0.45), 0 2px 6px rgba(0,0,0,0.55)" }}
      >
        {PRESENTER}
      </motion.p>

      {/* The wordmark is artwork, so the real heading stays in the markup for
          search engines and screen readers. */}
      <h1 className="sr-only">{EVENT_NAME}</h1>
      <motion.div
        initial={{ opacity: 0, y: 16, scale: 0.97 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        transition={{ duration: 0.8, ease: "easeOut" }}
        className="mt-4 w-full max-w-[340px] sm:max-w-[440px]"
      >
        <Image
          src="/wordmark.png"
          alt=""
          width={1591}
          height={988}
          priority
          sizes="(max-width: 640px) 340px, 440px"
          className="w-full h-auto"
        />
      </motion.div>

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
