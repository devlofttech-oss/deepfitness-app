"use client";

import type { ReactNode } from "react";
import { REGISTRATION_OPENS_AT, useIsRegistrationOpen } from "@/lib/launch";
import Countdown from "@/components/Countdown";
import PageShell from "@/components/PageShell";

export default function LaunchGate({
  children,
  message = "Bookings open when the countdown ends. Check back then.",
}: {
  children: ReactNode;
  message?: string;
}) {
  const { open, ready } = useIsRegistrationOpen();

  if (!ready) {
    return (
      <PageShell className="items-center justify-center">
        <div className="w-6 h-6 rounded-full border-2 border-[var(--border)] border-t-[var(--gold-2)] animate-spin" />
      </PageShell>
    );
  }

  if (!open) {
    return (
      <PageShell className="items-center justify-center text-center">
        <h2 className="font-display gold-text text-3xl mb-2">Not Yet</h2>
        <p className="text-xs text-[var(--muted)] max-w-xs mb-8">{message}</p>
        <Countdown target={REGISTRATION_OPENS_AT} label="Bookings open in" />
      </PageShell>
    );
  }

  return <>{children}</>;
}
