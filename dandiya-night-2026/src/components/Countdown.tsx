"use client";

import { useCountdownTo } from "@/lib/launch";

export default function Countdown({
  target,
  label = "The night begins in",
}: {
  target: number;
  label?: string;
}) {
  const remaining = useCountdownTo(target);
  if (!remaining.ready || remaining.diff <= 0) return null;

  const units = [
    { value: remaining.days, unit: "Days" },
    { value: remaining.hours, unit: "Hrs" },
    { value: remaining.minutes, unit: "Min" },
    { value: remaining.seconds, unit: "Sec" },
  ];

  return (
    <div className="flex flex-col items-center gap-3">
      <p className="text-[10px] uppercase tracking-[0.3em] text-[var(--muted)]">{label}</p>
      <div className="flex items-center gap-2">
        {units.map((u) => (
          <div
            key={u.unit}
            className="gold-border rounded-xl px-3 py-2 flex flex-col items-center min-w-[56px]"
          >
            <span className="gold-text font-display text-2xl tabular-nums leading-tight">
              {String(u.value).padStart(2, "0")}
            </span>
            <span className="text-[9px] text-[var(--muted)] uppercase tracking-wide mt-0.5">
              {u.unit}
            </span>
          </div>
        ))}
      </div>
    </div>
  );
}
