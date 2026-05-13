# Launch Playbook

> The strategic spine of Checkpoint's marketing. Read this first.

---

## 1. Positioning Statement

**For** iPhone owners who care about their car but resent the apps that try to track it,
**Checkpoint** is a vehicle maintenance companion
**that** tells you what's next at a glance — without ads, accounts, subscriptions, or data exfiltration —
**because** keeping your car alive shouldn't require a second relationship with a tech company.

### One-sentence pitch (use everywhere)

> **Checkpoint tells you what's due, what you've spent, and what's next — without ads, accounts, or a subscription.**

### One-sentence pitch (Spanish, Puerto Rico voice)

> **Checkpoint te dice qué le toca a tu carro, cuánto has gastado y qué viene — sin anuncios, sin cuentas, sin subscripción.**

### What we are NOT

Saying this clearly internally keeps messaging honest:
- Not a fleet manager. (AUTOsist serves that market.)
- Not an insurance / shopping front-end. (Jerry serves that market.)
- Not a fuel-economy obsessive's tool. (Fuelly serves that market; we add fuel in v1.5 as a *quiet* feature.)
- Not a Carfax replacement. (We don't pretend to know your shop history.)
- Not Android. (And it never will be — owning this is a positioning weapon, not a weakness.)

---

## 2. The Three Audiences

Every piece of marketing should target one of these. If a piece of copy or art doesn't, kill it.

### A. **The Casual Owner** ("doesn't want to think about it")

- 30–55, single car, drives it daily, doesn't know when the last oil change was.
- Has had one expensive surprise (a battery, a brake job, a recall). Wants insurance against the next one.
- Lives on iPhone, uses Widgets, checks the Watch.
- Will not read a settings screen. Will not open the app weekly.
- **What they want from us:** "Tell me what's next. Bug me only when it matters."
- **Hero feature:** Next Up card + Lock Screen widget + once-a-month notifications.
- **Conversion to Pro:** unlikely. They're the freemium top of funnel. Worth it because they evangelize ("descárgala, está limpia").

### B. **The Enthusiast** ("knows their car")

- 25–45, often 2–4 vehicles (daily + project car + spouse's car + motorcycle).
- DIYs oil changes, tracks fluids, reads forums, has opinions about 0W-20.
- Hates apps that pretend dealer service is the only kind that counts.
- **What they want from us:** Custom service types, multi-vehicle, freeform notes, PDF export for resale, recall alerts that fire.
- **Hero feature:** Multi-vehicle + Custom service types + Service history PDF + Watch quick-log.
- **Conversion to Pro:** **High.** They hit the 3-vehicle gate fast. They want themes. They are the revenue base.

### C. **The Diaspora / Bilingual Driver** (Puerto Rico–specific, exportable to FL, NY, TX)

- Drives in both English and Spanish contexts. Receives manuals in English, talks to their mechanic in Spanish.
- Owns a car older than the US fleet average (PR fleet skews older — average vehicle in PR ~13+ years). More maintenance, more recalls, more receipts in glove compartment.
- Pays for *marbete* (annual registration sticker) by mid-summer. Knows about *inspección*, ASES, CESCO. Has a familial relationship with a specific *taller*.
- **What they want from us:** A maintenance app that doesn't feel like a translated US product. Reminders that include marbete. Receipt scanning that works on the *taller's* hand-written invoice. Cost-per-mile in *millas*.
- **Hero feature:** Marbete reminder (custom service type with annual interval, July 31st anchor — see `PUERTO_RICO_GTM.md`). Bilingual UI. Offline-first.
- **Conversion to Pro:** Moderate. They will tip more than they Pro-purchase if the app earns it.

---

## 3. Messaging Hierarchy

Every channel uses the same 4-layer hierarchy. Pick the layer that fits the surface area you have.

| Layer | Length | Where it appears |
|---|---|---|
| **1. Tagline** | ≤8 words | App icon caption, OG image, Twitter bio, swag |
| **2. Pitch** | 1 sentence | App Store subtitle (30 char), social bios, press one-liner |
| **3. Promise stack** | 3 bullets | App Store screenshot captions, website hero, press kit fact sheet |
| **4. Story** | 1 paragraph | App Store description first paragraph, founder bio, press release lede |

### Layer 1 — Tagline candidates (pick one, use everywhere)

| Tagline | Voice | Recommended? |
|---|---|---|
| **Know what's next.** | Confident, brand-aligned | ✅ Primary — short, ownable, works in EN/ES ("Sabe qué le toca.") |
| Your car, on the dashboard. | Visual, Apple-native | Secondary, good for widget marketing |
| Maintenance without the noise. | Anti-subscription | Use in press, not headlines |
| Para tu carro, sin enredos. | Spanish-PR voice | ✅ Spanish primary |

### Layer 2 — Pitch (final, locked)

> Checkpoint tells you what's due, what you've spent, and what's next — without ads, accounts, or a subscription.

### Layer 3 — Promise stack (final, locked)

1. **Know what's next.** A dashboard that puts the most urgent service in front of you the second you open the app. No digging.
2. **Stay where you are.** Widgets, Watch, Siri, CarPlay, notifications — the app comes to you. Open it only when you choose to.
3. **Own your data.** No account. No tracking. Free iCloud sync. Export to PDF anytime. Works fully offline.

### Layer 4 — Story (40-second elevator)

> Checkpoint is a vehicle maintenance tracker built for people who'd rather be driving than logging. Open it, and the most urgent thing — an oil change at 47,500, an overdue brake inspection, a recall on your model — is the first thing on screen. Snap a photo of your odometer or receipt and it fills in the rest. Widgets and the Apple Watch surface what's next without you opening anything. No account, no ads, no subscription. Your data lives on your iPhone and syncs through your own iCloud. Free for three vehicles. $9.99 once to unlock the rest.

---

## 4. Brand Voice & Tone

Already established in the website's `AESTHETIC.md` (brutalist-tech-modernist) and the app's notification tone doc. Marketing inherits the same voice with these additions:

| Do | Don't |
|---|---|
| Direct. Short sentences. | Marketing superlatives ("game-changing," "revolutionary"). |
| Specific verbs ("scan," "log," "snap"). | Hedged verbs ("helps you," "lets you"). |
| Use the word *taller*, *marbete*, *CESCO* in PR-market copy. | Translate them. PR-market readers know these words; using them signals you're not a translated US product. |
| Speak to a person who already owns the car. | Speak to a fictional "you should be tracking maintenance" persona. |
| Honest pricing — show ~~$14.99~~ $9.99 crossed out. | Soft-launch then hike. |
| Mention what we DON'T do (no ads, no account). | Imply we are doing things we're not (e.g. "AI-powered" — we use Vision OCR, not LLMs in v1). |

**Banned words in marketing copy:** ecosystem, seamless, unleash, revolutionize, supercharge, gamify, AI-driven (until v1.5 AI OCR ships, then *only* on that feature).

---

## 5. The 90-Day Plan

Three phases. Each has a single primary goal. If a tactic doesn't serve the phase goal, defer it.

### The two non-negotiables (validated by indie launch history)

Two things drive nearly every successful indie iOS launch from the last decade:

1. **Ship on the day of a major Apple platform release** — David Smith's Widgetsmith hit #1 on the App Store after a TikTok creator demoed it the week iOS 14 shipped. He didn't engineer the virality; he engineered *being ready to capitalize when it happened*. (["Lessons Learned From 50 Million Downloads — David Smith"](https://subclub.com/episode/lessons-learned-from-50-million-downloads-david-smith-widgetsmith)) → **For Checkpoint: aim to ship the v1.0 release the same week iOS 26 ships publicly.** Liquid Glass adoption is the wedge. Even if no one goes viral, App Store editorial actively features apps that ship for the new OS day 1.
2. **Build sharing INTO the product** — Slopes' single biggest growth driver was a shareable run-stats card that users posted to Instagram and group chats. It outperformed his $5,000 Instagram ad test. ([RevenueCat case study](https://www.revenuecat.com/blog/growth/slopes-from-indie-side-hustle-to-1m-in-arr-and-an-apple-design-award/)) → **For Checkpoint: the yearly cost roundup, the PDF service history, and the marbete reminder must all generate a shareable PNG/card.** This is a v1.1 ship target, not a "nice to have."

### Phase 0 — Pre-Launch (T-6 weeks to T-0)

**Primary goal:** Be ready to ship. No public marketing.

| Track | Tasks |
|---|---|
| App Store | Finalize ASO copy & keywords (`APP_STORE_ASSETS.md`), produce 10 screenshots, record App Preview, write review notes, set up IAPs |
| Press kit | Build `PRESS_KIT.md` assets: logo lockups, founder photo, app icon, 6.9" screenshots, 30-sec App Preview, fact sheet, bios EN+ES |
| Website | Confirm `checkpoint.franciscocasiano.com` deploys cleanly, add `/press` route (already exists), add `/es` Spanish landing |
| TestFlight | Recruit 20–40 external testers from PR (target: 60% Casual, 30% Enthusiast, 10% mechanics) via Reddit r/PuertoRico, Facebook PR auto groups, personal network |
| Legal | Privacy policy live; PrivacyInfo.xcprivacy in build |
| Analytics baseline | PostHog dashboards for: install → first vehicle, first vehicle → first service log, 7-day retention, paywall view → purchase |

**Exit criteria:** App approved on TestFlight. Press kit downloadable from website. Privacy policy live. 30+ TestFlight users have logged ≥1 service.

### Phase 1 — Soft Launch (Weeks 1–3 post-approval)

**Primary goal:** Earn the first 1,000 quality installs from people who'll tell others. Volume is *not* the goal.

| Tactic | Channel | Notes |
|---|---|---|
| **Founder thread** | Twitter / X, Mastodon, Threads, LinkedIn | First-person story: why I built this, what's free, what's paid, no marketing speak. Pin to profile. |
| **Reddit launches (4)** | r/iOSProgramming, r/iphone, r/cars, r/PuertoRico | One thread per sub, spaced 3 days apart. Lead with screenshots, not link. Reply to every comment for 48h. |
| **Show HN** | news.ycombinator.com | Tuesday or Wednesday, 8–10 AM ET. Title: "Show HN: Checkpoint – iPhone vehicle maintenance tracker, no account, no subscription". |
| **Indie iOS press** | The Sweet Setup, Indie Apps Catalog, App Wishlist, AppAdvice | Use template in `PRESS_KIT.md`. Offer first-look exclusive to The Sweet Setup *or* MacStories — not both. |
| **Puerto Rico tech press** | Sin Comillas, Estamos en Línea, El Nuevo Día Tecnología | Bilingual outreach. Hook: "Local developer ships maintenance app, free, no data harvesting." |
| **MacStories pitch** | personal note to Federico Viticci | Lead with Apple-ecosystem depth (Watch + CarPlay + Widgets + Siri + Live Activities in v1.5). Federico cares about ecosystem natives. |

**Anti-tactics during Phase 1:** No paid ads. No Product Hunt yet (save it for Phase 2 when there are reviews to anchor on). No "follow for follow." No fake reviews.

**Exit criteria:** 1,000 installs. 50+ App Store reviews. 4.5+ avg rating. ≥1 piece of unsolicited press coverage. Paywall view → purchase rate ≥3%.

### Phase 2 — Puerto Rico Push (Weeks 4–9)

**Primary goal:** Make Checkpoint the default answer to *"¿qué app uso para el mantenimiento del carro?"* in Puerto Rico.

Detailed in [`PUERTO_RICO_GTM.md`](./PUERTO_RICO_GTM.md). Highlights:

- **Marbete countdown campaign** (the centerpiece). Begins June 1, peaks July 31.
- **Talleres partnership program** — 5–10 independent shops display a QR card; in return, their name shows up in Checkpoint's "log this at..." quick-pick list (a future v1.5 feature, soft-promised now).
- **Local press exclusives** — Sin Comillas long-form interview, El Nuevo Día Sunday tech column.
- **Puerto Rico Reddit + Facebook native posts** — recurring monthly check-ins, not one-and-done.
- **CarPlay demo at Plaza Las Américas Apple Store** — if a relationship can be cultivated (low probability, high payoff).

**Exit criteria:** 5,000 PR installs OR top 50 in Utilities (PR storefront). 100+ Spanish-language reviews. 3 pieces of PR press coverage.

### Phase 3 — Scale & Iterate (Weeks 10–13 and beyond)

**Primary goal:** Use the PR base as proof, scale to the broader US + diaspora.

- **Product Hunt launch** (now we have reviews + press to anchor).
- **Diaspora geo-targeting**: paid Twitter/Meta ads ($300–$1,000) targeted at PR-affinity audiences in Orlando, NYC, Houston. Spanish creative.
- **Content marketing**: One long-form blog post per month on the founder's site — *"How I built a free iPhone-only app and refused VC,"* *"The marbete reminder feature I shipped after my own ticket,"* etc. Cross-post to Hacker News, Lobsters.
- **v1.5 feature drops as marketing events**: Fuel tracking, EV support, Live Activities. Each ships with its own one-pager, one social thread, one press follow-up.

**Exit criteria for Phase 3:** Whatever the founder defines as "I can keep doing this." Typically: enough recurring revenue to fund ~50% of a part-time contractor, or a clear product-market-fit signal (organic install rate doubling every 4–6 weeks without effort).

---

## 6. Success Metrics

What we measure, on what cadence, with what threshold.

| Metric | Cadence | Floor | Target | What it tells us |
|---|---|---|---|---|
| Daily installs | Daily | 5 | 50 | Are we visible at all? |
| App Store rating | Weekly | 4.3 | 4.7 | Does the product survive the first launch? |
| Reviews count | Weekly | — | 200 in 90d | Trust signal for new visitors |
| Activation (install → 1st vehicle) | Weekly cohort | 60% | 80% | Is onboarding working? |
| 7-day retention | Weekly cohort | 30% | 50% | Is the *Widget-coming-back* loop working? |
| Paywall view → purchase | Monthly | 2% | 5% | Is the 3-vehicle gate priced right? |
| Press placements | Monthly | 1 | 3 | Are we earning outside attention? |
| PR storefront rank (Utilities) | Weekly | top 200 | top 50 | Are we winning the home market? |
| Tip jar conversion | Monthly | 0.3% | 1% | Do users love it enough to pay anyway? |

**Anti-metric** — what we explicitly do NOT optimize for:

- Daily active users (DAU). The product's job is to *not* require daily use. A high DAU here would be a failure of the "the app comes to you" thesis.
- Push notification open rates. We send rare notifications by design. Optimizing this metric corrupts that.
- Time in app. Same reason. The shorter the session, the better the product.

---

## 7. Budget Tiers

What can be done at three levels of investment. All three assume the founder's own time is free.

### Lean ($0 out of pocket)

- Everything in Phase 0 & Phase 1.
- Press outreach via email (free).
- Reddit, HN, Mastodon (free).
- One marbete-launch poster printed at Office Depot ($30) — let's call it lean-with-cents.
- PostHog self-hosted (already running).

### Standard ($500 over 90 days)

- Lean, plus:
- 5 printed business-card-sized QR codes for *talleres* (~$60 with VistaPrint).
- Domain renewal + email forwarder (~$30).
- 1 sponsored Reddit post in r/PuertoRico if Reddit allows it (~$150).
- A small Meta ad set targeted at PR drivers (~$200) — *only* runs week 4–7 to support marbete campaign.
- Apple Developer Program renewal ($99 — table stakes, not really marketing).

### Aggressive ($2,500–$5,000 over 90 days)

- Standard, plus:
- A short-form bilingual video ad produced by a local PR creator (~$800–$1,500).
- TikTok / Reels boosted to PR ZIP codes (~$1,000).
- Sponsoring a single segment on a Puerto Rico car-themed podcast (~$300–$500).
- Reserve $500 for an opportunistic press/giveaway moment (a *taller* partnership launch, an Apple Store demo).

**Recommendation: Standard.** Lean leaves money on the table once the product has reviews; Aggressive is wasted before product-market fit is proven.

---

## 8. Decision log

Things we've decided so we stop re-litigating.

| Decision | Made | Why |
|---|---|---|
| Launch English first, then Spanish-Mexico | 2026-05 | English unlocks press; Spanish-Mexico localization covers PR (and Mexico) within 2 weeks of EN launch. See ASO doc. |
| Tagline = "Know what's next." | 2026-05 | Short, ownable, translates cleanly. |
| Free tier = 3 vehicles | (carried from MONETIZATION.md) | Covers majority, sets a real upgrade trigger. |
| No Android port | Permanent | Apple-ecosystem-depth is the *positioning*. Android dilutes it. |
| No referral / viral mechanic at launch | 2026-05 | Premature for a single-developer indie. Revisit at 10k installs. |
| App name locked: `Checkpoint: Car Maintenance` (27 chars) | 2026-05 | "Car Maintenance" matches what users actually type in search; "tracker" alternative competes with fitness apps in semantic search. |
| App Store listing is **general-audience**, not PR-coded | 2026-05 | The App Store listing is read once by strangers in any market. PR-specific copy (`marbete`, *taller*, *inspección*) helps the 1% from PR and confuses everyone else. PR push happens in PR-channel marketing, not the listing. |
| Spanish subtitle = `Mantenimiento sin anuncios.` | 2026-05 | Full Spanish reads on-brand; Spanglish *"Sin ads"* reads cringe in PR even though Spanglish is otherwise welcome. |
| First press exclusive: El Nuevo Día Negocios | 2026-05 | Local-dev story is the strongest single angle for the founder-in-PR positioning, and PR press is more responsive to a warm pitch than US iOS press. US-iOS-press exclusive (MacStories vs The Sweet Setup) is a separate, *non-competing* decision still to be made. |
| Phase 2 launch spike anchored to **late July** | 2026-05 | DTOP press history shows July/August marbete extension events (system stress = receptive audience); pre-staggered "July 31" muscle memory still drives search volume. January is credible backup. See `PUERTO_RICO_GTM.md` § 3. |
| Spanish review gate = informal pass by two PR native speakers from founder's network | 2026-05 | The bar is "does this sound natural?" not "professional copy-editor." Close friends / coworkers read aloud; flag anything stilted. Avoids paid-translator timeline. |

---

## 9. Risks & how we'll handle them

| Risk | Likelihood | Mitigation |
|---|---|---|
| **App Store rejection** for unclear IAPs / privacy manifest | Medium | Review notes scripted (`APP_STORE_ASSETS.md`); PrivacyInfo.xcprivacy shipped before submission. |
| **Bad early reviews from data-loss anxiety** | Medium | iCloud sync framed front-and-center; PDF export shown in screenshot 7. Anxiety is the #1 user pain in this category. |
| **Localization backlash** ("you said it speaks Spanish, but it's broken Spanish") | High if rushed | First Spanish release must be reviewed by ≥2 native PR Spanish speakers before submission. No machine translation. |
| **Competitor (CARFAX) free-tier expansion** | Low–Medium | We don't compete on shop-imported history. We compete on dignity (no ads, no tracking) and Apple depth. |
| **Press silence** in Phase 1 | High | Realistic. PR press needs warm intro; US press needs an angle. Backup plan: founder-written long-form post seeded on HN, expecting one of three pitches to land. |

---

_Last updated: 2026-05-12_
