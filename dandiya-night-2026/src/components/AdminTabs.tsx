"use client";

import { useState } from "react";
import AdminTransactions from "@/components/AdminTransactions";
import AdminCheckedIn from "@/components/AdminCheckedIn";

const TABS = [
  { id: "transactions", label: "Bookings" },
  { id: "checkedin", label: "Checked In" },
] as const;

type TabId = (typeof TABS)[number]["id"];

export default function AdminTabs() {
  const [active, setActive] = useState<TabId>("transactions");

  return (
    <div>
      <div className="flex gap-2 mb-6 flex-wrap">
        {TABS.map((t) => (
          <button
            key={t.id}
            onClick={() => setActive(t.id)}
            className={`text-xs uppercase tracking-wide px-4 py-2 rounded-full border transition-colors ${
              active === t.id
                ? "gold-btn border-transparent"
                : "border-[var(--border)] text-[var(--muted)] hover:text-[var(--gold-1)]"
            }`}
          >
            {t.label}
          </button>
        ))}
      </div>
      {active === "transactions" && <AdminTransactions />}
      {active === "checkedin" && <AdminCheckedIn />}
    </div>
  );
}
