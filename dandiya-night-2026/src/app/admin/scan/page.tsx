import AuthGuard from "@/components/AuthGuard";
import Scanner from "@/components/Scanner";

export default function ScanPage() {
  return (
    <AuthGuard adminOnly>
      <main className="flex-1 w-full max-w-md mx-auto px-6 py-10 flex flex-col">
        <h1 className="font-display gold-text text-3xl text-center mb-8">Check-In Scanner</h1>
        <Scanner />
      </main>
    </AuthGuard>
  );
}
