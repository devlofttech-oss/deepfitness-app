import Link from "next/link";
import AuthGuard from "@/components/AuthGuard";
import AdminTabs from "@/components/AdminTabs";
import AdminStats from "@/components/AdminStats";

export default function AdminPage() {
  return (
    <AuthGuard adminOnly>
      <main className="flex-1 w-full max-w-lg mx-auto px-6 py-10">
        <div className="flex items-center justify-between mb-6">
          <h1 className="font-display gold-text text-3xl">Admin</h1>
          <Link
            href="/admin/scan"
            className="text-xs uppercase tracking-wide text-[var(--muted)] hover:text-[var(--gold-1)] transition-colors"
          >
            Scan &rarr;
          </Link>
        </div>
        <AdminStats />
        <AdminTabs />
      </main>
    </AuthGuard>
  );
}
