import type { InputHTMLAttributes, ReactNode } from "react";

interface FormInputProps extends InputHTMLAttributes<HTMLInputElement> {
  label: string;
  rightElement?: ReactNode;
}

export default function FormInput({ label, id, rightElement, ...props }: FormInputProps) {
  return (
    <div className="flex flex-col gap-1.5">
      <label htmlFor={id} className="text-xs uppercase tracking-widest text-[var(--muted)]">
        {label}
      </label>
      <div className="relative">
        <input
          id={id}
          className={`rounded-lg px-4 py-3 text-base w-full ${rightElement ? "pr-11" : ""}`}
          {...props}
        />
        {rightElement && (
          <div className="absolute right-3 top-1/2 -translate-y-1/2">{rightElement}</div>
        )}
      </div>
    </div>
  );
}
