import Link from "next/link";
import PageShell from "@/components/PageShell";
import { CONTACT_PHONES, VENUE_ADDRESS, VENUE_MAP_URL, VENUE_NAME } from "@/lib/event";
import { PhoneIcon, PinIcon, TicketIcon } from "@/components/Ornaments";

const FAQ = [
  {
    q: "My payment is done but the pass still says pending.",
    a: "Every payment is checked by hand against the transaction ID. It usually takes a few hours. The page updates itself the moment it is verified — no need to refresh.",
  },
  {
    q: "Can I book for my whole family in one go?",
    a: "Yes. On the booking page, set how many adults, students and kids are coming. The best bundle rate is applied for you, and one QR code admits the entire group.",
  },
  {
    q: "What do I show at the gate?",
    a: "The QR code on your pass page. It is scanned once at entry, so keep the group together when you arrive.",
  },
  {
    q: "I entered the wrong transaction ID.",
    a: "Call us on the numbers below with your booking name and the correct ID, and we will sort it out before the event.",
  },
];

export default function HelpPage() {
  return (
    <PageShell wide>
      <h2 className="font-display gold-text text-3xl text-center mb-2">Need Help?</h2>
      <p className="text-center text-xs text-[var(--muted)] mb-8">
        Call us any time before the event — we answer fastest on the phone.
      </p>

      <div className="flex flex-wrap items-center justify-center gap-2 mb-8">
        {CONTACT_PHONES.map((phone) => (
          <a
            key={phone}
            href={`tel:+91${phone}`}
            className="gold-btn flex items-center gap-2 rounded-xl px-6 py-3 text-sm uppercase tracking-wide"
          >
            <PhoneIcon size={16} />
            {phone}
          </a>
        ))}
      </div>

      <div className="flex flex-col gap-3">
        {FAQ.map((item) => (
          <div key={item.q} className="gold-border rounded-xl p-4">
            <p className="text-sm text-[var(--gold-1)] mb-1.5">{item.q}</p>
            <p className="text-xs text-[var(--muted)] leading-relaxed">{item.a}</p>
          </div>
        ))}
      </div>

      <Link
        href="/rules"
        className="gold-border rounded-xl p-4 mt-3 flex items-start gap-3 hover:border-[var(--gold-3)] transition-colors"
      >
        <span className="text-[var(--gold-3)] mt-0.5">
          <TicketIcon size={16} />
        </span>
        <span>
          <span className="block text-sm text-[var(--foreground)] underline underline-offset-2">
            Rules & Regulations
          </span>
          <span className="block text-xs text-[var(--muted)] mt-0.5 leading-relaxed">
            Entry, safety, dress code, kids, dance floor and photography — read before you arrive.
          </span>
        </span>
      </Link>

      <a
        href={VENUE_MAP_URL}
        target="_blank"
        rel="noopener noreferrer"
        className="gold-border rounded-xl p-4 mt-3 flex items-start gap-3 hover:border-[var(--gold-3)] transition-colors"
      >
        <span className="text-[var(--gold-3)] mt-0.5">
          <PinIcon size={16} />
        </span>
        <span>
          <span className="block text-sm text-[var(--foreground)] underline underline-offset-2">
            {VENUE_NAME}
          </span>
          <span className="block text-xs text-[var(--muted)] mt-0.5 leading-relaxed">
            {VENUE_ADDRESS}
          </span>
        </span>
      </a>
    </PageShell>
  );
}
