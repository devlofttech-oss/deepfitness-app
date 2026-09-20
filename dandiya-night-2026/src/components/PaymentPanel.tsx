"use client";

import Image from "next/image";
import { motion } from "framer-motion";
import { CONTACT_PHONES, PAYMENT_QR, UPI_ID } from "@/lib/event";
import { rupees } from "@/lib/pricing";

/**
 * The pay-first half of the booking page: amount, UPI QR, and what to do
 * while the QR is not in place yet.
 */
export default function PaymentPanel({ amount }: { amount: number }) {
  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.96 }}
      animate={{ opacity: 1, scale: 1 }}
      transition={{ duration: 0.45 }}
      className="gold-border rounded-2xl p-5 flex flex-col items-center gap-3"
    >
      <p className="text-[10px] uppercase tracking-[0.3em] text-[var(--gold-3)]">Amount to pay</p>
      <p className="font-display gold-text text-4xl tabular-nums leading-none">
        {rupees(amount)}
      </p>

      {PAYMENT_QR.ready ? (
        <div className="bg-white rounded-xl p-3 mt-1">
          <Image
            src={PAYMENT_QR.src}
            alt="UPI payment QR code"
            width={802}
            height={868}
            className="w-full max-w-[300px] h-auto"
            priority
          />
        </div>
      ) : (
        <div className="mt-1 w-full max-w-[260px] aspect-square rounded-xl border border-dashed border-[var(--gold-4)] flex flex-col items-center justify-center gap-3 px-6 text-center">
          <svg width="38" height="38" viewBox="0 0 24 24" fill="none" aria-hidden className="text-[var(--gold-3)]">
            <g stroke="currentColor" strokeWidth="1.6">
              <rect x="3" y="3" width="7" height="7" rx="1" />
              <rect x="14" y="3" width="7" height="7" rx="1" />
              <rect x="3" y="14" width="7" height="7" rx="1" />
            </g>
            <g fill="currentColor">
              <rect x="5.5" y="5.5" width="2" height="2" />
              <rect x="16.5" y="5.5" width="2" height="2" />
              <rect x="5.5" y="16.5" width="2" height="2" />
              <rect x="14" y="14" width="3" height="3" />
              <rect x="18" y="18" width="3" height="3" />
              <rect x="14" y="19" width="2" height="2" />
              <rect x="19" y="14" width="2" height="2" />
            </g>
          </svg>
          <p className="text-xs text-[var(--muted)] leading-relaxed">
            The UPI QR code is being set up. Call{" "}
            <a href={`tel:+91${CONTACT_PHONES[0]}`} className="text-[var(--gold-1)] underline">
              {CONTACT_PHONES[0]}
            </a>{" "}
            to get the payment details, then submit your transaction ID below.
          </p>
        </div>
      )}

      {UPI_ID && (
        <p className="text-xs text-[var(--muted)]">
          UPI ID: <span className="text-[var(--foreground)]">{UPI_ID}</span>
        </p>
      )}

      <p className="text-[11px] text-[var(--muted)] text-center leading-relaxed">
        Pay the exact amount, then enter the UPI transaction / UTR ID below. Your pass is issued
        once we verify the payment.
      </p>
    </motion.div>
  );
}
