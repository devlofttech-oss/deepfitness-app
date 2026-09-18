import type { Metadata } from "next";
import { Poppins, Rozha_One } from "next/font/google";
import { Analytics } from "@vercel/analytics/next";
import Nav from "@/components/Nav";
import { AuthProvider } from "@/lib/firebase/AuthProvider";
import {
  EVENT_DATE,
  EVENT_NAME,
  EVENT_TIME,
  PRESENTER,
  VENUE_SHORT,
} from "@/lib/event";
import "./globals.css";

const poppins = Poppins({
  variable: "--font-poppins",
  subsets: ["latin"],
  weight: ["300", "400", "500", "600", "700"],
});

const rozha = Rozha_One({
  variable: "--font-rozha",
  subsets: ["latin"],
  weight: "400",
});

export const metadata: Metadata = {
  title: `${EVENT_NAME} — ${PRESENTER}`,
  description: `${EVENT_DATE}, ${EVENT_TIME} at ${VENUE_SHORT}. Live music and DJ, dinner, a choreographer on the floor, and complimentary dandiya sticks. Limited passes.`,
  openGraph: {
    title: `${EVENT_NAME} — ${PRESENTER}`,
    description: `Feel the rhythm of tradition. ${EVENT_DATE} · ${EVENT_TIME} · ${VENUE_SHORT}`,
    type: "website",
  },
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html lang="en" className={`${poppins.variable} ${rozha.variable} h-full antialiased`}>
      <body className="min-h-full flex flex-col">
        <AuthProvider>
          <Nav />
          {children}
        </AuthProvider>
        <Analytics />
      </body>
    </html>
  );
}
