/**
 * Every price rule for the event lives in this file and nowhere else.
 * Change the numbers here and the event page, booking form, price summary
 * and admin views all follow — no other file hard-codes a rupee amount.
 *
 * ── ASSUMPTIONS TO CONFIRM ────────────────────────────────────────────────
 * The poster's list is ambiguous in two places; these are the readings
 * currently wired in:
 *
 *  1. "Kid with Parents — ₹999" is treated as 2 adults + 1 kid.
 *     Note this undercuts Couple (₹1,299): a couple can add one kid and pay
 *     ₹300 LESS than a couple alone. If that is not intended, either change
 *     the kid-with-parents pack to { adults: 1, kids: 1 } or raise its price
 *     above the couple price.
 *  2. "Students Offer — ₹1,299" is treated as a pass for 3 students.
 *     Students beyond a multiple of 3 are charged the single-entry rate.
 *
 * "Above 15 years — ₹799" is the same amount as Single Entry, so it is one
 * option (RATE.adult) rather than two identical rows.
 *
 * Every kid below KID_AGE_LIMIT pays the kid rate — there is no free age
 * band. The house rules on /rules are worded to match.
 * ──────────────────────────────────────────────────────────────────────────
 */

export type Category = "adult" | "kid" | "student";

export interface PartyCounts {
  adults: number;
  kids: number;
  students: number;
}

export const EMPTY_PARTY: PartyCounts = { adults: 0, kids: 0, students: 0 };

/** A "kid" is anyone below this age; at or above it, the adult rate applies. */
export const KID_AGE_LIMIT = 15;

/** Per-head rates, charged to anyone not covered by a pack below. */
export const RATE: Record<Category, number> = {
  adult: 799,
  kid: 399,
  student: 799,
};

export const CATEGORY_LABEL: Record<Category, string> = {
  adult: `Adults (${KID_AGE_LIMIT} yrs & above)`,
  kid: `Kids (below ${KID_AGE_LIMIT} yrs)`,
  student: "Students",
};

export const CATEGORY_HINT: Record<Category, string> = {
  adult: `₹${RATE.adult} each · two adults book as a couple for ₹1,299`,
  kid: `₹${RATE.kid} each · cheaper when booked with two parents`,
  student: "3 students for ₹1,299 · student ID required at entry",
};

export interface Pack {
  id: string;
  label: string;
  price: number;
  adults: number;
  kids: number;
  students: number;
  note?: string;
}

/** Bundles. Applied automatically, best value first, then per-head rates. */
export const PACKS: Pack[] = [
  {
    id: "student-trio",
    label: "Students Offer (3 students)",
    price: 1299,
    adults: 0,
    kids: 0,
    students: 3,
    note: "Valid student ID required at entry",
  },
  {
    id: "kid-with-parents",
    label: "Kid with Parents (2 adults + 1 kid)",
    price: 999,
    adults: 2,
    kids: 1,
    students: 0,
  },
  {
    id: "couple",
    label: "Couple",
    price: 1299,
    adults: 2,
    kids: 0,
    students: 0,
  },
];

/**
 * From this moment every head costs a flat LATE_FLAT_PER_PERSON and all
 * packs stop applying — "After 12th October, all entries will be ₹899."
 */
export const LATE_PRICE_FROM = new Date("2026-10-13T00:00:00+05:30").getTime();
export const LATE_FLAT_PER_PERSON = 899;
export const LATE_PRICE_NOTE = `After 12th October, all entries are ₹${LATE_FLAT_PER_PERSON} per person.`;

export function isLatePricing(now: number = Date.now()): boolean {
  return now >= LATE_PRICE_FROM;
}

export interface QuoteLine {
  label: string;
  qty: number;
  unit: number;
  amount: number;
  note?: string;
}

export interface Quote {
  people: number;
  total: number;
  lines: QuoteLine[];
  late: boolean;
}

