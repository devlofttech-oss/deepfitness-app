"use client";

import { motion } from "framer-motion";
import { WhatsAppIcon } from "@/components/Ornaments";
import { toWhatsAppNumber, whatsappInviteLink } from "@/lib/invite";
import type { Ticket } from "@/lib/types";

/** WhatsApp's own green, so the button reads as WhatsApp and not as a pass action. */
const WHATSAPP_GREEN = "#25D366";

/**
 * Opens WhatsApp on this booking's number with the invite pre-typed. It never
 * sends — the admin reads it over and presses send in WhatsApp themselves.
 * Renders nothing when the booking has no dialable number.
 *
 * `label` switches it from the bare icon used on the booking cards to the
 * wider button the Invite tab works down.
 */
export default function WhatsAppInvite({
  ticket,
  label,
}: {
  ticket: Ticket;
  label?: string;
}) {
  if (!toWhatsAppNumber(ticket.phone)) return null;

  return (
    <motion.a
      whileHover={{ scale: label ? 1.02 : 1.08 }}
      whileTap={{ scale: label ? 0.98 : 0.94 }}
      href={whatsappInviteLink(ticket)}
      target="_blank"
      rel="noopener noreferrer"
      title={`Invite ${ticket.name} on WhatsApp`}
      aria-label={`Invite ${ticket.name} on WhatsApp`}
      className={
        label
          ? "inline-flex items-center justify-center gap-2 rounded-lg px-4 py-2 text-xs uppercase tracking-wide transition-colors"
          : "inline-flex items-center justify-center rounded-full w-8 h-8 shrink-0 transition-colors"
      }
      style={{
        color: WHATSAPP_GREEN,
        border: `1px solid ${WHATSAPP_GREEN}66`,
        background: `${WHATSAPP_GREEN}14`,
      }}
    >
      <WhatsAppIcon size={16} />
      {label}
    </motion.a>
  );
}
