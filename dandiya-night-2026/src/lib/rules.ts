import { KID_AGE_LIMIT, RATE, rupees } from "@/lib/pricing";

export interface RuleGroup {
  /** Picks the ornament drawn beside the heading — see RULE_ICONS. */
  id: "entry" | "safety" | "conduct" | "kids" | "event";
  heading: string;
  items: string[];
}

export const RULES_TITLE = "Rules & Regulations";

export const RULES_INTRO =
  "A few things that keep the night safe and enjoyable for everyone. By entering the venue you agree to follow them.";

/**
 * House rules as issued by the organizers, each point stated once. The kids
 * line is worded to match the price list in src/lib/pricing.ts — every kid
 * below KID_AGE_LIMIT pays the kid rate; there is no free age band.
 */
export const RULES: RuleGroup[] = [
  {
    id: "entry",
    heading: "Entry & Tickets",
    items: [
      "Entry only with a valid ticket / wristband. Tickets are non-refundable and non-transferable.",
      "No re-entry without permission from the organizer.",
      `Kids below ${KID_AGE_LIMIT} pay the kid rate of ${rupees(RATE.kid)} and are admitted only with parents. ID proof is mandatory for age verification.`,
    ],
  },
  {
    id: "safety",
    heading: "Safety & Security",
    items: [
      "Outside dandiya sticks, food, drinks, alcohol and cigarettes are strictly NOT allowed.",
      "Sharp objects, weapons and inflammable items are strictly prohibited.",
      "Management is not responsible for loss of valuables. Please take care of your belongings.",
    ],
  },
  {
    id: "conduct",
    heading: "Conduct",
    items: [
      "Traditional / decent wear is appreciated. No vulgar behaviour will be tolerated.",
      "Misbehaving, fighting, or harassing ladies will lead to immediate removal without refund.",
      "Respect all participants and staff, and follow the instructions of the organizers, security and anchors.",
    ],
  },
  {
    id: "kids",
    heading: "Kids & Dance Floor",
    items: [
      `Parents are fully responsible for their kids' safety, and kids below ${KID_AGE_LIMIT} must be accompanied at all times.`,
      "Dance only in the designated area, follow the circle pattern, and no running or pushing.",
      "Do not throw sticks. Exchange a broken rental stick at the counter.",
    ],
  },
  {
    id: "event",
    heading: "The Event",
    items: [
      "Organizers have full rights to change timings or stop the event due to rain or any emergency reason.",
      "The event will be photographed / videographed by the Sadhana Team for social media promotion.",
    ],
  },
];

export const NON_REFUNDABLE_NOTE =
  "All bookings are non-refundable and non-cancellable. Once a payment is submitted it cannot be reversed, and passes cannot be transferred to another person.";
