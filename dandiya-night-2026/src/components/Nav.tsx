"use client";

import { useState } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { motion } from "framer-motion";
import { signOut } from "firebase/auth";
import { auth } from "@/lib/firebase/client";
import { useAuth } from "@/lib/firebase/AuthProvider";
import ConfirmModal from "@/components/ConfirmModal";
import { StringLights } from "@/components/Ornaments";

function BackIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" aria-hidden>
      <path d="M15 19l-7-7 7-7" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

export default function Nav() {
  const { user, profile } = useAuth();
  const router = useRouter();
  const pathname = usePathname();
  const [confirmingLogout, setConfirmingLogout] = useState(false);

  async function handleLogout() {
    setConfirmingLogout(false);
    await signOut(auth);
    router.push("/");
  }

  return (
    <header className="w-full relative">
      <div className="max-w-lg mx-auto px-6 py-4 flex items-center justify-between">
        <div className="flex items-center gap-3">
          {pathname !== "/" && (
            <motion.button
              whileHover={{ scale: 1.1 }}
              whileTap={{ scale: 0.92 }}
              onClick={() => router.back()}
              aria-label="Go back"
              className="text-[var(--muted)] hover:text-[var(--gold-1)] transition-colors"
            >
              <BackIcon />
            </motion.button>
          )}
          <Link href="/" className="leading-none shrink-0">
            <span className="block font-display gold-text text-xl whitespace-nowrap">
              Dandiya Night
            </span>
            <span className="block text-[9px] uppercase tracking-[0.35em] text-[var(--muted)]">
              2026
            </span>
          </Link>
        </div>
        <nav className="flex items-center justify-end flex-wrap gap-x-3 gap-y-1.5 text-[10px] uppercase tracking-wide text-[var(--muted)]">
          <Link href="/rules" className="hover:text-[var(--gold-1)] transition-colors">
            Rules
          </Link>
          <Link href="/help" className="hover:text-[var(--gold-1)] transition-colors">
            Help
          </Link>
          {user ? (
            <>
              <Link href="/ticket" className="hover:text-[var(--gold-1)] transition-colors">
                My Pass
              </Link>
              {profile?.isAdmin && (
                <Link href="/admin" className="hover:text-[var(--gold-1)] transition-colors">
                  Admin
                </Link>
              )}
              <button
                onClick={() => setConfirmingLogout(true)}
                className="hover:text-[var(--gold-1)] transition-colors uppercase"
              >
                Logout
              </button>
            </>
          ) : (
            <Link
              href="/login"
              className="gold-border rounded-full px-3 py-1.5 whitespace-nowrap text-[var(--gold-1)] hover:bg-[var(--gold-2)]/10 transition-colors"
            >
              Login / Sign&nbsp;Up
            </Link>
          )}
        </nav>
      </div>

      {/* Bulbs strung across the top of every page */}
      <StringLights className="w-full h-6 text-[var(--gold-3)]" />

      <ConfirmModal
        open={confirmingLogout}
        title="Log Out"
        message="Are you sure you want to log out?"
        confirmLabel="Log Out"
        onConfirm={handleLogout}
        onCancel={() => setConfirmingLogout(false)}
      />
    </header>
  );
}
