import AuthGuard from "@/components/AuthGuard";
import TicketView from "@/components/TicketView";

export default function TicketPage() {
  return (
    <AuthGuard>
      <TicketView />
    </AuthGuard>
  );
}
