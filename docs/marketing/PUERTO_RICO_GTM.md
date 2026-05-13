# Puerto Rico — Go-To-Market

> Why PR is the right launch market, what's structurally different here, and the specific tactics that will earn the first 5,000 installs.

---

## 1. Why Puerto Rico is the right launch market

Not just because the founder lives here. PR is structurally better than a US-wide launch for a Day 1 indie iOS app:

| Factor | PR | Mainland US |
|---|---|---|
| **iPhone share** | ~60%+ of smartphone market (one of the highest in any US market) | ~57% nationally, with wide regional variance |
| **Vehicle fleet age** | Older than mainland (≈13+ years avg) — more maintenance needed | ≈12.8 years |
| **Annual touchpoint** | **Marbete** renewal is a universal, calendared, anxiety-inducing event every July. We can hook directly into it. | No equivalent universal event (registration varies by state) |
| **Press density** | Small, accessible — Sin Comillas, Estamos en Línea, El Nuevo Día Negocios, NotiCel, Bloomberg LatAm, several PR-focused tech podcasts | National press is gated, slow, expensive to reach |
| **Bilingual ad cost** | One creative serves the market | English + Spanish creatives needed nationally |
| **Network density** | "Two-degree" island. Word of mouth compounds visibly. | Word of mouth doesn't compound at scale below the millions. |
| **Cultural fit** | Distrust of subscriptions, ads, data harvesters — the brand voice resonates | Same sentiment exists, but is one of many competing narratives |

**Strategic bet:** dominate PR's Utilities category (top 50), use that ranking + Spanish-speaking reviews as proof for diaspora markets (FL, NY, TX) and Latin America at large.

### Research that informs this strategy

