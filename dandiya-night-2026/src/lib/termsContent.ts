import { KID_AGE_LIMIT, LATE_FLAT_PER_PERSON, RATE, rupees } from "@/lib/pricing";
import { EVENT_NAME, PRESENTER, VENUE_NAME } from "@/lib/event";

export interface TermsSection {
  heading: string;
  body: string[];
}

export const TERMS_TITLE = `${EVENT_NAME} — Terms & Conditions`;

export const TERMS_INTRO = `By booking a pass for ${EVENT_NAME}, presented by ${PRESENTER}, you acknowledge and agree to the following terms and to the Rules & Regulations for the night.`;

export const TERMS_SECTIONS: TermsSection[] = [
  {
    heading: "1. Passes & Payment",
    body: [
      "All bookings are strictly NON-REFUNDABLE and NON-CANCELLABLE. Once a payment is submitted it cannot be reversed or called off, for any reason — including change of mind, inability to attend, weather, or any other personal or unforeseen circumstance.",
      "Passes are non-transferable and may not be sold on or handed to another person.",
      "A booking is confirmed only after the organizers verify the payment against the transaction ID submitted. Until then the booking stays pending.",
      `Prices are as listed at the time of booking. After 12th October, all entries are charged at ${rupees(LATE_FLAT_PER_PERSON)} per person.`,
      "Entry is permitted only against a valid pass / wristband. The pass QR code is scanned once at the gate and cannot be reused.",
      "Passes booked under the Students Offer require a valid student ID for every person in the group at entry.",
    ],
  },
  {
    heading: "2. Entry, Age & Re-entry",
    body: [
      `Kids below ${KID_AGE_LIMIT} years are charged the kid rate of ${rupees(RATE.kid)} and are admitted only with parents. ID proof is mandatory for age verification at the gate.`,
      "The organizers reserve the right to verify the identity and age of any pass holder, and to refuse entry where the details do not match the booking.",
      "Re-entry is not allowed without permission from the organizer.",
      "Limited passes are available for the night. Once capacity is reached, bookings close regardless of the date.",
    ],
  },
  {
    heading: "3. Prohibited Items",
    body: [
      "Outside dandiya sticks, food, drinks, alcohol and cigarettes are strictly not allowed inside the venue. Dandiya sticks are provided at the event.",
      "Sharp objects, weapons and inflammable items are strictly prohibited.",
      "Any attendee found in violation will be denied entry or removed from the venue without refund, and may be handed over to venue security or local authorities as necessary.",
    ],
  },
  {
    heading: "4. Dress Code & Behaviour",
    body: [
      "Traditional or decent wear is appreciated. No vulgar behaviour will be tolerated.",
      "Misbehaving, fighting, or harassing ladies will lead to immediate removal from the venue without refund.",
      "Attendees must respect all other participants, staff, vendors and performers.",
    ],
  },
  {
    heading: "5. Kids & Family",
    body: [
      "Parents are fully responsible for the safety of their children at all times.",
      `Kids below ${KID_AGE_LIMIT} years must be accompanied by a parent or guardian throughout the event.`,
      "No running or pushing on the dance floor.",
    ],
  },
  {
    heading: "6. Dance Floor",
    body: [
      "Dance only in the designated area and follow the circle pattern set by the organizers and anchors.",
      "If a rented dandiya stick breaks, exchange it at the counter. Sticks must not be thrown under any circumstances.",
      "Attendees must follow the instructions of the organizers, security personnel and anchors at all times.",
    ],
  },
  {
    heading: "7. Belongings & Liability",
    body: [
      "The management is not responsible for the loss of valuables, mobile phones or jewellery. Attendees are responsible for their own belongings, footwear and vehicles.",
      `Entry to and participation in ${EVENT_NAME} is at the attendee's own risk. The organizers, ${VENUE_NAME}, and any associated vendors or sponsors shall not be held liable for any loss, injury, theft, damage or inconvenience experienced before, during or after the event, except where caused by proven gross negligence on the part of the organizers.`,
      "The organizers have full rights to change the timings, alter the schedule, or stop the event on account of rain or any other emergency. As the event is held on an open-air field, it may be delayed, shortened or moved within the venue. None of this entitles an attendee to a refund.",
    ],
  },
  {
    heading: "8. Photography & Content",
    body: [
      "The event will be photographed and videographed by Deepfitness@mysore and Sadhana Team for social media promotion. By attending, you consent to being captured in such photos and videos and to their use on the event's social media and promotional channels.",
    ],
  },
  {
    heading: "9. Acceptance",
    body: [
      "By booking a pass and/or entering the venue, the attendee confirms they have read, understood and agreed to these Terms & Conditions and the Rules & Regulations in full.",
    ],
  },
];
