import { KID_AGE_LIMIT, RATE, rupees } from "@/lib/pricing";

export interface RuleGroup {
  /** Picks the ornament drawn beside the heading — see RULE_ICONS. */
  id: "entry" | "safety" | "conduct" | "family" | "floor" | "media";
  heading: string;
  items: string[];
}

export const RULES_TITLE = "General Rules";

export const RULES_INTRO =
  "A few things that keep the night safe and enjoyable for everyone. By entering the venue you agree to follow them.";

/**
 * House rules as issued by the organizers. The kids line is worded to match
 * the price list in src/lib/pricing.ts — every kid below KID_AGE_LIMIT pays
 * the kid rate; there is no free age band.
 */
export const RULES: RuleGroup[] = [
  {
    id: "entry",
    heading: "Entry & Tickets",
    items: [
      "Entry only with a valid ticket / wristband. Tickets are non-refundable and non-transferable.",
      `Kids below ${KID_AGE_LIMIT} are charged the kid rate of ${rupees(RATE.kid)} and are admitted only with parents. ID proof is mandatory for age verification.`,
      "Re-entry is not allowed without permission from the organizer.",
    ],
  },
  {
    id: "safety",
    heading: "Safety & Security",
    items: [
      "Outside dandiya sticks, food, drinks, alcohol and cigarettes are strictly NOT allowed.",
      "Sharp objects, weapons and inflammable items are strictly prohibited.",
      "Management is not responsible for loss of valuables, mobiles or jewellery. Please take care of your belongings.",
    ],
  },
  {
    id: "conduct",
    heading: "Dress Code & Behaviour",
    items: [
      "Traditional / decent wear is appreciated. No vulgar behaviour will be tolerated.",
      "Misbehaving, fighting, or harassing ladies will lead to immediate removal without refund.",
      "Please respect all participants and staff.",
    ],
  },
  {
    id: "family",
    heading: "Kids & Family",
    items: [
      "Parents are fully responsible for their kids' safety.",
      `Kids below ${KID_AGE_LIMIT} must be accompanied by a parent or guardian at all times.`,
      "No running or pushing on the dance floor.",
    ],
  },
  {
    id: "floor",
    heading: "Dance Floor Rules",
    items: [
      "Dance only in the designated area. Follow the circle pattern.",
      "If your dandiya stick is broken, please exchange it at the counter (if rental).",
      "Do not throw sticks.",
    ],
  },
  {
    id: "media",
    heading: "Photography & Other",
    items: [
      "The event will be photographed / videographed by the Sadhana Team for social media promotion.",
      "Organizers have full rights to change timings or stop the event due to rain or any emergency reason.",
      "Follow the instructions of the organizers, security and anchors.",
    ],
  },
];

export const NON_REFUNDABLE_NOTE =
  "All bookings are non-refundable and non-cancellable. Once a payment is submitted it cannot be reversed, and passes cannot be transferred to another person.";
