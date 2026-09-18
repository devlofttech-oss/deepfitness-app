"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { signInWithEmailAndPassword, signOut } from "firebase/auth";
import { doc, getDoc } from "firebase/firestore";
import { auth, db } from "@/lib/firebase/client";
import PageShell from "@/components/PageShell";
import FormInput from "@/components/FormInput";
import PasswordInput from "@/components/PasswordInput";
import GoldButton from "@/components/GoldButton";

// Deliberately generic — this page's copy and errors must look like any
// other login form. It is not linked from anywhere in the app; reaching it
// at all means someone already knows the URL.
const GENERIC_ERROR = "Incorrect email or password.";

export default function AdminPortalPage() {
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
      setError(GENERIC_ERROR);
      return;
    }

    setPending(true);
    try {
      const cred = await signInWithEmailAndPassword(auth, email, password);
      const snap = await getDoc(doc(db, "profiles", cred.user.uid));
      const isAdmin = snap.exists() && snap.data().isAdmin === true;

      if (!isAdmin) {
        await signOut(auth);
        setError(GENERIC_ERROR);
        setPending(false);
        return;
      }

      router.push("/admin");
    } catch {
      setError(GENERIC_ERROR);
      setPending(false);
    }
  }

  return (
    <PageShell>
      <h2 className="font-display gold-text text-3xl text-center mb-8">Login</h2>
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
    </PageShell>
  );
}
