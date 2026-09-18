"use client";

import { motion } from "framer-motion";
import { MarigoldIcon, RULE_ICONS } from "@/components/Ornaments";
import { NON_REFUNDABLE_NOTE, RULES } from "@/lib/rules";

export default function RulesList({ compact = false }: { compact?: boolean }) {
  return (
    <div className="flex flex-col gap-3">
      <div
        className="rounded-xl px-4 py-3 text-xs leading-relaxed"
        style={{
          background: "rgba(245, 165, 36, 0.10)",
          border: "1px solid rgba(245, 165, 36, 0.35)",
          color: "var(--marigold)",
        }}
      >
        <span className="uppercase tracking-wide font-semibold">Important · </span>
        {NON_REFUNDABLE_NOTE}
      </div>

      {RULES.map((group, i) => {
        const Icon = RULE_ICONS[group.id] ?? MarigoldIcon;
        return (
          <motion.section
            key={group.id}
            initial={{ opacity: 0, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: compact ? 0 : i * 0.05, duration: 0.4 }}
            className="gold-border rounded-xl p-4"
          >
            <div className="flex items-center gap-2.5 mb-2.5">
              <span className="text-[var(--gold-2)]">
                <Icon size={18} />
              </span>
              <h3 className="font-display text-lg text-[var(--gold-1)] leading-none">
                {group.heading}
              </h3>
            </div>
            <ul className="flex flex-col gap-1.5">
              {group.items.map((item) => (
                <li key={item} className="flex gap-2.5 text-xs text-[var(--muted)] leading-relaxed">
                  <span className="text-[var(--gold-3)] mt-[3px] leading-none">◆</span>
                  <span>{item}</span>
                </li>
              ))}
            </ul>
          </motion.section>
        );
      })}
    </div>
  );
}