- iOS market share in PR is among the highest of any US market.
- Average PR vehicle is older than the mainland average (~13 years) — more maintenance per vehicle.
- The **Marbete Digital** transition (2024–2026) removed the physical sticker but left a reminder gap that CESCO Digital fills poorly. Government-issued software in PR is a low bar to clear — and the official channel itself ([CESCO Digital](https://cescodigital.dtop.pr.gov/)) confirms users are responsible for tracking their own renewals.
- DTOP's own messaging confirms it **does not mail reminders** ([DTOP / Piloto 151](https://piloto151.com/marbete-renewal/)) — every Puerto Rican driver is on their own to remember a $20-per-quarter penalty deadline. That gap is the opening.

---

## 2. Puerto Rico–specific feature surfaces

These are the things that are *real* about driving in PR that the app should reflect — either at launch (via custom service types) or in v1.5 (as first-class features).

### Marbete (annual registration) — and **Marbete Digital**

Two important facts that shape the entire PR strategy:

1. **Marbete is staggered by license-plate digit**, not universal. Each vehicle renews in the month "punched" on its current marbete (loosely tied to the plate's last digit). There is no single nation-wide July 31 deadline. ([Piloto 151 / Relocate PR](https://piloto151.com/marbete-renewal/))
2. **The physical sticker has been replaced by Marbete Digital** as of the 2024–2026 rollout. Renewal is now done in **CESCO Digital** (app + portal), tied to the AutoExpreso tag. ([newsismybusiness.com](https://newsismybusiness.com/puerto-ricos-new-marbete-digital-goes-live-on-dtop-app/), [Piloto 151](https://piloto151.com/marbete-digital/))
3. **DTOP does not mail renewal reminders.** The official CESCO Digital app theoretically sends a notice, but its delivery and reliability are well-documented problems — see below. *This is our wedge.*

#### What CESCO Digital does (and doesn't) do well

The CESCO Digital app is where Puerto Rican drivers now register their digital marbete, schedule inspections, and pay fines. We are not a replacement for it, and shouldn't position as one — that's a fight against a government service. We position as the *layer above it*: **CESCO Digital is where you pay; Checkpoint is where you remember.**

What's publicly documented about CESCO Digital's reminder + reliability story:

- **JustUseApp safety score: 0/100.** Independent rating, based on aggregated user complaints. Ongoing user-reported. ([JustUseApp](https://justuseapp.com/en/app/1389951990/cesco-digital/reviews))
- **App Store reviews** (ongoing) repeatedly cite that it *"constantly shuts down and crashes,"* doesn't recognize its own AutoExpreso integration (which Marbete Digital depends on), and won't let users complete appointment scheduling. ([CESCO Digital — App Store](https://apps.apple.com/us/app/cesco-digital/id1389951990))
- **The DTOP secretary publicly committed to fixing the platform (2024)** — *"DTOP mejorará plataforma del Cesco Digital para pagos y educará más sobre la renovación del marbete electrónico."* ([El Nuevo Día, 2024](https://www.elnuevodia.com/noticias/gobierno/notas/dtop-mejorara-plataforma-del-cesco-digital-para-pagos-y-educara-mas-sobre-la-renovacion-del-marbete-electronico/))
- **Mainstream press has covered system crashes**, including the Marbete Digital launch itself ([wapa.tv, 2023](https://wapa.tv/noticias/locales/se-cae-el-sistema-del-nuevo-marbete-digital/article_7ad95cf4-4903-11ee-87f9-b36ab2aad481.html)) and the inspection scheduling system ([Telemundo PR](https://www.telemundopr.com/noticias/puerto-rico/se-cae-sistema-utilizado-para-inspeccionar-vehiculos/2526379/)).
- Reporting also describes the in-app **notifications function as something DTOP *"was working to have"*** — i.e., aspirational, not a confirmed-reliable channel for renewal reminders.

> **Citation hygiene:** the dated sources above span **2023–2024**. Before any press pitch or interview that leans on this evidence, re-check whether CESCO Digital has shipped a meaningful reliability/reminder improvement in the meantime. The argument is durable only as long as the underlying gap is.

This changes the whole campaign shape:

- **Marbete is a year-round drumbeat**, not a July spike. Every month, ~1/12 of PR drivers are facing a renewal. The campaign runs *continuously* with monthly mini-pushes ("¿Tu marbete vence este mes?"), not one summer event.
- **Inspección de seguridad** remains mandatory annually and is the practical bottleneck (ASES centers, long lines). Inspection-month and marbete-month line up by design. Reminders for both belong on the same card.
- **Tone discipline — don't punch at the government.** It backfires and we sound bitter. Position alongside, not against. The disciplined line is:

> *"Pagas en CESCO Digital. Te acuerdas con Checkpoint."*
> (*"You pay in CESCO Digital. You remember with Checkpoint."*)

- A sharper backup line, only for media interviews or when a journalist asks directly about CESCO Digital's issues: *"El sistema oficial es donde pagas. Nosotros somos el recordatorio que no te llega."*

#### What this means for the product

- **Today (v1.0):** users create a custom service type "Marbete" with a 12-month interval anchored to their renewal month.
- **v1.1 (small, ship in Phase 2):** First-class **Marbete preset**, auto-suggested when the user adds a vehicle with a PR locale. Sub-checklist: *inspección · seguro · pago*. Notifications fire 30 / 7 / 1 day before the user's personal renewal date. Deep link to `cescodigital.dtop.pr.gov`.
- **v1.1 (companion):** **Inspección** as a paired preset that automatically schedules ~30 days before marbete.
- **v1.5:** Integrate ASES inspection station addresses (public dataset) so users can pre-select where they'll go.
- **v1.5:** Optional "Comparte tu calendario de marbete" — a shareable card (à la Slopes' [shareable run cards](https://www.revenuecat.com/blog/growth/slopes-from-indie-side-hustle-to-1m-in-arr-and-an-apple-design-award/)) that turns a renewal reminder into a WhatsApp-forwardable image. This is the highest-leverage word-of-mouth feature we can build for PR.

### Inspección de seguridad

- Annual or biennial safety inspection, paired with marbete.
- Common pain: forgetting to do it before marbete deadline.
- **App handling:** sub-service of marbete preset OR standalone service type. v1.1 should pair them.

### Recalls — actually mailed paper letters in PR

- USPS to PR is slow and unreliable. Many PR drivers learn about recalls months late.
- The app's NHTSA recall integration is *more valuable in PR than in mainland US.* This is a positioning angle: **"Checkpoint te avisa de los recalls antes de que te llegue la carta."**

### Used-car commerce

- Strong PR used-car market (Clasificados Online, Facebook Marketplace, dealerships).
- Service history PDF has higher resale value here because buyers are skeptical of mileage rollback (a real local concern).
- **Marketing angle:** the PDF export is "tu historial — el comprador te lo va a pedir."

### Hurricane season

- Annual June–November hurricane season changes vehicle priorities (battery, wipers, fuel-up timing, AC system).
- **Seasonal reminder content:** ship a "preparación para temporada de huracanes" content card (June 1) in v1.1.

### Talleres independientes

- Most PR drivers use a trusted independent shop, not a dealer.
- DIY rates are high (especially among older male enthusiast segment).
- Competitor weakness: CARFAX-style apps assume dealer service; Checkpoint's custom service types and freeform notes are a feature here, not an afterthought.

---

## 3. The Marbete Drumbeat (centerpiece campaign — always-on, not seasonal)

**Original assumption:** a July 31 spike campaign.
**Revised after research:** marbete is **staggered**. Every month a different cohort renews. The campaign is a **year-round drumbeat with monthly mini-pushes** — perfect for a content-led, low-budget indie launch.

**Concept:** Position Checkpoint as the missing layer between you and CESCO Digital. The government replaced the sticker with an app, but it still doesn't remind you well. *Checkpoint does.* While you're here, it'll also remind you about the oil change.

### Always-on rhythm

| Cadence | Action |
|---|---|
| **Monthly (1st of month)** | Single Instagram Reel / TikTok / WhatsApp story: *"¿Tu marbete vence en [mes]? Te toca a ti."* Pin a comment with the download link. |
| **Monthly (15th)** | Blog post / X thread on a marbete-adjacent topic (inspección, seguro, ASES centers, common rejections) — content marketing that surfaces in PR Google searches. |
| **Continuous** | Replies in PR Facebook groups whenever someone asks *"¿cómo me acuerdo del marbete?"* — answered with a screenshot, not a sales pitch. |

### Two-week launch spike (Phase 2 kickoff)

**Locked: late July.** Two reasons:

1. **DTOP has historically extended deadlines for July and August marbetes** — e.g., [Primera Hora coverage of a 15-day extension for marbetes "vencidos sólo en agosto"](https://www.primerahora.com/noticias/gobierno-politica/notas/dtop-extiende-por-15-dias-la-renovacion-de-los-marbetes-vencidos-en-julio-y-agosto/). Extensions only happen when the system is buckling, which is when the audience is most receptive to "there's a better way."
2. **Cultural muscle memory** — before the digit-staggered system, the universal marbete deadline was July 31. That association still lives in PR drivers' heads and in Google search volume for `marbete`, even though the legal reality has shifted. Riding that residual search demand is a free distribution channel.

January is the credible backup anchor — [DTOP also extended January renewals in 2022](https://aldia.microjuris.com/2021/12/28/dtop-extiende-la-vigencia-de-los-marbetes-y-las-licencias-que-vencen-en-enero/) — and pairs naturally with the yearly cost roundup (Campaign 5). If for any reason a July spike isn't feasible, run it in mid-January.

D-day for the spike anchors on the **last Friday of July**. Run this two-week sprint then:

| Day | Action |
|---|---|
| **D-14** | Press push (Sin Comillas, El Nuevo Día Negocios, Estamos en Línea) — angle: *"Local dev replaces what CESCO doesn't do."* |
| **D-10** | Founder long-form post on personal blog: *"Por qué construí un recordatorio de marbete"* — cross-posted to HN ("Show HN") and Reddit r/PuertoRico. |
| **D-7** | App update ships: Marbete preset, paired Inspección preset, shareable card. |
| **D-3** | Talleres QR cards live (see § 5). |
| **D 0** | Paid Meta boost ($150–200) targeting San Juan / Bayamón / Caguas iPhone users 25-55. |
| **D+7** | Founder check-in social post: numbers, learnings, public download count. |

### App-side hooks (need to ship before Phase 2)

1. **Marbete preset** in service-type picker — already creatable via custom types, but making it a *first-class preset* frames the campaign and lets us deep-link.
2. **Inspección preset** — paired, auto-scheduled 30 days ahead of marbete.
3. **Per-vehicle renewal-month picker** during onboarding, when locale is set to PR. "¿Qué mes vence tu marbete?" → drives the dueDate anchor.
4. **Shareable marbete reminder card** (PNG export) — generated from the upcoming service. Cerulean background, monospace, just "MARBETE · MES X · TE QUEDAN N DÍAS · CHECKPOINT". This is the Slopes-style word-of-mouth hook.
5. **PR-only onboarding card**: *"¿Quieres que te avise del marbete y la inspección? Sí / No gracias."* No location permission requested — locale is enough.

### Off-app assets

- **Spanish tagline:** *"Para que no se te pase el marbete."*
- **English tagline:** *"So your registration never sneaks up on you."*
- **Hero asset:** vertical Lock-Screen mockup with the marbete countdown widget. Cerulean (#0033BE) background, off-white (#F5F0DC) frame, JetBrains Mono. One sentence under it.
- **PR landing page:** `/marbete` route on the marketing site, Spanish-first. Below the fold, the other 11 things Checkpoint does. Goal: convert *"I came for marbete"* into *"I'll keep it for the oil change too."*

---

## 4. Channels & tactics

### Reddit — r/PuertoRico

- ~150k members, active, friendly to local launches if posted right.
- **DO**: ask for feedback before launching ("estoy lanzando una app para mantenimiento de carro, ¿qué le pondrían?"). Post the finished product 2 weeks later.
- **DO**: respond to every comment for the first 72 hours.
- **DON'T**: cross-post a US-market launch. PR readers can spot it instantly.

### Facebook groups (still dominant in PR over Twitter/X)

Target groups, in priority order:
1. *Compra y Venta de Carros Puerto Rico* (very large, very transactional — perfect for PDF export angle)
2. *Mecánica y Tuning Puerto Rico*
3. *Apple Users Puerto Rico*
4. Brand-specific groups (Honda PR, Toyota PR, BMW PR clubs)

**Approach:** Don't post launch announcements. Post *useful answers* — when someone asks "¿cómo llevo el récord de mi mantenimiento?" or "¿cuándo le toca el cambio de aceite?", reply with a screenshot of Checkpoint and a one-line download link. Repeat with discipline. This is a 6-month slow burn that converts at 5× the rate of any paid social.

### WhatsApp

- The dominant messaging channel in PR.
- **Don't try to advertise on WhatsApp.** The play is making it *easy to share Checkpoint* from inside the app. The iOS Share Sheet does this for free — confirm it's tested.
- A separate test: a single Instagram Reel that ends with "compártesela a quien tú sabes que lo necesita" — designed to be forwarded.

### Instagram + TikTok

- Skew younger / Enthusiast demographic.
- Format that works: **30-second screen-recordings + voiceover.** Founder voice, in Spanish, casual. *"Le subo una foto al odómetro y me reconoce el número. Eso es todo. No tengo que escribir nada."*
- Hashtags: `#PuertoRico`, `#CarrosPR`, `#TallerPR`, `#iPhone`, `#Apple`, `#Mantenimiento`. Mid-volume tags beat huge ones for indie launches.

### Local podcasts

There are a handful of PR podcasts worth pitching:
- *Bloomberg Línea Puerto Rico* (business / tech crossover)
- *Estamos en Línea* (tech, accessible)
- *Carros y Motores PR* (if it's still running — check at launch)
- *Negocios Hoy* (radio, has a podcast feed)

**Pitch angle for each:** *"Local developer ships an app, refuses VC and subscription model, here's why."* The PR press loves an independence narrative.

### CESCO / DTOP

- Public-facing transportation authority. Don't expect direct partnership.
- **Realistic ambition:** be the app *AAA*-style commenters recommend in CESCO-line conversations. Get there via the marbete content campaign.

---

## 5. Talleres partnership program

**Concept:** 5–10 independent talleres in San Juan / Bayamón / Caguas display a small printed card with a QR code that downloads Checkpoint. In return, when the user logs a service through the app, "{taller name}" is a pre-suggested location for the *Shop / Notes* field.

### Why this works

- Free for the taller (no integration, no fees).
- Free for Checkpoint (printed QR card ~$6 each at VistaPrint).
- The user gets a small, real benefit ("recordar que lo hice donde Miguel").
- The taller gets a small, real benefit ("mi nombre sale en su teléfono cuando le toca el próximo").
- The relationship creates physical, in-the-real-world distribution that no competitor has.

### Mechanics (v1 — no app changes needed)

- Founder visits 8–10 trusted shops with a stack of printed cards (front: app name + QR + tagline; back: founder's WhatsApp).
- Card sits at register.
- Track: which shops generate installs. Use UTM-coded short URLs per shop.

### Mechanics (v1.5 — small app addition)

- Add a "Saved shops" list to the Settings → Vehicles screen. Pre-populate from the user's history of typed-in shop names.
- Show pre-populated shops as quick-pick chips in the service log entry sheet.
- This is a 1-day feature in the app. It dramatically increases the perceived value of the partnership.

### Initial taller list to approach

Founder's call. Suggested criteria:
- Independent (not a dealer chain).
- Owner has owned the shop 5+ years.
- iPhone-using clientele.
- Founder or someone in founder's network can introduce.

Start with 3, prove it, then expand to 10. Don't try for 20 in Phase 2.

---

## 6. Localization plan

### Phase 0 — Spanish (Mexico) added as second App Store locale

- Apple's "Spanish (Mexico)" is the broadest LATAM locale and is the standard PR uses on iOS.
- Add Spanish translations to:
  - App Store name, subtitle, keywords, description, promotional text
  - App Preview captions
  - Screenshot text overlays (Spanish set)
- App itself: localize **Settings, error messages, the marbete preset name, and onboarding** as a first pass. Full app localization comes in v1.1.

### Translation principles

- Use PR Spanish, not Castilian. Yes, the App Store locale is "Mexico," but the copy can read PR-natural — Mexico Spanish is a superset, not a constraint.
- *Carro*, not *coche*. *Llanta*, not *neumático*. *Marbete*, not *registro*. *Taller*, not *garaje*.
- Confirmed by two native PR Spanish reviewers before any text ships.
- **Do not use machine translation** for the launch copy. Use it as a starting point, but every line gets a human pass.

### Glossary (sample — full list in `APP_STORE_ASSETS.md`)

| English | PR Spanish (preferred) | Mainland MX Spanish (acceptable) |
|---|---|---|
| Oil change | Cambio de aceite | Cambio de aceite |
| Tire rotation | Rotación de gomas | Rotación de neumáticos |
| Brake pads | Pastillas | Pastillas / balatas |
| Spark plugs | Bujías | Bujías |
| Service log | Bitácora de servicio | Bitácora / historial |
| Mileage | Millas (or *odómetro*) | Kilometraje |
| Registration | Marbete | Tarjeta de circulación |
| Workshop | Taller | Taller |

---

## 7. PR-specific success milestones

In addition to the general metrics in `LAUNCH_PLAYBOOK.md` §6:

| Metric | Target by end of Phase 2 (Week 9) |
|---|---|
| PR storefront rank (Utilities) | Top 50 |
| Spanish-language reviews | ≥100 |
| Talleres displaying QR card | ≥6 |
| Marbete service type logged by users | ≥40% of PR users |
| Pieces of PR press coverage | ≥3 |
| WhatsApp "share Checkpoint" events (tracked via Share Sheet UTM) | ≥200 |

---

## 8. What to skip

Decisions made to keep focus.

- **Spanish (Spain) localization** — different vocabulary, low ROI before LATAM is proven.
- **Bus / radio billboards** — too expensive, can't measure.
- **Auto-Expo / Convention Center booth** — too expensive for Phase 2. Revisit Phase 3.
- **Influencer sponsorships above ~$500** — wait for revenue.
- **Localizing the app to French or Portuguese** — out of scope for v1.

---

_Last updated: 2026-05-12_
