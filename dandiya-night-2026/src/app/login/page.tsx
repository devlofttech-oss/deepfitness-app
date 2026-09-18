"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { signInWithEmailAndPassword } from "firebase/auth";
import { auth } from "@/lib/firebase/client";
import PageShell from "@/components/PageShell";
import FormInput from "@/components/FormInput";
import PasswordInput from "@/components/PasswordInput";
import GoldButton from "@/components/GoldButton";
import LaunchGate from "@/components/LaunchGate";

function friendlyError(code: string) {
  if (
    code.includes("invalid-credential") ||
    code.includes("wrong-password") ||
    code.includes("user-not-found")
  ) {
    return "Incorrect email or password.";
  }
  if (code.includes("invalid-email")) return "Enter a valid email address.";
  if (code.includes("too-many-requests")) return "Too many attempts. Try again later.";
  return "Something went wrong. Please try again.";
}

export default function LoginPage() {
  const router = useRouter();
  const [error, setError] = useState("");
  const [pending, setPending] = useState(false);

  async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setError("");
    const formData = new FormData(e.currentTarget);
    const email = String(formData.get("email") || "").trim();
    const password = String(formData.get("password") || "");

    if (!email || !password) {
      setError("Email and password are required.");
      return;
    }

    setPending(true);
    try {
      await signInWithEmailAndPassword(auth, email, password);
      router.push("/ticket");
    } catch (err) {
      const code = err && typeof err === "object" && "code" in err ? String(err.code) : "";
      setError(friendlyError(code));
      setPending(false);
    }
  }

  return (
    <LaunchGate message="Login opens when the countdown ends. Check back then.">
      <PageShell>
        <h2 className="font-display gold-text text-3xl text-center mb-8">Welcome Back</h2>
        <form onSubmit={handleSubmit} className="flex flex-col gap-4">
          <FormInput
            id="email"
            name="email"
            type="email"
            label="Email"
            required
            autoComplete="email"
          />
          <PasswordInput
            id="password"
            name="password"
            label="Password"
            required
            autoComplete="current-password"
          />
          {error && <p className="text-sm text-[var(--danger)]">{error}</p>}
          <GoldButton type="submit" loading={pending} className="mt-2">
            Log In
          </GoldButton>
        </form>
        <p className="text-center text-xs text-[var(--muted)] mt-6">
          New here?{" "}
          <Link href="/signup" className="text-[var(--gold-1)] underline">
            Create an account
          </Link>
        </p>
      </PageShell>
    </LaunchGate>
  );
}
