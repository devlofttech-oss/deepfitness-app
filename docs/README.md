# Google Play Console — public pages

Static pages Google Play requires before Deep Fitness can be published. They have no
dependencies and can be hosted anywhere; these are set up for Vercel (see below).

| File | Purpose | Required by Play? |
|---|---|---|
| `index.html` | Landing page linking to everything else | No, but useful as a canonical home |
| `privacy-policy.html` | Privacy policy | **Yes — mandatory** |
| `account-deletion.html` | Web route to request account + data deletion | **Yes — mandatory for apps with account creation** |
| `terms-of-service.html` | Terms of service | Not by Play, but expected for a real product |
| `support.html` | Support / FAQ page | Play requires a support *email*; a page is optional |
| `style.css` | Shared dark stylesheet matching the app | — |
| `vercel.json` | Static-hosting config: keeps `.html` URLs canonical, adds security headers | — |

---

## 1. Publish on Vercel

The pages are plain static HTML — no build step. `vercel.json` pins `cleanUrls: false`
so `/privacy-policy.html` stays the canonical URL, matching the internal links and
whatever you paste into Play Console.

### Option A — Vercel dashboard (recommended)

1. Push this folder to `master`.
2. [vercel.com/new](https://vercel.com/new) → import `devlofttech-oss/deepfitness-app`.
3. **Root Directory: `docs`** — click *Edit* and select it. This is important: it scopes
   the deployment to the public pages so the rest of the repo is never served.
4. **Framework Preset: Other.** Leave Build Command and Output Directory empty.
5. **Deploy.**

Every push to `master` redeploys automatically.

### Option B — Vercel CLI

```bash
npm i -g vercel
cd docs
vercel --prod
```

Accept the defaults; when asked for the directory, use `./`.

### Your URLs

```
https://<project>.vercel.app/
https://<project>.vercel.app/privacy-policy.html
https://<project>.vercel.app/account-deletion.html
https://<project>.vercel.app/terms-of-service.html
https://<project>.vercel.app/support.html
```

Custom domain: **Project → Settings → Domains**. Keep the filenames so nothing else
needs changing.

> Verify every URL in a **private/incognito window** before submitting. Play rejects
> privacy policy URLs that 404, redirect to a login, or sit behind any auth wall.
> Vercel serves HTTPS automatically, which Play requires.

---

## 2. Fill in the placeholders first

Every placeholder renders as a **red dashed box** on the page, so it is obvious if one is
missed. Search the folder for `class="todo"` to find them all.

- [ ] `[YOUR LEGAL ENTITY NAME]` — the entity that owns the Play developer account. Must match the developer name on the listing.
- [ ] `[REGISTERED BUSINESS ADDRESS]` — Play requires a real contact address for the developer.
- [ ] `[DD MONTH YYYY]` — effective / last-updated dates on the privacy policy and terms.
- [ ] `[MINIMUM AGE]` — 13, 16, or 18. Must agree with the age rating and target audience you declare in Console.
- [ ] `[SUPABASE REGION]` — where the backend actually stores data (check the Supabase dashboard).
- [ ] `[AMOUNT]`, `[COUNTRY / STATE]`, `[CITY, COUNTRY]` — liability cap and governing law in the terms.
- [ ] `[e.g. 2 business days]`, `[e.g. 30 days]`, `[e.g. 12 months]` — response and retention windows you can actually honour.
- [ ] `[1.0.0]` — app version on the support page.

These pages are drafted from what the code and database schema actually do, but they are
templates, not legal advice. Have someone qualified review them before release —
especially the health-data and liability sections.

---

## 3. Where each URL goes in Play Console

| Console location | What to paste |
|---|---|
| **App content → Privacy policy** | privacy-policy.html URL |
| **Store listing → Privacy Policy** | same URL |
| **App content → Data safety → Data deletion** | account-deletion.html URL |
| **Store listing → Support email** | `deepfitnessgym2025@gmail.com` |
| **Store listing → Website** (optional) | index.html URL |

---

## 4. Data safety form — draft answers

Derived from `supabase/schema.sql` and the app's actual network calls. Verify each line
yourself; you are the one attesting to it.

**Top-level questions**

| Question | Answer |
|---|---|
| Does your app collect or share any of the required user data types? | **Yes** |
| Is all user data encrypted in transit? | **Yes** — HTTPS/TLS to Supabase |
| Do you provide a way for users to request data deletion? | **Yes** — account-deletion.html |

**Data types to declare**

| Category | Type | Collected | Shared | Required | Purpose |
|---|---|---|---|---|---|
| Personal info | Name | Yes | No | Yes | App functionality, Account management |
| Personal info | Email address | Yes | No | Yes* | App functionality, Account management |
| Personal info | Phone number | Yes | No | Yes* | App functionality, Account management |
| Personal info | User IDs | Yes | No | Yes | App functionality, Account management |
| Personal info | Other info (gender, age) | Yes | No | Optional | App functionality |
| Health and fitness | Health info (height, weight, body fat) | Yes | No | Optional | App functionality |
| Health and fitness | Fitness info (workouts, sets, reps, weight lifted) | Yes | No | Yes | App functionality |

\* Email *or* phone is required, depending on which the member registers with.

**Do NOT declare** — the app does not collect these: location, contacts, calendar, SMS,
photos/videos, audio, files, financial info, advertising ID, or app-activity analytics.
There is no analytics or ads SDK in `pubspec.yaml`.

**On "sharing":** Supabase is a *processor* acting on your instructions, which Play does
not count as sharing. Answer **No** to shared for every row — but do describe Supabase in
the privacy policy, which section 5 already does.

**Health apps declaration:** if you list the app under Health & Fitness, Play may require
the separate health apps declaration form. Deep Fitness is a fitness *tracker*, not a
medical device — say so, and point to the "not medical advice" clause.

---

## 5. Before you submit — open blockers

These are outside this folder but will block or fail review.

1. **No in-app account deletion.** Play's policy requires apps offering account creation
   to provide deletion **both** in-app *and* via a web URL. This folder covers the URL
   half; there is no delete-account path in the app itself. `profile_screen.dart` has no
   such action. This needs building before release.

2. **The backend is paused.** The Supabase project auto-paused on the free tier, which
   removes its DNS record — nothing can sign in, and a reviewer would hit the same error
   and reject the app for broken functionality. Click **Resume project** in the Supabase
   dashboard (resumable until 20 Aug 2027; data and backups are intact). If the Firebase
   migration lands first, this blocker moves with it.

3. **App access credentials.** The app is entirely behind a login, so Play requires demo
   credentials under **App content → App access**. Provide the member and trainer demo
   accounts — and make sure they actually work against a live backend first.

4. **Support email mismatch.** `app_constants.dart` declares `support@deepfitness.app`,
   but the UI and these pages use `deepfitnessgym2025@gmail.com`. Pick one. The address
   on the store listing must be monitored — Play uses it to contact you.

5. **Content rating questionnaire** and **target audience** must be completed in Console,
   and the age you declare must match `[MINIMUM AGE]` in these pages.
