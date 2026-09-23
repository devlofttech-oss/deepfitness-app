"use client";

import { motion } from "framer-motion";
import {
  CATEGORY_HINT,
  CATEGORY_LABEL,
  type Category,
  type PartyCounts,
  totalPeople,
} from "@/lib/pricing";

const ROWS: Category[] = ["adult", "student", "kid"];

const FIELD: Record<Category, keyof PartyCounts> = {
  adult: "adults",
  student: "students",
  kid: "kids",
};

function Stepper({
  value,
  onChange,
  canIncrease,
  label,
}: {
  value: number;
  onChange: (next: number) => void;
  canIncrease: boolean;
  label: string;
}) {
  return (
    <div className="flex items-center gap-3">
      <motion.button
        type="button"
        whileTap={{ scale: 0.88 }}
        onClick={() => onChange(Math.max(0, value - 1))}
        disabled={value === 0}
        aria-label={`Remove one ${label}`}
        className="w-9 h-9 rounded-full border border-[var(--border)] text-[var(--gold-1)] text-lg leading-none disabled:opacity-30 hover:border-[var(--gold-3)] transition-colors"
      >
        −
      </motion.button>
      <span className="font-display text-xl w-6 text-center tabular-nums">{value}</span>
      <motion.button
        type="button"
        whileTap={{ scale: 0.88 }}
        onClick={() => onChange(value + 1)}
        disabled={!canIncrease}
        aria-label={`Add one ${label}`}
        className="w-9 h-9 rounded-full border border-[var(--border)] text-[var(--gold-1)] text-lg leading-none disabled:opacity-30 hover:border-[var(--gold-3)] transition-colors"
      >
        +
      </motion.button>
    </div>
  );
}

export default function PartyBuilder({
  party,
  onChange,
}: {
  party: PartyCounts;
  onChange: (next: PartyCounts) => void;
}) {
  const people = totalPeople(party);

  return (
    <div className="flex flex-col gap-1.5">
      <span className="text-xs uppercase tracking-widest text-[var(--muted)]">Who is coming?</span>

      <div className="gold-border rounded-2xl divide-y divide-[var(--border)]">
        {ROWS.map((category) => {
          const field = FIELD[category];
          return (
            <div key={category} className="flex items-center justify-between gap-4 px-4 py-3.5">
              <div className="min-w-0">
                <p className="text-sm">{CATEGORY_LABEL[category]}</p>
                <p className="text-[11px] text-[var(--muted)] mt-0.5 leading-snug">
                  {CATEGORY_HINT[category]}
                </p>
              </div>
              <Stepper
                value={party[field]}
                canIncrease
                label={CATEGORY_LABEL[category]}
                onChange={(next) => onChange({ ...party, [field]: next })}
              />
            </div>
          );
        })}
      </div>

      <p className="text-[11px] text-[var(--muted)] mt-1">
        {people === 0
          ? "Add at least one person."
          : `${people} ${people === 1 ? "person" : "people"} in this booking`}
      </p>
    </div>
  );
}
