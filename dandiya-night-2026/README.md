# Dandiya Night 2026 — SK Presents

Maroon-and-gold, mobile-first pass booking for a garba night, with manual UPI
payment verification and QR check-in at the gate. Same workflow as Euphoria'26,
rebuilt for a public event with group pricing.

## Stack

Next.js 16 (App Router, client-rendered auth/data) · Firebase (Auth + Firestore) ·
Tailwind v4 · Framer Motion · `qrcode` · `html5-qrcode` · Rozha One + Poppins

## Flow

- **Guest**: `/` (poster landing, countdown) → `/event` (highlights, venue, price
  list, key rules) → `/rules` (full house rules) → `/signup` (name, phone, email,
  password, optional Instagram) →
  `/book` (pick the party, see the live total, pay by UPI QR, submit the
  transaction ID, accept the non-refundable terms) → `/ticket` (pending →
  verified QR / rejected), which updates live.
- **Slot counter**: the landing and event pages show passes remaining out of 400,
  counting down as bookings are approved. Approving writes the ticket and the
  public counter (`stats/slots`) in one transaction, so simultaneous approvals
  can't lose a count; opening `/admin` re-syncs the counter from the real ticket
  data if it ever drifts. Anyone can read that one document; only admins write it.
- **Admin**: `/admin` → slot counter + **Bookings** tab to approve/reject
  pending payments, **Checked In** tab for who is inside · `/admin/scan` scans
  the QR at the gate. Check-in runs as a Firestore transaction
  (`verified → checked_in`), so a QR cannot be reused even with two scanners
  going at once. One scan admits the whole booking.
- **Admin login** lives at the unlisted `/portal-4k9x7m`, not linked anywhere.

## Where things live

| What | File |
| --- | --- |
| Every price, bundle and the post-12-Oct flat rate | `src/lib/pricing.ts` |
| Date, time, venue, contact numbers, highlights, slot cap, payment QR switch | `src/lib/event.ts` |
| When bookings open | `src/lib/launch.ts` (+ `isLaunched()` in `firestore.rules`) |
| House rules shown on `/rules` | `src/lib/rules.ts` |
| Public slot counter (doc path, maths) | `src/lib/slots.ts` |
| Festival artwork — dandiya, diya, peacock, kalash, lotus, paisley, ghungroo, rangoli corners, toran, mandala, the garba scene | `src/components/Ornaments.tsx` |
| Terms & Conditions text (signup modal) | `src/lib/termsContent.ts` |
| Colours, gold text/border/button, rangoli background | `src/app/globals.css` |
| Dandiya, diya, toran, mandala artwork (inline SVG) | `src/components/Ornaments.tsx` |

## Pricing — open question

`src/lib/pricing.ts` carries the poster's list, with two readings that still
need confirming (both flagged in the file header):

1. **Kid with Parents ₹999** is wired as *2 adults + 1 kid*. That undercuts
   Couple (₹1,299) — a couple can add a kid and pay ₹300 less. Change the pack
   to `{ adults: 1, kids: 1 }`, or raise its price, if that is not intended.
2. **Students Offer ₹1,299** is wired as *3 students*; a 4th student pays the
   ₹799 single rate.

Everything else follows those numbers automatically: the booking page adds up
the party, applies the best-value bundles first, then charges per head. From
13 Oct the bundles switch off and every head is ₹899.

## 1. Firebase setup

> **This event needs its own Firebase project — never the Deep Fitness app's
> (`deepfitness-82bdd`).** Both live in this repo now, each with its own
> `firebase.json` and `firestore.rules`, and running `firebase deploy --only
> firestore` in the wrong directory would overwrite the app's security rules
> with the event's. The `.firebaserc` here holds a placeholder project id on
> purpose, so the CLI fails loudly until you set the real one. Always check
> `firebase use` before deploying, and run it from inside this folder.

1. Create a project at [console.firebase.google.com](https://console.firebase.google.com).
2. **Build → Authentication → Get started → Sign-in method** → enable **Email/Password**.
3. **Build → Firestore Database → Create database** → production mode, pick a region.
4. **Project settings → General → Your apps → Add app → Web (`</>`)** → register, copy the config.
5. Deploy the rules and indexes in this repo, either:
   - Console: paste [`firestore.rules`](firestore.rules) into **Firestore → Rules** and publish.
     Composite indexes ([`firestore.indexes.json`](firestore.indexes.json)) are otherwise created
     on demand — the browser console error carries a direct "create index" link.
   - Or CLI: `npm i -g firebase-tools`, `firebase login`, `firebase deploy --only firestore`.

## 2. Environment variables

Copy `.env.local.example` to `.env.local` and fill in the web app config from step 4:

```
NEXT_PUBLIC_FIREBASE_API_KEY=
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=
NEXT_PUBLIC_FIREBASE_PROJECT_ID=
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=
NEXT_PUBLIC_FIREBASE_APP_ID=
```

These are safe to expose client-side — a Firebase web app is secured by the
Firestore security rules, not by hiding the config.

## 3. Payment QR

Drop the UPI QR image in at `public/payment-qr.jpeg`, then set `ready: true` in
`PAYMENT_QR` in [`src/lib/event.ts`](src/lib/event.ts). Until then the booking
page shows a "call us for payment details" placeholder instead of a broken
image. Set `UPI_ID` in the same file to print the UPI handle under the QR.

## 4. Make yourself admin

Sign up once through the app, then in **Firestore → Data → profiles → `<your uid>`**
set `isAdmin` to `true` (find the uid under **Authentication → Users**). Admins
get `/admin` and `/admin/scan`, and reach them by logging in at `/portal-4k9x7m`.

## 6. Run

```bash
npm install
npm run dev
```

## Deploy — garba.deepfitness.app

This folder lives inside the `devlofttech-oss/deepfitness-app` repo and deploys as
its **own Vercel project**, exactly the way [`docs/`](../docs) does. The two
projects share the repo and nothing else.

1. Push the folder to `master` (Vercel's production branch for this repo).
2. [vercel.com/new](https://vercel.com/new) → import `devlofttech-oss/deepfitness-app`.
3. **Root Directory: `dandiya-night-2026`** — click *Edit* and select it. This is the
   important step: it scopes the project to this folder so the Flutter app and the
   `docs/` pages are never built or served here.
4. **Framework Preset: Next.js** (auto-detected). Leave the build settings alone.
5. **Environment Variables** → add the same six `NEXT_PUBLIC_FIREBASE_*` values from
   `.env.local`, for Production, Preview and Development.
6. **Deploy.**
7. Project → **Settings → Domains** → add `garba.deepfitness.app`. Vercel shows the
   DNS record to create:
   - If `deepfitness.app` uses Vercel's nameservers, it adds the record itself.
   - Otherwise add a `CNAME` for `garba` → `cname.vercel-dns.com` at your registrar,
     then wait for it to verify.
8. Firebase console → **Authentication → Settings → Authorized domains** → add
   `garba.deepfitness.app` (and the `*.vercel.app` preview domain), or sign-in is
   blocked on the deployed site.
9. Publish [`firestore.rules`](firestore.rules) if you have not since — the public
   slot counter needs the `stats/{doc}` rule.

Every push to `master` that touches this folder redeploys it.

Free tiers (Firebase Spark + Vercel Hobby) comfortably cover 400 guests.
