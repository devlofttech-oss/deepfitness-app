"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import {
  addDoc,
  collection,
  getDocs,
  query,
  serverTimestamp,
  where,
} from "firebase/firestore";
import { db } from "@/lib/firebase/client";
import { useAuth } from "@/lib/firebase/AuthProvider";
import PageShell from "@/components/PageShell";
import FormInput from "@/components/FormInput";
import GoldButton from "@/components/GoldButton";
import PartyBuilder from "@/components/PartyBuilder";
import PriceSummary from "@/components/PriceSummary";
import PaymentPanel from "@/components/PaymentPanel";
import AttendeeFields, { type KidEntry } from "@/components/AttendeeFields";
import { MAX_PARTY_SIZE } from "@/lib/event";
import {
  EMPTY_PARTY,
  KID_AGE_LIMIT,
  type PartyCounts,
  quoteFor,
  totalPeople,
} from "@/lib/pricing";
import type { Attendee } from "@/lib/types";

const ACTIVE_STATUSES = ["pending", "verified", "checked_in"];

/** Grows or trims a list of attendee fields to match the chosen head count. */
function resize<T>(list: T[], size: number, make: () => T): T[] {
  if (list.length === size) return list;
  if (list.length > size) return list.slice(0, size);
  return [...list, ...Array.from({ length: size - list.length }, make)];
}

export default function BookForm() {
  const { user, profile } = useAuth();
  const router = useRouter();
  const [checking, setChecking] = useState(true);
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

  const quote = useMemo(() => quoteFor(party), [party]);
  const people = totalPeople(party);

  useEffect(() => {
    if (!user) return;
    (async () => {
      const q = query(
        collection(db, "tickets"),
        where("userId", "==", user.uid),
        where("status", "in", ACTIVE_STATUSES)
      );
      const snap = await getDocs(q);
      if (!snap.empty) {
        router.replace("/ticket");
        return;
      }
      setChecking(false);
    })();
  }, [user, router]);

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

  async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setError("");
    if (!user || !profile) return;

    const formData = new FormData(e.currentTarget);
    const transactionId = String(formData.get("transaction_id") || "").trim();
    const referralCode = String(formData.get("referral_code") || "").trim();

    if (people === 0) {
      setError("Add at least one person to the booking.");
      return;
    }
    if (people > MAX_PARTY_SIZE) {
      setError(`A single booking covers up to ${MAX_PARTY_SIZE} people.`);
      return;
    }

    const attendees = buildAttendees();
    if (attendees.some((a) => !a.name)) {
      setError("Enter a name for everyone in the booking.");
      return;
    }
    if (!leadPhone.trim()) {
      setError("Enter a phone number we can reach you on.");
      return;
    }
    const badAge = kids.some((kid) => {
      const age = Number(kid.age);
      return kid.age === "" || Number.isNaN(age) || age < 0 || age >= KID_AGE_LIMIT;
    });
    if (badAge) {
      setError(`Enter each kid's age — the kid rate applies below ${KID_AGE_LIMIT} years.`);
      return;
    }
    if (!transactionId) {
      setError("Enter your transaction ID.");
      return;
    }
    if (!nonRefundableAck) {
      setError("You must confirm this payment is non-refundable and cannot be cancelled.");
      return;
    }

    setPending(true);
    try {
      await addDoc(collection(db, "tickets"), {
        userId: user.uid,
        name: profile.name,
        email: profile.email,
        phone: leadPhone.trim(),
        instagram: profile.instagram || "",
        party,
        attendees,
        amount: quote.total,
        transactionId,
        referralCode,
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

  if (checking) {
    return (
      <PageShell className="items-center justify-center">
        <div className="w-6 h-6 rounded-full border-2 border-[var(--border)] border-t-[var(--gold-2)] animate-spin" />
      </PageShell>
    );
  }

  return (
    <PageShell wide>
      <h2 className="font-display gold-text text-3xl text-center mb-2">Book Your Pass</h2>
      <p className="text-center text-xs text-[var(--muted)] mb-8">
        Pick who is coming, pay the total, and submit your transaction ID for verification.
      </p>

      <form onSubmit={handleSubmit} className="flex flex-col gap-6">
        <PartyBuilder party={party} onChange={updateParty} />

        <PriceSummary quote={quote} />

        {people > 0 && <PaymentPanel amount={quote.total} />}

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

        <div className="flex flex-col gap-4">
          <FormInput
            id="transaction_id"
            name="transaction_id"
            label="Transaction / UTR ID"
            required
            autoComplete="off"
          />
          <FormInput
            id="referral_code"
            name="referral_code"
            label="Have a Referral Code? (optional)"
            autoComplete="off"
          />
        </div>

        <div className="gold-border rounded-xl p-4">
          <p className="text-xs text-[var(--muted)] leading-relaxed mb-3">
            This payment is{" "}
            <span className="text-[var(--foreground)] font-medium">non-refundable</span>,{" "}
            <span className="text-[var(--foreground)] font-medium">non-cancellable</span> and the
            pass is{" "}
            <span className="text-[var(--foreground)] font-medium">non-transferable</span> once
            submitted.
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
                Rules & Regulations
              </Link>
              .
            </span>
          </label>
        </div>

        {error && <p className="text-sm text-[var(--danger)]">{error}</p>}

        <GoldButton type="submit" loading={pending} disabled={!nonRefundableAck || people === 0}>
          Submit for Verification
        </GoldButton>
      </form>
    </PageShell>
  );
}
