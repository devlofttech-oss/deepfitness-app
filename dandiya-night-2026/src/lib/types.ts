import type { Category, PartyCounts } from "@/lib/pricing";

export type TicketStatus = "pending" | "verified" | "rejected" | "checked_in";

export interface Profile {
  id: string;
  email: string;
  name: string;
  phone: string;
  instagram?: string;
  isAdmin: boolean;
  createdAt: number;
}

export interface Attendee {
  name: string;
  category: Category;
  /** Collected for the lead booker; optional for the rest of the party. */
  phone?: string;
  /** Collected for kids so the gate can check the age band. */
  age?: number;
}

export interface Ticket {
  id: string;
  userId: string;
  name: string;
  email: string;
  phone: string;
  instagram?: string;
  party: PartyCounts;
  attendees: Attendee[];
  /** Amount quoted by src/lib/pricing.ts at the time of booking, in rupees. */
  amount: number;
  transactionId: string;
  referralCode?: string;
  status: TicketStatus;
  createdAt: number;
  verifiedAt: number | null;
  checkedInAt: number | null;
}
