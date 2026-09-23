"use client";

import { useMemo, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { AnimatePresence, motion } from "framer-motion";
import { addDoc, collection, serverTimestamp } from "firebase/firestore";
import { db } from "@/lib/firebase/client";
import { useAuth } from "@/lib/firebase/AuthProvider";
import PageShell from "@/components/PageShell";
import FormInput from "@/components/FormInput";
import GoldButton from "@/components/GoldButton";
import PartyBuilder from "@/components/PartyBuilder";
import PriceSummary from "@/components/PriceSummary";
import PaymentPanel from "@/components/PaymentPanel";
import AttendeeFields, { type KidEntry } from "@/components/AttendeeFields";
import {
  EMPTY_PARTY,
  KID_AGE_LIMIT,
  type PartyCounts,
  partySummary,
  quoteFor,
  rupees,
  totalPeople,
} from "@/lib/pricing";
import type { Attendee } from "@/lib/types";

const STEPS = ["Who", "Details", "Pay"] as const;

/** Grows or trims a list of attendee fields to match the chosen head count. */
function resize<T>(list: T[], size: number, make: () => T): T[] {
  if (list.length === size) return list;
  if (list.length > size) return list.slice(0, size);
  return [...list, ...Array.from({ length: size - list.length }, make)];
}

function Stepper({ step }: { step: number }) {
  return (
    <div className="flex items-center justify-center gap-2 mb-7">
      {STEPS.map((label, i) => (
        <div key={label} className="flex items-center gap-2">
          <span
            className={`w-6 h-6 rounded-full grid place-items-center text-[11px] font-medium transition-colors ${
              i <= step
                ? "bg-[var(--gold-2)] text-[#3a0810]"
                : "border border-[var(--border)] text-[var(--muted)]"
            }`}
          >
            {i + 1}
          </span>
          <span
            className={`text-[10px] uppercase tracking-[0.2em] transition-colors ${
              i === step ? "text-[var(--gold-1)]" : "text-[var(--muted)]"
            }`}
          >
            {label}
          </span>
          {i < STEPS.length - 1 && (
            <span
              className={`h-px w-4 ${i < step ? "bg-[var(--gold-3)]" : "bg-[var(--border)]"}`}
            />
          )}
        </div>
      ))}
    </div>
  );
}

export default function BookForm() {
  const { user, profile } = useAuth();
  const router = useRouter();
  const [step, setStep] = useState(0);
  const [error, setError] = useState("");
  const [pending, setPending] = useState(false);
  const [nonRefundableAck, setNonRefundableAck] = useState(false);

  const [party, setParty] = useState<PartyCounts>(EMPTY_PARTY);
  const [adults, setAdults] = useState<string[]>([]);
  const [students, setStudents] = useState<string[]>([]);
  const [kids, setKids] = useState<KidEntry[]>([]);
  // null means "not typed in yet", so the account's number can seed the field
  // without an effect fighting the user's edits.
  const [leadPhoneInput, setLeadPhoneInput] = useState<string | null>(null);
  const leadPhone = leadPhoneInput ?? profile?.phone ?? "";
  const [transactionId, setTransactionId] = useState("");

  const quote = useMemo(() => quoteFor(party), [party]);
  const people = totalPeople(party);

  /** Keep the name fields in step with the steppers. */
  function updateParty(next: PartyCounts) {
    setParty(next);
    setAdults((list) => {
      const resized = resize(list, next.adults, () => "");
      // Seed the first adult from the account, so the common case — one adult
      // booking for themselves — needs no typing.
      if (resized.length > 0 && !resized[0] && profile?.name) {
        return [profile.name, ...resized.slice(1)];
      }
      return resized;
    });
    setStudents((list) => resize(list, next.students, () => ""));
    setKids((list) => resize(list, next.kids, () => ({ name: "", age: "" })));
  }

  function buildAttendees(): Attendee[] {
    const list: Attendee[] = [
      ...adults.map((name) => ({ name: name.trim(), category: "adult" as const })),
      ...students.map((name) => ({ name: name.trim(), category: "student" as const })),
      ...kids.map((kid) => ({
        name: kid.name.trim(),
        category: "kid" as const,
        age: Number(kid.age),
      })),
    ];
    // The gate needs one number to call; it hangs off the first attendee.
    if (list.length > 0) list[0] = { ...list[0], phone: leadPhone.trim() };
    return list;
  }

  /** Returns what is missing on a given step, or null when it is complete. */
  function stepError(index: number): string | null {
    if (index === 0) {
      if (people === 0) return "Add at least one person to the booking.";
      return null;
    }
    if (index === 1) {
      if (buildAttendees().some((a) => !a.name))
        return "Enter a name for everyone in the booking.";
      if (!leadPhone.trim()) return "Enter a phone number we can reach you on.";
      const badAge = kids.some((kid) => {
        const age = Number(kid.age);
        return kid.age === "" || Number.isNaN(age) || age < 0 || age >= KID_AGE_LIMIT;
      });
      if (badAge)
        return `Enter each kid's age — the kid rate applies below ${KID_AGE_LIMIT} years.`;
      return null;
    }
    if (!transactionId.trim()) return "Enter your transaction ID.";
    if (!nonRefundableAck)
      return "You must confirm this payment is non-refundable and cannot be cancelled.";
    return null;
  }

  function next() {
    const problem = stepError(step);
    if (problem) {
      setError(problem);
      return;
    }
    setError("");
    setStep((s) => Math.min(STEPS.length - 1, s + 1));
  }

  function back() {
    setError("");
    setStep((s) => Math.max(0, s - 1));
  }

  async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    // Enter anywhere in the form advances rather than submits early.
    if (step < STEPS.length - 1) {
      next();
      return;
    }
    setError("");
    if (!user || !profile) return;

    // Re-check every step — a stepper is navigation, not validation.
    for (let i = 0; i < STEPS.length; i += 1) {
      const problem = stepError(i);
      if (problem) {
        setError(problem);
        setStep(i);
        return;
      }
    }

    setPending(true);
    try {
      await addDoc(collection(db, "tickets"), {
        userId: user.uid,
        name: profile.name,
        username: profile.username || "",
        email: profile.email,
        phone: leadPhone.trim(),
        instagram: profile.instagram || "",
        party,
        attendees: buildAttendees(),
        amount: quote.total,
        transactionId: transactionId.trim(),
        status: "pending",
        createdAt: serverTimestamp(),
        verifiedAt: null,
        checkedInAt: null,
      });
      router.push("/ticket");
    } catch {
      setError("Could not submit your booking. Please try again.");
      setPending(false);
    }
  }

  const subheading = [
    "Pick who is coming and we work out the best price.",
    "Names go on the guest list at the gate.",
    "Pay the exact amount, then enter your transaction ID.",
  ][step];

  return (
    <PageShell wide>
      <h2 className="font-display gold-text text-3xl text-center mb-2">Book Your Pass</h2>
      <p className="text-center text-xs text-[var(--muted)] mb-7">{subheading}</p>

      <Stepper step={step} />

      {people > 0 && step > 0 && (
        <div className="flex items-center justify-between gold-border rounded-xl px-4 py-2.5 mb-6">
          <span className="text-[11px] uppercase tracking-wide text-[var(--muted)]">
            {partySummary(party)}
          </span>
          <span className="font-display gold-text text-lg">{rupees(quote.total)}</span>
        </div>
      )}

      <form onSubmit={handleSubmit} className="flex flex-col gap-6">
        <AnimatePresence mode="wait">
          <motion.div
            key={step}
            initial={{ opacity: 0, x: 16 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -16 }}
            transition={{ duration: 0.22, ease: "easeOut" }}
            className="flex flex-col gap-6"
          >
            {step === 0 && (
              <>
                <PartyBuilder party={party} onChange={updateParty} />
                <PriceSummary quote={quote} />
              </>
            )}

            {step === 1 && (
              <AttendeeFields
                party={party}
                adults={adults}
                students={students}
                kids={kids}
                leadPhone={leadPhone}
                onAdultChange={(i, value) =>
                  setAdults((list) => list.map((v, idx) => (idx === i ? value : v)))
                }
                onStudentChange={(i, value) =>
                  setStudents((list) => list.map((v, idx) => (idx === i ? value : v)))
                }
                onKidChange={(i, field, value) =>
                  setKids((list) =>
                    list.map((kid, idx) => (idx === i ? { ...kid, [field]: value } : kid))
                  )
                }
                onLeadPhoneChange={setLeadPhoneInput}
              />
            )}

            {step === 2 && (
              <>
                <PaymentPanel amount={quote.total} />

                <FormInput
                  id="transaction_id"
                  name="transaction_id"
                  label="Transaction / UTR ID"
                  value={transactionId}
                  onChange={(e) => setTransactionId(e.target.value)}
                  required
                  autoComplete="off"
                />

                <div className="gold-border rounded-xl p-4">
                  <p className="text-xs text-[var(--muted)] leading-relaxed mb-3">
                    This payment is{" "}
                    <span className="text-[var(--foreground)] font-medium">non-refundable</span>,{" "}
                    <span className="text-[var(--foreground)] font-medium">non-cancellable</span>{" "}
                    and the pass is{" "}
                    <span className="text-[var(--foreground)] font-medium">non-transferable</span>.
                  </p>
                  <label className="flex items-start gap-2.5 text-xs text-[var(--muted)]">
                    <input
                      type="checkbox"
                      checked={nonRefundableAck}
                      onChange={(e) => setNonRefundableAck(e.target.checked)}
                      className="mt-0.5 accent-[var(--gold-3)]"
                    />
                    <span>
                      I understand and accept this, and I have read the{" "}
                      <Link
                        href="/rules"
                        target="_blank"
                        className="text-[var(--gold-1)] underline underline-offset-2"
                      >
                        Rules &amp; Regulations
                      </Link>
                      .
                    </span>
                  </label>
                </div>
              </>
            )}
          </motion.div>
        </AnimatePresence>

        {error && <p className="text-sm text-[var(--danger)]">{error}</p>}

        <div className="flex gap-3">
          {step > 0 && (
            <GoldButton type="button" variant="outline" onClick={back} className="flex-1">
              Back
            </GoldButton>
          )}
          {step < STEPS.length - 1 ? (
            <GoldButton
              type="button"
              onClick={next}
              disabled={step === 0 && people === 0}
              className="flex-[2]"
            >
              Continue
            </GoldButton>
          ) : (
            <GoldButton type="submit" loading={pending} className="flex-[2]">
              Submit for Verification
            </GoldButton>
          )}
        </div>
      </form>
    </PageShell>
  );
}
