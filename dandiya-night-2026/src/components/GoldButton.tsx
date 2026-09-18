"use client";

import { motion, type HTMLMotionProps } from "framer-motion";

interface GoldButtonProps extends HTMLMotionProps<"button"> {
  loading?: boolean;
  variant?: "solid" | "outline";
}

export default function GoldButton({
  children,
  loading,
  variant = "solid",
  className = "",
  disabled,
  ...props
}: GoldButtonProps) {
  const base =
    "w-full rounded-xl py-3 px-6 text-sm tracking-wide uppercase disabled:opacity-50 disabled:cursor-not-allowed";
  const styles =
    variant === "solid"
      ? "gold-btn"
      : "gold-border text-[var(--gold-1)] hover:bg-[var(--gold-2)]/10";

  return (
    <motion.button
      whileHover={{ scale: 1.02 }}
      whileTap={{ scale: 0.97 }}
      transition={{ type: "spring", stiffness: 400, damping: 20 }}
      className={`${base} ${styles} ${className}`}
      disabled={disabled || loading}
      {...props}
    >
      {loading ? "Please wait…" : children}
    </motion.button>
  );
}
