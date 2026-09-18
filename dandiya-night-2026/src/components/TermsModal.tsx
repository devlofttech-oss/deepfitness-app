"use client";

import { useSyncExternalStore } from "react";
import { createPortal } from "react-dom";
import Link from "next/link";
import { AnimatePresence, motion } from "framer-motion";
import { TERMS_INTRO, TERMS_SECTIONS, TERMS_TITLE } from "@/lib/termsContent";

const noopSubscribe = () => () => {};

export default function TermsModal({
  open,
  onClose,
}: {
  open: boolean;
  onClose: () => void;
}) {
  const mounted = useSyncExternalStore(
    noopSubscribe,
    () => true,
    () => false
  );
  if (!mounted) return null;

  return createPortal(
    <AnimatePresence>
      {open && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          className="fixed inset-0 z-50 flex items-end sm:items-center justify-center px-4 pb-4 sm:pb-0"
          style={{ background: "rgba(12, 2, 5, 0.78)" }}
          onClick={onClose}
        >
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: 20 }}
            transition={{ duration: 0.25 }}
            onClick={(e) => e.stopPropagation()}
            className="gold-border rounded-2xl w-full max-w-sm max-h-[80vh] overflow-y-auto p-6"
          >
            <h3 className="font-display gold-text text-xl mb-3">{TERMS_TITLE}</h3>
            <p className="text-xs text-[var(--muted)] leading-relaxed mb-4">{TERMS_INTRO}</p>
            <div className="space-y-4">
              {TERMS_SECTIONS.map((section) => (
                <div key={section.heading}>
                  <h4 className="text-xs font-semibold text-[var(--gold-1)] uppercase tracking-wide mb-1.5">
                    {section.heading}
                  </h4>
                  <div className="space-y-1.5">
                    {section.body.map((para, i) => (
                      <p key={i} className="text-xs text-[var(--muted)] leading-relaxed">
                        {para}
                      </p>
                    ))}
                  </div>
                </div>
              ))}
            </div>
            <Link
              href="/rules"
              target="_blank"
              className="block text-center text-[11px] uppercase tracking-[0.2em] text-[var(--gold-1)] underline underline-offset-4 mt-5"
            >
              Read the General Rules &rarr;
            </Link>
            <button
              onClick={onClose}
              className="gold-btn w-full rounded-xl py-2.5 text-xs uppercase tracking-wide mt-4"
            >
              Close
            </button>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>,
    document.body
  );
}
