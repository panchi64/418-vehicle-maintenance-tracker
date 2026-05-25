# Campaign Ideas

> Ten concrete, fundable campaigns. Each has a goal, an audience, a budget tier, an execution checklist, and a measurable outcome. Don't run more than two simultaneously in the first 90 days.

The two flagged ⭐ are the ones to start with. Everything else is a follow-up or seasonal play.

---

## How each campaign is structured

Every campaign in this doc follows the same shape:

```
NAME
- Audience    : which persona (from LAUNCH_PLAYBOOK §2)
- Goal        : the single thing it must achieve
- Budget tier : Lean / Standard / Aggressive
- When        : phase or trigger
- What it is  : the actual idea, in plain language
- Execution   : step-by-step checklist
- What success looks like : one or two numbers
- Risk        : what could go wrong
```

---

## ⭐ Campaign 1 — "El Marbete Drumbeat"

- **Audience:** Diaspora / Bilingual Driver (PR-localized)
- **Goal:** Make Checkpoint synonymous with marbete reminders in Puerto Rico.
- **Budget tier:** Lean (continuous) → Standard (during launch spike)
- **When:** Always-on, starting Phase 2 week 1, monthly mini-pushes forever.

### What it is

A year-round content drumbeat anchored to the marbete renewal cycle. Because marbete is **staggered by license-plate digit** ([Piloto 151](https://piloto151.com/marbete-renewal/)) and **the government no longer mails reminders** ([Relocate PR](https://relocatepuertorico.com/how-to-obtain-or-renew-your-annual-vehicle-registration-marbete-in-puerto-rico/)), there's a year-round audience of ~1/12 of all PR drivers facing this problem any given month.

The official replacement — CESCO Digital — has documented reliability issues (JustUseApp 0/100 user-aggregated score; repeated system crashes covered by [wapa.tv (2023, Marbete Digital launch)](https://wapa.tv/noticias/locales/se-cae-el-sistema-del-nuevo-marbete-digital/article_7ad95cf4-4903-11ee-87f9-b36ab2aad481.html) and [Telemundo PR (inspection system crash)](https://www.telemundopr.com/noticias/puerto-rico/se-cae-sistema-utilizado-para-inspeccionar-vehiculos/2526379/); DTOP publicly committed to fixing the platform per [El Nuevo Día (2024)](https://www.elnuevodia.com/noticias/gobierno/notas/dtop-mejorara-plataforma-del-cesco-digital-para-pagos-y-educara-mas-sobre-la-renovacion-del-marbete-electronico/)), and its in-app reminder is described in press coverage as aspirational rather than reliably live. Citations span 2023–2024; verify currency before any press pitch. **Positioning discipline: co-existence, not replacement.** CESCO Digital is where you pay; Checkpoint is where you remember. See `PUERTO_RICO_GTM.md` § 2 for the full tone protocol.

### Execution

1. On the 1st of every month, post a 30-second Reel / TikTok / WhatsApp story: *"¿Tu marbete vence en [mes]? Te toca."* Hook in the first 3 seconds — research shows that's when users decide ([Hilomedia](https://hilomedia.com/blog/app-store-video-previews/)).
2. On the 15th, publish a blog post: *Inspección sin contratiempos*, *Por qué falla más inspecciones de seguridad*, *Marbete Digital — qué cambió*, etc. SEO-targeted, Spanish.
3. Reply in PR Facebook groups whenever the topic surfaces. Once per occurrence. Screenshot, not link.
4. Ship the in-app **Marbete preset** and **shareable card** before D-7 of the Phase 2 launch spike (see `PUERTO_RICO_GTM.md` § 3).
5. Track via UTM-coded short URL: `chkp.pr/marbete`.

### What success looks like

- 40% of PR users have a Marbete service scheduled in the app within 6 weeks.
- One marbete-keyword Google search puts Checkpoint's blog on page 1 within 90 days.
- ≥3 organic mentions of Checkpoint in PR Facebook groups per month by month 4.

### Risk

- Could feel preachy if every post is "remember your marbete!" Mitigate by alternating: half are reminders, half are useful trivia (inspection failures, ASES locations, what changes when you sell the car).

---

## ⭐ Campaign 2 — "Day 1 with iOS 26"

- **Audience:** Enthusiast + iOS-press readers
- **Goal:** Be among the first 50 apps featured for iOS 26 / Liquid Glass at public ship.
- **Budget tier:** Lean ($0)
- **When:** Tied to iOS 26 public release date.

### What it is

David Smith's #1 lesson: *"I put myself in a position to be able to capitalize on an opportunity, but the fact that the opportunity ended up taking off was largely out of my hands."* He shipped Widgetsmith on iOS 14 launch day. It hit #1. ([Sub Club / Inc.com](https://www.inc.com/jason-aten/with-over-50-million-downloads-widgetsmith-became-an-overnight-success-12-years-in-making.html))

We do the same for iOS 26. Checkpoint already uses Liquid Glass per the design system (`AESTHETIC.md`). Apple's editorial team actively looks for OS-launch-day apps that exercise new APIs cleanly.

### Execution

1. **Submit a featuring nomination via App Store Connect ≥ 6 weeks before iOS 26 GM**. Per Apple's docs, "give the team a minimum of two weeks notice; up to three months ahead is better." ([Apple Developer — Getting featured](https://developer.apple.com/app-store/getting-featured/))
2. In the nomination, lead with: full Liquid Glass implementation in widgets, Lock Screen, sheets, navigation. List the new iOS 26 APIs we use specifically.
3. Build a 60-second screen-recording of Checkpoint on iOS 26 b6+ — to attach to the nomination *and* to send to MacStories/Sweet Setup.
4. Ship a `v1.x` build to the App Store the day Apple announces the iOS 26 GM ship date — beats Day 1 by a week, so it's available to early upgraders.
5. Have a 280-character post drafted for the moment iOS 26 ships, ready to paste.

### What success looks like

- App appears in the "Apps for iOS 26" or "New & Updated" editorial slate.
- 5,000+ installs in the first 72 hours post-iOS 26 ship.
- ≥1 piece of editorial coverage tied to the OS launch (MacStories' iOS X day-of round-up is the gold standard).

### Risk

- Apple doesn't feature us. *That's the default outcome.* The campaign still works — the build is shipped, the nomination is on file, the press materials exist, and the next OS launch is the next swing.

---

## Campaign 3 — "Talleres Partnership Program"

- **Audience:** Diaspora / Bilingual Driver
- **Goal:** Distribute Checkpoint at the physical point of need.
- **Budget tier:** Standard (~$60 in printing)
- **When:** Phase 2, weeks 2–5.

### What it is

5–10 independent auto shops in San Juan / Bayamón / Caguas display a printed business-card-sized QR. Detailed mechanics in `PUERTO_RICO_GTM.md` § 5.

### Execution

1. Print 1,000 cards via VistaPrint ($60). Cerulean front, QR + tagline; back has the founder's WhatsApp.
2. Founder visits 8–10 trusted shops in person, with a 60-second pitch and an offer ("free, no integration, and your name shows up in the user's app when they log a service").
3. UTM-track each shop with a unique short URL.
4. Monthly check-in via WhatsApp — has the card been seen? Has anyone asked about it?
5. In v1.5, ship the "Saved Shops" feature that pre-fills shop names in the service log entry sheet — the partner shops get listed first.

### What success looks like

- 6+ shops live with cards in Phase 2.
- 100+ Checkpoint installs attributed to shop QRs by week 9.
- 1 shop becomes a public advocate (TV mention / radio mention / social post by the owner).

### Risk

- Shop owners say yes politely, never display the card. Mitigate by visiting in person, not emailing. Bring the card already printed — friction kills.

---

## Campaign 4 — "Show HN: I Built a Car Maintenance App That Doesn't Try to Log Into Anything"

- **Audience:** Enthusiast + indie/tech press
- **Goal:** A single, well-timed HN front-page moment.
- **Budget tier:** Lean ($0)
- **When:** Phase 1, week 2. Tuesday or Wednesday, 11 AM PT / 2 PM ET — the documented sweet spot ([Indie Hackers](https://www.indiehackers.com/post/best-time-to-post-to-hacker-news-b52bece549)).

### What it is

A Show HN post that leads with the *technical* angle (on-device Vision OCR, SwiftData architecture, the "no account" stance) rather than marketing. Hacker News punishes anything that smells like a press release; it rewards engineering candor.

### Execution

1. Draft title: `Show HN: Checkpoint – iPhone vehicle maintenance, no account, no subscription` (length: 76 chars, well under HN's 80-char title limit).
2. Body (under 1,200 chars) leads with the technical: *why on-device OCR, why SwiftData, why no Android, what the data model looks like, what's free vs $9.99*. Mentions revenue model honestly. Link to the app + the website.
3. Post at the documented sweet spot. Don't ask friends to upvote (HN flags brigading). Do ask three friends to *engage in the comments* — questions, observations, sincere takes.
4. The first 2 hours, founder is at the keyboard, replying to every comment within 10 minutes. This is non-negotiable.
5. After 24 hours, screenshot the result and reuse it as social proof on Twitter / Mastodon / the website.

### What success looks like

- Top 30 of HN front page for ≥4 hours.
- 1,000+ visits to the website from HN referrers in 48 hours.
- 200+ App Store visits attributed to the HN post.
- ≥1 follow-up from an indie iOS dev wanting to collaborate / write about / interview the founder.

### Risk

- The post falls off the new tab without traction. Recoverable: try again 4 months later with a different angle (e.g. "Show HN: How I integrated NHTSA recall data with SwiftData").

---

## Campaign 5 — "Yearly Cost Roundup → Shareable Card"

- **Audience:** Casual + Enthusiast
- **Goal:** Trigger word-of-mouth at the moment of highest user emotion.
- **Budget tier:** Lean ($0 — engineering only)
- **When:** Phase 3 (depends on v1.5 feature)

### What it is

Slopes' single biggest growth driver was a shareable run-stats card. ([RevenueCat case study](https://www.revenuecat.com/blog/growth/slopes-from-indie-side-hustle-to-1m-in-arr-and-an-apple-design-award/)) Apply the pattern: when Checkpoint's January 2nd yearly cost roundup ships, generate a PNG/JPG of the user's year that they can share to Instagram Stories / WhatsApp / iMessage.

### Execution

1. Engineering: extend the existing yearly roundup notification (`docs/FEATURES.md` § 8) to also generate a 1080×1920 PNG card with the user's headline stat: *"En 2026, gasté $1,247 en mi Civic."*
2. Include subtle Checkpoint branding (app icon + "Checkpoint" wordmark in the corner). Subtle: no big watermark.
3. Test the export through iOS Share Sheet for the four highest-volume destinations: Messages, WhatsApp, Instagram Stories, Mail.
4. Marketing: on the day the roundup notification fires (January 2nd), drop one social post: *"Today, every Checkpoint user is finding out what their car cost them. Hopefully it's less than mine."* (Founder's actual number disclosed — honesty as marketing.)

### What success looks like

- ≥10% of MAU at the time of the roundup share their card.
- ≥1% of those shares convert a viewer to an install.
- A measurable bump in installs the week of January 2.

### Risk

- Users feel exposed by the number — could backfire if it lands as "Checkpoint is shaming me for spending money." Mitigate by tone: the copy frames it as *informational, not judgmental* (`FEATURES.md` § 8 already commits to this tone).

---

## Campaign 6 — "Recall, Before The Mail"

- **Audience:** Casual + Diaspora
- **Goal:** Press hook + safety positioning.
- **Budget tier:** Lean ($0)
- **When:** Phase 1, week 3 — pegged to a real NHTSA recall event.

### What it is

When a high-profile NHTSA recall lands (Toyota, Honda, Ford, etc.), Checkpoint posts a quick founder note: *"Owners of [model/year] just got a recall. If you have Checkpoint, you already know."* Pair with a screenshot of the in-app recall alert.

Critical PR angle: in Puerto Rico, USPS mail delivery is slow and unreliable — many drivers learn about recalls months after mainland US. Checkpoint surfaces them immediately. That's a press story in itself.

### Execution

1. Set up a Google Alert + a manual weekly check on `nhtsa.gov/recalls` for new high-volume recalls.
2. When a big one lands, draft a 280-char post within 4 hours.
3. Send a tailored 100-word email to Sin Comillas, El Nuevo Día Negocios, NotiCel: *"Local app gets PR drivers notified of recalls before the carta llega."* (Template in `PRESS_KIT.md`.)
4. Add a section to the website's `/recalls` page with the recall, the affected models, and a "Check yours" CTA.

### What success looks like

- ≥1 piece of PR press coverage tied to a real recall event in Phase 2.
- A measurable install bump on the affected models' owner-forum / Reddit subs.

### Risk

- Looking opportunistic. Mitigate by tone (informational, *not* "Look at us!"). Lead with the recall, *not* the app.

---

## Campaign 7 — "Switch from Fuelly / Drivvo / Simply Auto"

- **Audience:** Enthusiast (the disenfranchised power-user of an aging competitor)
- **Goal:** Convert the most committed users in the market to switch.
- **Budget tier:** Lean ($0 — content)
- **When:** Phase 2 onward, ongoing.

### What it is

A three-post content series on the founder's blog:
1. *"Why I left Fuelly after 5 years"* — written from the perspective of someone who actually did. (If the founder didn't, the developer of the v1.0 CSV import did the painful work and has the receipts.)
2. *"Importing 8 years of Drivvo logs into Checkpoint in 4 minutes"* — a how-to with screenshots.
3. *"Simply Auto data loss: what I learned moving my records"* — addresses the #1 anxiety in the category.

Each post links to the in-app CSV import feature.

### Execution

1. Write the three posts (≈800–1,200 words each).
2. Cross-post to Reddit r/cars, r/4runners, r/MotorcycleApps, r/Fuelly.
3. Pin a comment in each Reddit post linking to the in-app import. Don't put the link in the post body — it reads as advertorial.
4. Reply to every comment for 72 hours.
5. After 4 weeks, repurpose as a single landing page: `/switch`.

### What success looks like

- ≥100 attributed installs from the three Reddit posts combined.
- ≥1 piece of PR coverage in an indie iOS press outlet tied to the "switch story."
- 30% of new installs in the relevant weeks use the CSV import feature.

### Risk

- Subreddits hostile to anything that smells like promotion. Mitigate: write in first person, lead with the *frustration*, end with the *tool*. Don't title posts "Why Checkpoint is better."

---

## Campaign 8 — "App Store Search Ads (PR + Diaspora ZIPs)"

- **Audience:** Casual (already-searching intent)
- **Goal:** Cheap, measurable acquisition once organic ranking is established.
- **Budget tier:** Standard ($150–300 / month) → Aggressive ($1,000+)
- **When:** Phase 3 (do NOT run earlier — needs reviews + ranking first).

### What it is

Apple Search Ads, super-targeted. Curtis Herbert spent ~$30–40k total over Slopes' lifetime and credits Search Ads with great ROI *when targeted at the resort-keyword level.* ([Larder interview](https://larder.io/blog/making-it-curtis-herbert/)) The Checkpoint equivalent: keyword-level targeting on `marbete`, `inspeccion puerto rico`, `cambio de aceite`.

### Execution

1. Phase 3, weeks 1–2: set up Apple Search Ads Advanced account.
2. Start with 5 keyword sets, $5/day each: `marbete`, `cambio aceite`, `vehicle maintenance`, `vin lookup`, `car maintenance log`.
3. Geo-target the first three to PR storefront + diaspora ZIP codes (Orlando 32811-32859, Bronx, Hartford, Houston 77001-77099).
4. After 2 weeks, kill any keyword with CPI > $1.50 (in line with the [RevenueCat report](https://www.revenuecat.com/state-of-subscription-apps-2025/) — utility apps in this category should hit sub-$1 CPI in targeted markets).
5. Monthly check: which keywords convert to a paywall view? Which convert to a Pro purchase? Reallocate.

### What success looks like

- Sub-$1.00 CPI on at least 2 keyword sets.
- 5%+ of acquired users hit the 4-vehicle paywall within 30 days.

### Risk

- Burns cash if not monitored. Set a hard $300/month cap. Set a $0.50 max bid per keyword initially — Search Ads' auto-bid is aggressive.

---

## Campaign 9 — "Founder's Note" Long-form

- **Audience:** All three personas, mediated through quality press
- **Goal:** Slow-burn brand building. Compounding asset.
- **Budget tier:** Lean ($0)
- **When:** One post per month, starting Phase 2.

### What it is

A monthly first-person essay on the founder's blog about something specific that happened in Checkpoint's development or business. Curtis Herbert calls this the "Slopes Diaries" model — his series is openly readable and has become the indie iOS community's reference for what to do *and* not do. ([blog.curtisherbert.com](https://blog.curtisherbert.com/))

### Execution

Suggested first 6 essays:

1. *"Why Checkpoint will never be on Android"* — positioning piece. Cross-post to HN, Lobsters.
2. *"Building a marbete reminder after I almost paid the late fee"* — the personal story that anchors the PR positioning.
3. *"What I learned from 30 days of receipt OCR in the wild"* — technical + product post, Mastodon / Bluesky catnip.
4. *"Three vehicles free, $9.99 once, no subscription — and the math behind it"* — the monetization thesis.
5. *"The yearly cost roundup, and the time I learned my car cost more than my rent"* — personal + tying into Campaign 5.
6. *"Why Checkpoint is in Spanish before it's in Portuguese"* — the launch market thesis.

Each essay is 800–1,500 words, written in plain language, with one or two screenshots. End each with the *real* download link.

### What success looks like

- 6 essays live by end of Phase 2.
- ≥1 essay hits HN front page or Lobsters top 5.
- One essay gets quoted in MacStories or Sweet Setup.

### Risk

- Founders default to writing for other founders, not for their actual users. Mitigate: write essay #2 first (the personal marbete story) before any of the more "indie business" topics.

---

## Campaign 10 — "Pain-Point Sticker Drop"

- **Audience:** Casual + Enthusiast + Diaspora — anyone with a car and eyes
- **Goal:** Cheap, tactile awareness in places where the target is already thinking about their vehicle. Generate per-slogan conversion data for future copy decisions.
- **Budget tier:** Lean ($60–$120 for the first 200 stickers)
- **When:** Phase 2 onwards. Refresh the slogan rotation quarterly.

### What it is

A small batch of 2"×2" pain-point stickers, placed on **legal, permission-granted surfaces only**, rotated quarterly, each carrying a UTM-tracked QR. The goal is not volume — it's per-slogan conversion data. After 90 days the highest-converting slogan informs App Store copy, ads, and social cadence.

### ⚠️ Placement rules (read first)

**Do NOT place on:** road signs, traffic infrastructure, bus stops, government buildings, private property without permission, utility poles, or any surface you wouldn't want your name on as a vandal in tomorrow's news. PR Law 22 covers defacement. The first *"local app is sticker-bombing San Juan"* tweet ends the brand permanently — and contradicts everything we say about respecting users and their property.

**DO place on:**

| Surface | Why it works | How to get there |
|---|---|---|
| Talleres (partner shops) | Captive, high-intent waiting-room audience | Already covered by Campaign 3 — bundle 50 stickers per partner |
| Auto parts stores (AutoZone, NAPA, Pep Boys) | Same audience, higher intent | Ask the manager; expect ~50% yes |
| Coffee shops + co-working spaces with iPhone-heavy clientele | Reaches Casual + Enthusiast | Almost all have public sticker/flyer boards |
| University bulletin boards (UPR Río Piedras, Bayamón, Mayagüez) | First-time owner / Gen-Z driver — explicit market gap per [`docs/MARKET_RESEARCH.md`](../MARKET_RESEARCH.md) | Free, walk-in |
| Piloto 151 + other PR co-working spaces | Tech-aware iPhone users; founder's own network | Already in the ecosystem |
| Back cover of a 1-page flyer handed out at partner talleres | Owner-approved, waiting-room captive | Cheap to print, partner shop distributes |
| Founder's own car bumper / laptop / water bottle | Free organic placement, conversation starter | Just do it |
| Stickers handed out at indie iOS / car meetups | Earned distribution — people choose to apply them | Bring a stack to every meetup |

### Slogan candidates (pick 4–6, rotate quarterly)

Each slogan needs its own UTM-coded QR so we can measure which pain point converts highest. Format: cerulean (`#0033BE`) background, off-white (`#F5F0DC`) JetBrains Mono, slogan up top, small QR + `CHECKPOINT` wordmark at bottom. Brutalist, on-brand, no images.

| Spanish | English |
|---|---|
| `¿CUÁNDO FUE EL ÚLTIMO CAMBIO DE ACEITE?` | `WHEN WAS THE LAST OIL CHANGE?` |
| `EL MARBETE VENCE Y NADIE TE AVISA.` | `YOUR REGISTRATION ISN'T GOING TO REMIND YOU.` |
| `RECIBOS EN LA GUANTERA NO SON HISTORIAL.` | `RECEIPTS IN THE GLOVE BOX AREN'T A HISTORY.` |
| `EL RECALL LLEGÓ HACE TRES MESES.` | `THAT RECALL WAS MAILED THREE MONTHS AGO.` |
| `¿LE TOCA O NO LE TOCA?` | `IS IT DUE? OR ISN'T IT?` |
| `TU CARRO NO TE LO VA A DECIR.` | `YOUR CAR ISN'T GOING TO TELL YOU.` |

Production: Sticker-Mule die-cut, 2"×2", ~$0.30/each at 200 qty. Order in batches of 200 — enough to seed all surfaces, not so many they pile up unused.

### Execution

1. Design 6 slogan variants in Figma using the cerulean/off-white/JetBrains Mono system. Each gets its own QR pointing to a unique short URL: `chkp.pr/s1` through `chkp.pr/s6`.
2. Set up the 6 short URLs with UTM parameters (`utm_source=sticker&utm_campaign=painpoint&utm_content=slogan-1`) all redirecting to the App Store / website.
3. Print 200 stickers at Sticker-Mule (~$60).
4. Distribute in batches over Phase 2:
   - 50 to partner talleres (Campaign 3 bundle)
   - 30 to co-working / coffee shops the founder visits
   - 20 to university bulletin boards
   - 10 founder's own use (laptop, car, water bottle, meetup giveaway)
   - 90 held in reserve for opportunistic placement
5. Once a month, log scans-per-slogan in a single spreadsheet.
6. After 90 days, kill the bottom two performers. Reprint the top four for batch 2, plus add two new experimental slogans.

### What success looks like

- ≥200 scans across all stickers in 90 days (1 per sticker is the floor).
- Clear winner among the slogans (top performer ≥2× the median).
- ≥1 of the 6 slogans gets folded into App Store copy or social bios.
- Zero complaints / removal requests from venue owners.

### Risk

- **The sticker ends up somewhere it shouldn't.** Even with placement discipline, someone might peel one off a coffee shop board and slap it on a road sign. Mitigate by: not putting the app name as the *largest* element on the sticker (the slogan is biggest), and keeping the QR small. If a misplacement does get tweeted, respond publicly the same day: *"That's not where we put them. If you see one, peel it off and DM us — we'll send you a real one."* Turns a brand risk into a brand moment.
- **Low scan rate** is the default — most stickers are read, not scanned. The conversion data still has signal if a couple of slogans clearly outperform; the awareness lift is hard to measure but real.

---

## What we are deliberately not doing

Saying *no* with intent is a campaign in itself.

| Campaign idea | Why we're skipping |
|---|---|
| **TikTok ads / influencer sponsorships > $500** | Too expensive for an indie pre-PMF. The David Smith / Widgetsmith viral moment happened organically; engineering it costs more than the return justifies until ≥10k installs. |
| **Product Hunt launch in Phase 1** | Without reviews + press to anchor it, a PH launch ranks ~#5–10 and goes nowhere. Save for Phase 3 when there are anchors. |
| **Referral program** | A referral mechanism on a free utility app encourages spam, not advocacy. Re-evaluate at 10k installs. |
| **App Store giveaway codes for reviewers** | Apple's policy hostile to incentivized reviews. Plus reviewers who got a free copy give weaker reviews. |
| **Email newsletter** | No account model → no email list. Don't fight the architecture to harvest emails for "marketing." The founder's blog RSS is the substitute. |
| **Web app waitlist** | We don't have a web app. Don't promise one. |

---

_Last updated: 2026-05-12_
