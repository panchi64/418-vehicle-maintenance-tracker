# App Store Assets

> Locked ASO copy (EN + Spanish), keyword strategy, 10 screenshot mockups with full layout specs, and a 30-second App Preview video script. This is the most leveraged surface area Checkpoint has — change carefully.

---

## 0. What the research says (and why this doc looks the way it does)

Three findings from 2025 ASO data determine the structure below:

1. **≈90% of users don't scroll past screenshot #3.** Apple's search results show only the first 3 screenshots, full-width, before a tap. (["Screenshots for App Store and Google Play in 2025" — ASOMobile](https://asomobile.net/en/blog/screenshots-for-app-store-and-google-play-in-2025-a-complete-guide/))
2. **Benefit-focused hero shots convert ~45% better** than UI-only screenshots. ([Fanana ASO study](https://fanana.io/articles/app-store-screenshot-optimization.html))
3. **Optimized App Preview videos lift installs 20–30%.** Users decide in the first 3–5 seconds. Autoplay is muted, so captions are mandatory. ([SplitMetrics / Storemaven via Hilomedia](https://hilomedia.com/blog/app-store-video-previews/))

So: screenshots #1–#3 carry a problem→solution→outcome arc. Screenshot #1 leads with the *benefit* (not the UI). The App Preview is two clips, not one — the first 5 seconds answer "what does this app do."

---

## 1. App Store Connect — final copy (English)

### App Name (30 char)

**Locked:** `Checkpoint: Car Maintenance` *(27 chars)*

⚠️ Alternative considered and rejected: *"Checkpoint - Vehicle Tracker"* — "tracker" is generic and competes against fitness apps in semantic search. "Car Maintenance" is what users actually type. (See keywords analysis below.)

### Subtitle (30 char)

**Locked:** `Service & Mileage, no ads.` *(26 chars)*

The subtitle is the second-highest-weight ASO field after the name. *"No ads"* is the single most-cited preference in competitor reviews — surfacing it here is high-signal trust.

### Promotional Text (170 char, editable without resubmission — use for announcements)

```
Track your car's services, costs, and mileage. Smart reminders, widgets, Apple Watch, Siri. No ads, no account, no subscription. Free for up to 3 vehicles.
```

### Keywords (100 char, comma-separated, no spaces)

```
oil change,mileage,odometer,service log,vin,recall,maintenance,vehicle,repair,fuel,gas log,tires
```

*(98 chars)*

Rationale:
- **Do not** repeat words in the App Name. Apple already indexes "Checkpoint" and "Car Maintenance" from the name + subtitle.
- Mix specific transactional terms (`oil change`, `vin`, `recall`) with broad ones (`maintenance`, `vehicle`, `repair`).
- Singular forms only — Apple matches plurals automatically.
- `gas log` and `fuel` cover the v1.5 fuel tracking module without overcommitting now.
- Locale-specific terms (`marbete`, regional inspection slang) live in the Phase-2 Puerto Rico marketing copy, **not** the global App Store fields. The App Store presence is general-audience by design; localized push happens outside the listing.

### Description (4000 char max — final)

```
Know what's next.

Checkpoint tells you what's due, what you've spent, and what's next — at a glance. No ads. No account. No subscription. Just a clean iPhone-native tool for keeping your car alive.

WHAT'S NEXT — ALWAYS VISIBLE
The dashboard shows the single most urgent service every time you open the app. Brake pads at 47,500. Oil change in 12 days. A new recall on your model. No digging, no hunting.

EVERY APPLE SURFACE
• Home Screen and Lock Screen widgets
• Apple Watch app with complications
• Siri: "What's due on my car?"
• CarPlay dashboard widget
• Interactive widgets to mark a service complete in one tap
• Live Activities for overdue services (coming soon)

ZERO-FRICTION DATA ENTRY
• Snap a photo of your odometer — Checkpoint reads it
• Scan your VIN — make, model, year, engine all auto-fill
• Snap a service receipt — text extracts to a tappable log
• Built on Apple's Vision framework. All processing on-device.

SMART SCHEDULING
• Dual-axis reminders by date AND mileage, whichever comes first
• Mileage estimation that learns your driving rhythm
• Service clustering — bundle nearby items into one shop visit
• Seasonal reminders based on your climate
• NHTSA recall alerts surfaced before the mail catches up

YOUR DATA. YOUR DEVICE.
• No account required
• Free iCloud sync across your iPhone, iPad, and Apple Watch
• Full offline operation — the cloud is a bonus, not a requirement
• Export a complete PDF service history any time
• Import from Fuelly, Drivvo, Simply Auto

FAIR PRICING
Free forever for up to 3 vehicles, with every feature unlocked. No ads, no banners, no upsell modals on launch. One-time $9.99 to unlock unlimited vehicles and themes — no subscription required.

Built by a single developer who got tired of every other app trying to log into something.
```

### What's New (for future updates)

Not required for v1.0. Future format — three lines max, lead with the user benefit:

```
- Live Activities now show overdue services on your Lock Screen.
- Marbete reminders for Puerto Rico drivers.
- Fixes to receipt OCR on dim-light photos.
```

---

## 2. App Store Connect — copy (Spanish, Mexico locale — serves PR + LATAM)

### App Name (30 char)

**Locked:** `Checkpoint: Mantenimiento` *(25 chars)*

### Subtitle (30 char)

**Locked:** `Mantenimiento sin anuncios.` *(27 chars)*

Rejected alternatives: `Servicios y millas, sin anuncios.` (33 — over), `Servicios y millas. Sin ads.` (28 — *"Sin ads"* code-switches into a register that reads cringe in PR Spanish, even though Spanglish is otherwise welcome). The full Spanish word *anuncios* is on-brand and unambiguous.

### Promotional Text (170 char)

```
Lleva el control del mantenimiento, los costos y las millas de tu carro. Recordatorios, widgets, Apple Watch y Siri. Sin anuncios, sin cuenta, sin subscripción.
```

### Keywords (100 char)

```
mantenimiento,carro,aceite,millas,kilometraje,odometro,vin,recall,taller,bujias,llantas,gasolina
```

*(96 chars)* — covers both PR and broader LATAM ASO. `carro` (not `auto`) wins in PR + Caribbean + Mexico; `kilometraje` and `millas` both included so we index for the Mexican mainland search habit AND the PR `millas` habit. PR-specific terms (`marbete`, `goma`) are deliberately *not* here — they're reserved for off–App-Store marketing copy. See `PUERTO_RICO_GTM.md` for the local push.

### Description (Spanish, PR-natural — first 300 chars matter most, that's what shows before "más")

```
Sabe qué le toca.

Checkpoint te dice qué le toca a tu carro, cuánto has gastado y qué viene — todo de un vistazo. Sin anuncios. Sin cuenta. Sin subscripción. Una herramienta limpia, hecha en iPhone, para mantener tu carro al día.

LO PRÓXIMO, SIEMPRE A LA VISTA
La pantalla principal te muestra el servicio más urgente cada vez que abres la app. Pastillas a las 47,500 millas. Cambio de aceite en 12 días. Un recall nuevo de tu modelo. Sin buscar, sin escarbar.

TODO EL ECOSISTEMA APPLE
• Widgets en la pantalla de inicio y de bloqueo
• App de Apple Watch con complicaciones
• Siri: "¿Qué le toca a mi carro?"
• Widget de CarPlay
• Widgets interactivos: marca un servicio como hecho con un toque
• Live Activities para servicios vencidos (próximamente)

ENTRADA DE DATOS SIN FRICCIÓN
• Foto del odómetro — Checkpoint lee el número
• Escanea el VIN — marca, modelo, año y motor se llenan solos
• Foto del recibo del taller — el texto se extrae a tu bitácora
• Todo procesado en el iPhone, con Vision framework de Apple.

PROGRAMACIÓN INTELIGENTE
• Recordatorios por fecha Y por millaje — lo que llegue primero
• Estimación de millas que aprende cómo manejas
• Agrupa servicios cercanos en una sola visita al taller
• Recordatorios de temporada según el clima
• Avisos de recall del NHTSA antes de que te llegue la carta

TUS DATOS. TU DISPOSITIVO.
• Sin cuenta
• Sincronización gratis vía iCloud entre tu iPhone, iPad y Apple Watch
• Funciona sin internet — la nube es un extra, no un requisito
• Exporta tu historial completo en PDF cuando quieras
• Importa desde Fuelly, Drivvo, Simply Auto

PRECIO HONESTO
Gratis para siempre hasta 3 carros, con todas las funciones. Sin anuncios, sin banners, sin ventanitas pidiendo que pagues. $9.99 una sola vez para carros ilimitados y temas — sin subscripción.

Hecho por un desarrollador que se cansó de que cada app le pidiera registrarse.
```

**Localization review:** before submission, two native PR Spanish speakers (close friends / coworkers — informal review is fine, the bar is "does this sound natural?" not "professional copy-editor") read the description aloud and flag anything stilted. No machine-translated lines ship as-is.

**General-audience discipline:** this description deliberately contains *no* Puerto Rico–specific copy. PR marketing — marbete reminders, inspección, *taller* references — lives in the Phase-2 push (`PUERTO_RICO_GTM.md`) and the website's PR-localized landing page, not the App Store listing. Reason: the App Store description is read once by a stranger in any market; PR-coded language helps the 1% of readers from PR and confuses everyone else.

---

## 3. Keyword strategy — why these terms, not those terms

Built from competitor name overlap and keyword volume intuition (no paid keyword tool yet). Keywords are the *only ASO field that compounds over time* — get it wrong and re-ranking takes months.

| Keyword | Volume (intuition) | Competition | Why we use it |
|---|---|---|---|
| `oil change` | High | High | Most-searched maintenance term in English |
| `mileage` | High | Medium | Most-searched non-service term — odometer-tracking searches land here |
| `odometer` | Medium | Low | Specific intent; we have the OCR feature to back it |
| `service log` | Medium | Low | "Log" intent users are *already looking for our product* |
| `vin` | Medium | Medium | Differentiator — most competitors don't decode VIN well |
| `recall` | Medium | Low | Safety-critical, low competitor coverage |
| `maintenance` | High | High | Generic — present in name, here for double-indexing |
| `vehicle` | High | High | Same — name has "car," covers the "vehicle" searcher |
| `repair` | Medium | High | Captures the higher-intent fixers |
| `fuel` / `gas log` | Medium | Medium | Forward-positioning for v1.5 fuel module |
| `marbete` | Low (PR-only) | None | Own the term in PR storefront |

**Excluded deliberately:**
- `auto` — Apple uses this for car *brand* search, low relevance for utility maintenance.
- `carfax`, `fuelly`, brand names — risk policy enforcement.
- `dashboard`, `gauge` — semantic collision with finance apps.
- `tracker` — already covered in the subtitle's earlier draft; too generic in keywords field.

---

## 4. Screenshot Mockups — 10 frames, full spec

### Design system (applies to all 10 frames)

| Element | Value |
|---|---|
| **Canvas** | 1320 × 2868 px (6.9" — iPhone 17 Pro Max). All other sizes auto-derive. |
| **Background** | Cerulean Blue `#0033BE` (matches website aesthetic) |
| **Frame inset** | 80 px off-white `#F5F0DC` border around the device mockup (echoes the website's 35px frame, scaled for App Store render size) |
| **Device mockup** | iPhone 17 Pro Max, Titanium Natural color, dark mode |
| **Caption font** | JetBrains Mono Bold, all-uppercase for labels, sentence case for benefit lines |
| **Caption color** | Off-white `#F5F0DC` |
| **Caption position** | TOP 18% of canvas. Two lines max: one bold benefit (52pt), one supporting line (32pt). |
| **Status bar** | 9:41, full bars, full battery — Apple convention |
| **No emoji, no shadows, no rounded screenshot frames** | Matches brutalist aesthetic |

### The 10 frames

> Numbered 1–10. Apple shows frames 1–3 in search; frames 4–10 appear after a product-page tap. The arc: **Hook → Proof → Trust**.

---

### Frame 1 — HERO / What's next

**Story role:** Problem→Solution in a single image. The pitch.

**Caption (top, bold):** `KNOW WHAT'S NEXT.`
**Caption (subline):** `The most urgent service — the first thing you see.`

**Device content:** Home tab. Dominant element: the **Next Up card** rendering an overdue oil change.
- Vehicle header: `2019 HONDA CIVIC · 51,247 MI`
- Next Up card title: `OIL CHANGE`
- Status pill: `OVERDUE · 247 MI`
- Cost-since chip: `$0 THIS MONTH`
- Below: faint, blurred outlines of the "Recent Activity" cards — they exist but the eye locks on the Next Up.

**Why this works:** Hits both the benefit-first rule (caption is a benefit, not a feature) and the "real data, not placeholder" rule. The 247-mile-overdue figure is uncomfortably specific — readers project themselves onto it.

---

### Frame 2 — Receipt OCR

**Story role:** Solution to the #1 user friction (manual data entry).

**Caption:** `SNAP IT. DONE.`
**Subline:** `Your receipt becomes a service log in two taps.`

**Device content:** Split-state composition.
- Top half: a slightly-tilted photo of a real-looking taller receipt (Pep Boys / Mid-Atlantic Tire / "Taller Miguel"). Hand-written values: date, mileage, line items.
- Bottom half: the Checkpoint service log entry sheet auto-populated with date, mileage, "Oil & Filter," cost $52.30. Three fields highlighted with a thin accent underline (the "DETAILS FILLED FROM RECEIPT" treatment).

**Asset to source:** A real receipt photo (the developer's own — best authenticity). Permission to use the shop's name; if not, fictional.

---

### Frame 3 — Widgets everywhere

**Story role:** Trust + differentiator. Closes the first-3-screenshot story by showing *Checkpoint comes to you.*

**Caption:** `THE APP COMES TO YOU.`
**Subline:** `Widgets, Watch, Siri, CarPlay. Open it less.`

**Device content:** Multi-device composite, ordered left-to-right:
1. iPhone Lock Screen with a rectangular widget: `OIL CHANGE · 247 MI OVERDUE`
2. iPhone Home Screen with medium widget: `NEXT: BRAKE PADS · DEC 14` plus the "MARK DONE" interactive button visible
3. Apple Watch face (Modular Compact) with the Checkpoint complication: `OIL · 247 MI`
4. CarPlay dashboard widget at the bottom of the composite: `NEXT UP · OIL CHANGE`

This frame must look *busy* but *organized* — the brutalist grid keeps it disciplined.

---

### Frame 4 — Costs at a glance

**Story role:** Lead the second arc (Proof). Show the analytics depth.

**Caption:** `WHERE THE MONEY WENT.`
**Subline:** `Cost-per-mile, monthly trend, by category.`

**Device content:** Costs tab. The proportion bar across the top (Maintenance / Repairs / Upgrades split). Below it, the monthly trend line. Year-to-date total shown prominently: `$1,247.83`. One category drill-in chip is pressed/active to imply tappability.

---

### Frame 5 — VIN scan / vehicle setup

**Story role:** Onboarding friction → zero.

**Caption:** `SCAN. DONE.`
**Subline:** `VIN to year-make-model-engine in one tap.`

**Device content:** VIN scanning state — the camera framing a windshield VIN plate, mid-recognition. Below the camera viewfinder, the four fields filling in via the accent-flash treatment: `2019 · HONDA · CIVIC SI · 1.5L TURBO`. The "DETAILS FILLED FROM VIN" success row visible at the bottom.

---

### Frame 6 — Recall alert (the safety hook)

**Story role:** Differentiator + builds trust. Critical for PR (mail delay angle).

**Caption:** `WE'LL TELL YOU FIRST.`
**Subline:** `NHTSA recalls, before the mail catches up.`

**Device content:** Recall detail screen. Title: `RECALL · 24V-487 · FUEL PUMP`. Severity pill: `SAFETY-CRITICAL`. Status: `NEW`. Below: a one-paragraph summary, a "WHAT THIS MEANS" plain-language explainer (because most NHTSA notices read like court filings), and a "MARK READ" action.

⚠️ Avoid using a real, specific recall ID — fictional or generic. Apple reviewers can flag misrepresentation.

---

### Frame 7 — Apple Watch

**Story role:** Apple ecosystem proof, second wave.

**Caption:** `ON YOUR WRIST.`
**Subline:** `Log mileage. Mark done. Glance and go.`

**Device content:** Apple Watch (Series 10/Ultra). Three small watch screens in a row, each showing a different state: Next Up complication, the mileage update keypad screen, and the "Marked done" confirmation. **This is the screenshot that earns press from MacStories / The Sweet Setup.** Federico Viticci's pitch hooks here. (See `PRESS_KIT.md`.)

---

### Frame 8 — Marbete (Spanish locale only) / DIY-friendly custom service (English locale)

**English locale:**

**Caption:** `BUILD YOUR OWN SERVICES.`
**Subline:** `Custom types. Freeform notes. DIY-friendly.`
**Device:** Custom service type creation screen. Showing `TRANSMISSION FLUID FLUSH` being created with a 60K-mile interval.

**Spanish (Mexico) locale — different screenshot:**

**Caption:** `EL MARBETE, A TIEMPO.`
**Subline:** `Recordatorio de marbete e inspección.`
**Device:** A vehicle with two paired schedules visible: `MARBETE · VENCE FEBRERO` and `INSPECCIÓN · 30 DÍAS ANTES`. The PR flag emoji or text is *not* used — locale itself signals context. Below: a "shareable card" thumbnail with a "share" icon to imply the WhatsApp-export feature.

---

### Frame 9 — Service history PDF

**Story role:** Trust ("your data is yours, exportable").

**Caption:** `YOUR HISTORY. YOUR FILE.`
**Subline:** `One-tap PDF for resale, warranty, insurance.`

**Device content:** Side-by-side: app screen with the export confirmation modal, and a preview thumbnail of the generated PDF behind it (vehicle header, chronological service table). Reinforces the "the buyer will ask for this" angle.

---

### Frame 10 — Pricing / honesty

**Story role:** Close the loop. Address the subscription-fatigue elephant.

**Caption:** `NO ADS. NO ACCOUNT. NO SUB.`
**Subline:** `Free for 3 vehicles. $9.99 once for unlimited.`

**Device content:** Settings → Pricing page. Big crossed-out `$14.99` next to `$9.99 LAUNCH PRICE`. Three checkmarked lines:
- `FREE FOR UP TO 3 VEHICLES`
- `ICLOUD SYNC, ALWAYS FREE`
- `NO RECURRING CHARGES, EVER`

This is the screenshot users will reference when they recommend the app. *"It's free and it's not trying to upsell you."*

---

### How to actually produce the screenshots

1. Take raw screenshots from the iPhone 17 Pro Max simulator on a build with realistic seeded data. (The seeded-data part is the time sink — block out 1–2 days.)
2. For Frames 2, 3, 5, 7: assemble composites in Figma. For 1, 4, 6, 8, 9, 10: a single device frame is enough.
3. Use **Screenshots.pro** or **Rotato** for the device frames; both export the exact 1320×2868 canvas size Apple needs.
4. Export PNG, no alpha, sRGB. Check filesize: under 8MB each.
5. Submit one localized set per locale (`en-US`, `es-MX`). The `es-MX` set differs from `en-US` only in Frames 1, 2, 3, 8, 10 (captions translated, Frame 8 entirely different screen).

---

## 5. App Preview Videos — script

Apple allows up to 3 previews per locale, 15–30 sec each. Research says **two shorter clips outperform one 30-sec clip.** ([Apptweak](https://www.apptweak.com/en/aso-blog/keys-to-an-app-preview-video-that-converts))

### Preview A — "The Glance" (24 seconds)

| Time | Visual | Caption (no audio) |
|---|---|---|
| 0:00 – 0:03 | Black screen, then iPhone Lock Screen lights up. Marbete widget visible: `OIL CHANGE · 247 MI`. Thumb taps. | `OPEN, AND THERE IT IS.` |
| 0:03 – 0:08 | Home tab. Next Up card animates in with the overdue oil change. | `WHAT'S DUE. WHAT'S NEXT.` |
| 0:08 – 0:14 | User taps "MARK DONE" in the medium widget on Home Screen. Confirmation animation. | `MARK IT DONE WITHOUT OPENING THE APP.` |
| 0:14 – 0:20 | Apple Watch wrist-raise → complication shows next service. | `ON YOUR WRIST.` |
| 0:20 – 0:24 | Static final card: app icon, name, `Free. No ads. No account.` | — |

### Preview B — "The Data Entry" (22 seconds)

| Time | Visual | Caption |
|---|---|---|
| 0:00 – 0:04 | Hand holding a paper receipt next to an iPhone. | `LOGGING SHOULDN'T BE A CHORE.` |
| 0:04 – 0:10 | Camera scans the receipt. Fields populate in real time. | `SNAP. THE FIELDS FILL THEMSELVES.` |
| 0:10 – 0:15 | Cut to: VIN being scanned through a windshield. Year/make/model/engine fill in. | `VIN, ODOMETER, RECEIPTS — ALL ON-DEVICE.` |
| 0:15 – 0:22 | End card with the tagline `KNOW WHAT'S NEXT.` and app icon. | — |

### Production notes

- **No music** that has copyright friction. Use Apple's free Music for Reviews library, or absolute silence — silence is on-brand for the brutalist aesthetic and avoids licensing issues.
- **Captions are visual elements**, not subtitles. JetBrains Mono Bold, off-white on cerulean, never auto-generated.
- **First 3 seconds must contain the strongest visual moment** — the Lock Screen widget activating in Preview A, the receipt-in-hand reveal in Preview B.

---

## 6. App Privacy disclosures

Already drafted in [`docs/APP_STORE_CONNECT.md`](../APP_STORE_CONNECT.md). Marketing-relevant takeaway: **mark everything as "Used for App Functionality," nothing as "Tracking."** PostHog is self-hosted and opt-out → qualifies as analytics, not tracking. This matters because the iOS privacy nutrition label is now a discovery surface — apps with "Data Not Collected" or "Data Linked to You = none" labels show better conversion in 2025 ASO studies. ([Apptweak Benchmarks 2025](https://www.apptweak.com/en/aso-blog/aso-app-store-trends-benchmarks-report))

---

## 7. Review prompt strategy

The App Store rating is the single largest conversion-rate lever after screenshots. Plan for it deliberately, not reflexively.

| Trigger | Timing | Cooldown |
|---|---|---|
| User has logged ≥3 services in distinct sessions | Min 14 days since install | Never re-prompt if dismissed |
| User has completed a service via the widget's "Mark Done" | Trigger immediately after — peak satisfaction moment | Same — once per install lifetime |
| User has shared their PDF service history | Immediately after share-sheet returns success | Same |

Use `SKStoreReviewController.requestReview` — Apple caps to 3 prompts/365 days regardless of code. Anti-pattern: prompting on app launch. Never do it.

---

## 8. Pre-submission checklist (copy-paste into Linear / Asana)

- [ ] Bundle ID created, app shell exists in App Store Connect
- [ ] App Name + Subtitle locked (both locales)
- [ ] Keywords field locked (both locales)
- [ ] Description copied in (both locales) — Spanish reviewed by 2 native PR speakers
- [ ] Promotional Text drafted
- [ ] Screenshots: 10 × 6.9" (`en-US`), 10 × 6.9" (`es-MX`)
- [ ] Apple Watch screenshots: 410 × 502 (`en-US` only is fine for v1.0)
- [ ] App Preview A (24s) uploaded for `en-US`
- [ ] App Preview B (22s) uploaded for `en-US`
- [ ] App Preview A localized voiceless captions for `es-MX` (Preview B can wait)
- [ ] Privacy Policy URL live and reachable
- [ ] Support URL live and reachable
- [ ] PrivacyInfo.xcprivacy in the Xcode project (per [APP_STORE_CONNECT.md](../APP_STORE_CONNECT.md))
- [ ] IAPs in "Ready to Submit" state
- [ ] Review notes script copied in (with VIN `1HGBH41JXMN109186` for the reviewer)
- [ ] Featuring nomination submitted via App Store Connect ≥ 2 weeks before target ship date

---

_Last updated: 2026-05-12_
