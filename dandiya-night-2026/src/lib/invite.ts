/**
 * The WhatsApp invite an admin sends by hand from the Bookings list.
 *
 * Nothing here sends anything on its own: the button only opens WhatsApp with
 * the message typed out, and the admin presses send. That keeps the whole
 * thing inside WhatsApp's own rules — no Business API, no number getting
 * flagged for bulk messaging.
 *
 * The wording lives in inviteMessage() and nowhere else, so editing it here
 * changes every invite.
 */

import {
  EVENT_DATE,
  EVENT_NAME,
  EVENT_TIME,
  PRESENTER,
  VENUE_MAP_URL,
  VENUE_SHORT,
} from "@/lib/event";
import { EMPTY_PARTY, partySummary } from "@/lib/pricing";
import type { Ticket } from "@/lib/types";

/** Guests type bare 10-digit numbers; wa.me needs the country code. */
const DEFAULT_COUNTRY_CODE = "91";

/**
 * Turns whatever the guest typed — "90195 50010", "+91-9019550010",
 * "09019550010" — into the bare digits wa.me expects.
 * Returns "" when there is nothing dialable, so callers can hide the button.
 */
export function toWhatsAppNumber(phone: string | null | undefined): string {
  const digits = (phone ?? "").replace(/\D/g, "").replace(/^0+/, "");
  if (digits.length < 10) return "";
  return digits.length === 10 ? DEFAULT_COUNTRY_CODE + digits : digits;
}

function firstName(name: string | null | undefined): string {
  return (name ?? "").trim().split(/\s+/)[0] || "there";
}

/**
 * The pre-written invite. WhatsApp renders *text* between a pair of plain
 * asterisks as bold, so the "costs extra" marker is U+2217 (∗), not "*" —
 * four plain asterisks in the extras list would bold half the message.
 */
export function inviteMessage(ticket: Ticket): string {
  return [
    `Namaste ${firstName(ticket.name)}! 🪔`,
    "",
    `You are invited to *${EVENT_NAME}* — ${PRESENTER}.`,
    "",
    `📅 ${EVENT_DATE}`,
    `🕠 ${EVENT_TIME}`,
    `📍 ${VENUE_SHORT}`,
    VENUE_MAP_URL,
    "",
    `Your booking: ${partySummary(ticket.party ?? EMPTY_PARTY)}.`,
    "Open My Pass on the site and show the QR code at the gate.",
    "",
    "On the night:",
    "• Live music and a DJ",
    "• A choreographer to get you moving",
    "• Food",
    "• Complimentary dandiya sticks",
    "• PebbleCo Accessory store∗",
    "• Face painting∗",
    "• Posebox∗",
    "",
    "∗ Charged separately at the venue",
    "",
    "👗 Traditional wear please.",
    "⚠️ Kids and personal belongings are not our responsibility.",
    "",
    "See you on the floor 💃🕺",
  ].join("\n");
}

/**
 * Deep link that opens WhatsApp on the guest's number with the invite ready
 * to send. Works the same on phone and on WhatsApp Web.
 */
export function whatsappInviteLink(ticket: Ticket): string {
  return `https://wa.me/${toWhatsAppNumber(ticket.phone)}?text=${encodeURIComponent(
    inviteMessage(ticket)
  )}`;
}
