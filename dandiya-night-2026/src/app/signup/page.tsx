"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { createUserWithEmailAndPassword } from "firebase/auth";
import { doc, setDoc, serverTimestamp } from "firebase/firestore";
import { auth, db } from "@/lib/firebase/client";
import PageShell from "@/components/PageShell";
import FormInput from "@/components/FormInput";
import PasswordInput from "@/components/PasswordInput";
import GoldButton from "@/components/GoldButton";
import LaunchGate from "@/components/LaunchGate";
import TermsModal from "@/components/TermsModal";
import { normalizeUsername, usernameToEmail, validateUsername } from "@/lib/username";

function friendlyError(code: string) {
  if (code.includes("email-already-in-use")) return "That username is already taken.";
  if (code.includes("weak-password")) return "Password must be at least 6 characters.";
  if (code.includes("invalid-email")) return "That username cannot be used. Try another.";
  return "Something went wrong. Please try again.";
}

export default function SignupPage() {
  const router = useRouter();
  const [error, setError] = useState("");
  const [pending, setPending] = useState(false);
  const [agreed, setAgreed] = useState(false);
  const [termsOpen, setTermsOpen] = useState(false);

  async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setError("");
    const formData = new FormData(e.currentTarget);
    const name = String(formData.get("name") || "").trim();
    const phone = String(formData.get("phone") || "").trim();
    const instagram = String(formData.get("instagram") || "").trim();
    const username = normalizeUsername(String(formData.get("username") || ""));
    const password = String(formData.get("password") || "");

    if (!name || !phone || !username || !password) {
      setError("All fields are required.");
      return;
    }
    const usernameError = validateUsername(username);
    if (usernameError) {
      setError(usernameError);
      return;
    }
    if (!agreed) {
      setError("You must confirm you have read the Terms & Conditions.");
      return;
    }

    setPending(true);
    try {
      const email = usernameToEmail(username);
      const cred = await createUserWithEmailAndPassword(auth, email, password);
      await setDoc(doc(db, "profiles", cred.user.uid), {
        username,
        email,
        name,
        phone,
        instagram,
        isAdmin: false,
        createdAt: serverTimestamp(),
      });
      router.push("/book");
    } catch (err) {
      const code = err && typeof err === "object" && "code" in err ? String(err.code) : "";
      setError(friendlyError(code));
      setPending(false);
    }
  }

  return (
    <LaunchGate message="Registration opens when the countdown ends. Check back then.">
      <PageShell>
        <h2 className="font-display gold-text text-3xl text-center mb-2">Create Account</h2>
        <p className="text-center text-xs text-[var(--muted)] mb-8">
          One account per booking. You can add your whole group on the next step.
        </p>
        <form onSubmit={handleSubmit} className="flex flex-col gap-4">
          <FormInput id="name" name="name" label="Full Name" required autoComplete="name" />
          <FormInput
            id="phone"
            name="phone"
            label="Phone Number"
            required
            autoComplete="tel"
            inputMode="tel"
          />
          <FormInput
            id="username"
            name="username"
            label="Username"
            required
            autoComplete="username"
            autoCapitalize="none"
            spellCheck={false}
            placeholder="e.g. riya.shah"
          />
          <PasswordInput
            id="password"
            name="password"
            label="Password"
            required
            minLength={6}
            autoComplete="new-password"
          />
          <p className="text-[11px] text-[var(--muted)] -mt-1 leading-relaxed">
            Remember your username and password — there is no email reset. If you forget them,
            call us and we will sort it out.
          </p>
          <FormInput
            id="instagram"
            name="instagram"
            label="Instagram ID (optional)"
            autoComplete="off"
            placeholder="@yourhandle"
          />

          <label className="flex items-start gap-2.5 text-xs text-[var(--muted)]">
            <input
              type="checkbox"
              checked={agreed}
              onChange={(e) => setAgreed(e.target.checked)}
              className="mt-0.5 accent-[var(--gold-3)]"
            />
            <span>
              I have read the{" "}
              <button
                type="button"
                onClick={() => setTermsOpen(true)}
                className="text-[var(--gold-1)] underline underline-offset-2"
              >
                Terms &amp; Conditions
              </button>
            </span>
          </label>

          {error && <p className="text-sm text-[var(--danger)]">{error}</p>}
          <GoldButton type="submit" loading={pending} disabled={!agreed} className="mt-2">
            Sign Up
          </GoldButton>
        </form>
        <p className="text-center text-xs text-[var(--muted)] mt-6">
          Already have an account?{" "}
          <Link href="/login" className="text-[var(--gold-1)] underline">
            Log in
          </Link>
        </p>
      </PageShell>

      <TermsModal open={termsOpen} onClose={() => setTermsOpen(false)} />
    </LaunchGate>
  );
}
