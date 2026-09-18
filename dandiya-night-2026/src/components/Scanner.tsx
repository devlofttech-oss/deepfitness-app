"use client";

import { useEffect, useRef, useState } from "react";
import { AnimatePresence, motion } from "framer-motion";
import { doc, runTransaction, serverTimestamp } from "firebase/firestore";
import { db } from "@/lib/firebase/client";
import { EMPTY_PARTY, partySummary } from "@/lib/pricing";
import type { Ticket } from "@/lib/types";

type ScanResult = { ok: boolean; message: string } | null;

async function checkIn(ticketId: string): Promise<ScanResult> {
  try {
    const summary = await runTransaction(db, async (tx) => {
      const ref = doc(db, "tickets", ticketId);
      const snap = await tx.get(ref);

      if (!snap.exists()) throw new Error("INVALID");
      const ticket = snap.data() as Ticket;

      if (ticket.status === "checked_in") throw new Error("ALREADY");
      if (ticket.status !== "verified") throw new Error("NOT_VERIFIED");

      tx.update(ref, { status: "checked_in", checkedInAt: serverTimestamp() });
      return `${ticket.name} — ${partySummary(ticket.party ?? EMPTY_PARTY)}`;
    });

    return { ok: true, message: `Checked in: ${summary}` };
  } catch (err) {
    const reason = err instanceof Error ? err.message : "";
    if (reason === "ALREADY") return { ok: false, message: "Pass already checked in." };
    if (reason === "NOT_VERIFIED") return { ok: false, message: "Pass not verified." };
    if (reason === "INVALID") return { ok: false, message: "Invalid pass." };
    return { ok: false, message: "Not authorized or scan failed." };
  }
}

export default function Scanner() {
  const containerId = "qr-reader";
  const scannerRef = useRef<import("html5-qrcode").Html5Qrcode | null>(null);
  const busyRef = useRef(false);
  const [result, setResult] = useState<ScanResult>(null);

  useEffect(() => {
    let cancelled = false;

    (async () => {
      const { Html5Qrcode } = await import("html5-qrcode");
      if (cancelled) return;

      const scanner = new Html5Qrcode(containerId);
      scannerRef.current = scanner;

      try {
        await scanner.start(
          { facingMode: "environment" },
          {
            fps: 10,
            qrbox: (viewfinderWidth, viewfinderHeight) => {
              const size = Math.floor(Math.min(viewfinderWidth, viewfinderHeight) * 0.7);
              return { width: size, height: size };
            },
          },
          async (decodedText) => {
            if (busyRef.current) return;
            busyRef.current = true;

            const res = await checkIn(decodedText);
            setResult(res);

            setTimeout(() => {
              setResult(null);
              busyRef.current = false;
            }, 2400);
          },
          () => {}
        );
      } catch {
        setResult({ ok: false, message: "Camera access denied or unavailable." });
      }
    })();

    return () => {
      cancelled = true;
      scannerRef.current
        ?.stop()
        .then(() => scannerRef.current?.clear())
        .catch(() => {});
    };
  }, []);

  return (
    <div className="flex flex-col items-center gap-6">
      <div className="gold-border rounded-2xl overflow-hidden w-full aspect-square relative">
        <div id={containerId} className="w-full h-full" />
      </div>

      <AnimatePresence>
        {result && (
          <motion.div
            initial={{ opacity: 0, y: 12, scale: 0.95 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: -12 }}
            transition={{ duration: 0.25 }}
            className="w-full rounded-xl py-4 px-4 text-center text-sm font-medium"
            style={{
              background: result.ok ? "rgba(87,211,140,0.12)" : "rgba(255,107,107,0.12)",
              border: `1px solid ${result.ok ? "var(--success)" : "var(--danger)"}`,
              color: result.ok ? "var(--success)" : "var(--danger)",
            }}
          >
            {result.message}
          </motion.div>
        )}
      </AnimatePresence>

      <p className="text-xs text-[var(--muted)] text-center">
        Point the camera at the guest&rsquo;s pass QR code. One scan admits the whole booking.
      </p>
    </div>
  );
}
