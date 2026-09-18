import Link from "next/link";
import PageShell from "@/components/PageShell";
import RulesList from "@/components/RulesList";
import { RULES_INTRO, RULES_TITLE } from "@/lib/rules";
import { CONTACT_PHONES } from "@/lib/event";

export const metadata = {
  title: "General Rules — Dandiya Night 2026",
  description: "Entry, safety, dress code, kids, dance floor and photography rules for the night.",
};

export default function RulesPage() {
  return (
    <PageShell wide>
      <h2 className="font-display gold-text text-3xl text-center mb-2">{RULES_TITLE}</h2>
      <p className="text-center text-xs text-[var(--muted)] mb-8 max-w-sm mx-auto leading-relaxed">
        {RULES_INTRO}
      </p>

      <RulesList />

      <p className="text-[11px] text-[var(--muted)] text-center mt-6 leading-relaxed">
        Questions about any of this? Call{" "}
        <a href={`tel:+91${CONTACT_PHONES[0]}`} className="text-[var(--gold-1)] underline">
          {CONTACT_PHONES[0]}
        </a>{" "}
        or read the{" "}
        <Link href="/signup" className="text-[var(--gold-1)] underline">
          Terms &amp; Conditions
        </Link>{" "}
        shown at signup.
      </p>
    </PageShell>
  );
}