export function totalPeople(party: PartyCounts): number {
  return party.adults + party.kids + party.students;
}

function packValue(pack: Pack): number {
  const perHead =
    pack.adults * RATE.adult + pack.kids * RATE.kid + pack.students * RATE.student;
  return perHead - pack.price;
}

/**
 * Prices a party: applies each pack as many times as it fits (biggest saving
 * first), then charges whoever is left over at the per-head rate.
 */
export function quoteFor(party: PartyCounts, now: number = Date.now()): Quote {
  const people = totalPeople(party);
  const late = isLatePricing(now);

  if (people <= 0) return { people: 0, total: 0, lines: [], late };

  if (late) {
    const amount = people * LATE_FLAT_PER_PERSON;
    return {
      people,
      total: amount,
      late,
      lines: [
        {
          label: "Entry (after 12th Oct rate)",
          qty: people,
          unit: LATE_FLAT_PER_PERSON,
          amount,
        },
      ],
    };
  }

  let { adults, kids, students } = party;
  const lines: QuoteLine[] = [];

  const ordered = [...PACKS]
    .filter((p) => p.adults + p.kids + p.students > 0 && packValue(p) > 0)
    .sort((a, b) => packValue(b) - packValue(a));

  for (const pack of ordered) {
    let count = 0;
    while (adults >= pack.adults && kids >= pack.kids && students >= pack.students) {
      adults -= pack.adults;
      kids -= pack.kids;
      students -= pack.students;
      count += 1;
    }
    if (count > 0) {
      lines.push({
        label: pack.label,
        qty: count,
        unit: pack.price,
        amount: count * pack.price,
        note: pack.note,
      });
    }
  }

  if (adults > 0) {
    lines.push({
      label: `Single Entry (${KID_AGE_LIMIT} yrs & above)`,
      qty: adults,
      unit: RATE.adult,
      amount: adults * RATE.adult,
    });
  }
  if (students > 0) {
    lines.push({
      label: "Student Entry",
      qty: students,
      unit: RATE.student,
      amount: students * RATE.student,
      note: "Valid student ID required at entry",
    });
  }
  if (kids > 0) {
    lines.push({
      label: `Kid (below ${KID_AGE_LIMIT} yrs)`,
      qty: kids,
      unit: RATE.kid,
      amount: kids * RATE.kid,
    });
  }

  return {
    people,
    total: lines.reduce((sum, l) => sum + l.amount, 0),
    lines,
    late,
  };
}

/** The price list shown on the event page — generated from the rules above. */
export const PRICE_TABLE: { label: string; price: number; note?: string }[] = [
  { label: `Single Entry (${KID_AGE_LIMIT} yrs & above)`, price: RATE.adult },
  { label: "Couple", price: PACKS.find((p) => p.id === "couple")!.price },
  {
    label: `Kid (below ${KID_AGE_LIMIT} yrs)`,
    price: RATE.kid,
    note: "ID proof mandatory for age verification",
  },
  {
    label: "Kid with Parents",
    price: PACKS.find((p) => p.id === "kid-with-parents")!.price,
    note: "2 adults + 1 kid · extra kids at the kid rate",
  },
  {
    label: "Students Offer",
    price: PACKS.find((p) => p.id === "student-trio")!.price,
    note: "3 students · student ID required at entry",
  },
];

export function rupees(amount: number): string {
  return `₹${amount.toLocaleString("en-IN")}`;
}

/** Short one-line summary of a party, e.g. "2 Adults · 1 Kid". */
export function partySummary(party: PartyCounts): string {
  const bits: string[] = [];
  if (party.adults) bits.push(`${party.adults} Adult${party.adults > 1 ? "s" : ""}`);
  if (party.students) bits.push(`${party.students} Student${party.students > 1 ? "s" : ""}`);
  if (party.kids) bits.push(`${party.kids} Kid${party.kids > 1 ? "s" : ""}`);
  return bits.join(" · ") || "No one selected";
}
