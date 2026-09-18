"use client";

import { useState } from "react";
import FormInput from "@/components/FormInput";

function EyeIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
      <path
        d="M1.5 12S5 5 12 5s10.5 7 10.5 7-3.5 7-10.5 7S1.5 12 1.5 12Z"
        stroke="currentColor"
        strokeWidth="1.6"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <circle cx="12" cy="12" r="3" stroke="currentColor" strokeWidth="1.6" />
    </svg>
  );
}

function EyeOffIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
      <path
        d="M3 3l18 18M10.6 10.6a3 3 0 0 0 4.24 4.24M6.5 6.7C3.9 8.3 1.5 12 1.5 12s3.5 7 10.5 7c1.9 0 3.5-.5 4.8-1.2M9.9 5.2A10.6 10.6 0 0 1 12 5c7 0 10.5 7 10.5 7-.4.8-1.2 2-2.4 3.2"
        stroke="currentColor"
        strokeWidth="1.6"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}

export default function PasswordInput(
  props: Omit<React.ComponentProps<typeof FormInput>, "type" | "rightElement">
) {
  const [visible, setVisible] = useState(false);

  return (
    <FormInput
      {...props}
      type={visible ? "text" : "password"}
      rightElement={
        <button
          type="button"
          tabIndex={-1}
          onClick={() => setVisible((v) => !v)}
          className="text-[var(--muted)] hover:text-[var(--gold-1)] transition-colors"
          aria-label={visible ? "Hide password" : "Show password"}
        >
          {visible ? <EyeOffIcon /> : <EyeIcon />}
        </button>
      }
    />
  );
}
