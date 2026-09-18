"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "@/lib/firebase/AuthProvider";

export default function AuthGuard({
  children,
  adminOnly = false,
}: {
  children: React.ReactNode;
  adminOnly?: boolean;
}) {
  const { user, profile, loading } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (loading) return;
    if (!user) {
      router.replace("/login");
      return;
    }
    if (adminOnly && profile && !profile.isAdmin) {
      router.replace("/ticket");
    }
  }, [loading, user, profile, adminOnly, router]);

  if (loading || !user || (adminOnly && !profile?.isAdmin)) {
    return (
      <div className="flex-1 flex items-center justify-center py-24">
        <div className="w-6 h-6 rounded-full border-2 border-[var(--border)] border-t-[var(--gold-2)] animate-spin" />
      </div>
    );
  }

  return <>{children}</>;
}
