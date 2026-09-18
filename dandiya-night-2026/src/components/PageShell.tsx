"use client";

import { motion } from "framer-motion";
import type { ReactNode } from "react";

export default function PageShell({
  children,
  className = "",
  wide = false,
}: {
  children: ReactNode;
  className?: string;
  wide?: boolean;
}) {
  return (
    <motion.main
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.45, ease: "easeOut" }}
      className={`flex-1 w-full ${wide ? "max-w-lg" : "max-w-md"} mx-auto px-6 py-10 flex flex-col ${className}`}
    >
      {children}
    </motion.main>
  );
}
