"use client";

import { useSyncExternalStore } from "react";

/**
 * When booking opens. It is already in the past, so registration is live —
 * push it into the future to hold bookings behind the countdown gate, and
 * keep firestore.rules' isLaunched() in sync with whatever you set.
 */
export const REGISTRATION_OPENS_AT = new Date("2026-09-18T00:00:00+05:30").getTime();

export interface Remaining {
  /** Milliseconds left; 0 once the target is in the past. */
  diff: number;
  days: number;
  hours: number;
  minutes: number;
  seconds: number;
  /** False until the client has read the real clock — never trust diff before this. */
  ready: boolean;
}

/**
 * Server render and the first client render both get this, so a gate never
 * flashes unlocked content before the real time is known.
 */
const NOT_READY: Remaining = {
  diff: 0,
  days: 0,
  hours: 0,
  minutes: 0,
  seconds: 0,
  ready: false,
};

function subscribe(callback: () => void) {
  const id = setInterval(callback, 1000);
  return () => clearInterval(id);
}

// useSyncExternalStore requires getSnapshot to return the same reference when
// nothing has actually changed, or React throws "getSnapshot should be
// cached". Cache per target, by the second, rather than building a fresh
// object on every render.
const cache = new Map<number, { second: number; value: Remaining }>();

function snapshotFor(target: number): Remaining {
  const diff = Math.max(0, target - Date.now());
  const second = Math.floor(diff / 1000);

  const cached = cache.get(target);
  if (cached && cached.second === second) return cached.value;

  const value: Remaining = {
    diff,
    days: Math.floor(diff / 86400000),
    hours: Math.floor((diff % 86400000) / 3600000),
    minutes: Math.floor((diff % 3600000) / 60000),
    seconds: Math.floor((diff % 60000) / 1000),
    ready: true,
  };
  cache.set(target, { second, value });
  return value;
}

/** Ticks once a second towards `target`. */
export function useCountdownTo(target: number): Remaining {
  return useSyncExternalStore(
    subscribe,
    () => snapshotFor(target),
    () => NOT_READY
  );
}

/** Has booking opened? False until the clock has been read. */
export function useIsRegistrationOpen(): { open: boolean; ready: boolean } {
  const remaining = useCountdownTo(REGISTRATION_OPENS_AT);
  return { open: remaining.ready && remaining.diff <= 0, ready: remaining.ready };
}
