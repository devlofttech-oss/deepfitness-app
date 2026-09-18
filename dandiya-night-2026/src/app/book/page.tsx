import AuthGuard from "@/components/AuthGuard";
import BookForm from "@/components/BookForm";
import LaunchGate from "@/components/LaunchGate";

export default function BookPage() {
  return (
    <LaunchGate message="Bookings open when the countdown ends. Check back then.">
      <AuthGuard>
        <BookForm />
      </AuthGuard>
    </LaunchGate>
  );
}
