# Biombo — Implementation Plan

Companion to `docs/FUEL_PRICE_TRACKER.md` and `docs/AESTHETIC.md`. End-to-end actionable plan with all user refinements incorporated.

## Context

Biombo is a standalone iOS app + Postgres-backed backend that surfaces Puerto Rico gas prices. It scrapes DACO daily for an official baseline, accepts crowd-sourced photo submissions (OCR'd on-device) that get compared against DACO, and renders a brutalist map + list + historical trends. Both Biombo and Checkpoint share a refactored design system and localization infrastructure in a re-organized monorepo.

## Decisions baked in

| Topic | Decision |
|---|---|
| App name | **Biombo** (placeholder-acceptable) |
| iOS bundle ID | `com.418-studio.biombo` |
| Minimum iOS | 17 (match Checkpoint) |
| Localization | **EN + ES in both Checkpoint and Biombo** — shared `Localization` package, String Catalog (.xcstrings) workflow |
| Aesthetic | Shared 418 brutalist philosophy per `docs/AESTHETIC.md`. Biombo adopts the AESTHETIC.md palette (Cerulean `#0033BE` + Off-White `#F5F0DC`, JetBrains Mono). Checkpoint keeps its amber/dark theme — both apps consume the same `DesignKit` package via a `ThemeProviding` protocol. |
| Design system package | Renamed from `CheckpointUI` → **`DesignKit`** (neutral, shared) |
| DACO data source | No public API → **own backend scraper**; stores historical series in Postgres |
| Backend infra assumption | **PostgreSQL only** — deployment details deferred |
| Backend location | `apps/biombo/backend/` — **strictly separate from the iOS app, never bundled** |
| Backend tech | Node/TypeScript (matches existing `checkpoint-website` SolidJS stack competency) with `pg` driver + Drizzle or Prisma, Playwright for the scraper if DACO pages are JS-rendered |
| Submission flow | On-device Vision OCR + brand detection → POST `{imageBytes, ocrText, parsedPrice, detectedBrand, lat, lng}` to backend → Postgres (image as `bytea`, text as columns) |
| Brand detection | On-device Vision + string matching against the DACO brand list; backend cross-references against today's DACO record for that brand/station to compute ± delta |
| Map | Apple MapKit with custom annotation overlays styled to AESTHETIC.md (cerulean canvas, off-white pins, JetBrains Mono price labels, 2px borders, no rounded corners) |
| CloudKit | **Removed** — everything flows through our Postgres backend |

## Monorepo refactor (Phase 0 structural change)

Current layout is Checkpoint-centric (`checkpoint-app/`, `checkpoint-website/`). New symmetric structure:

```
418-vehicle-maintenance-tracker/
├── apps/
│   ├── checkpoint/
│   │   ├── ios/                    # ← moved from checkpoint-app/
│   │   └── web/                    # ← moved from checkpoint-website/
│   └── biombo/
│       ├── ios/                    # NEW — Swift iOS app
│       └── backend/                # NEW — Postgres API + scraper (NOT bundled with ios/)
├── packages/
│   ├── DesignKit/                  # NEW — shared SwiftPM design system
│   └── Localization/               # NEW — shared String Catalog + helpers
├── docs/
└── README.md
```

Moves are done with `git mv` to preserve history. Xcode project references, SwiftPM paths, and CI configs get updated accordingly.

---

## Key findings from the code

- **Spanish missing in both apps** — only `en.lproj/Localizable.strings` exists in Checkpoint. Both apps get ES in Phase 0 via a shared String Catalog.
- **No existing `packages/`** — greenfield SwiftPM setup.
- **ThemeManager heavily coupled:** `Theme.*` has **1,058** call sites, `Spacing.*` has **694**, `.brutalistBorder()` has **96**. `ThemeManager` is an `@Observable @MainActor` singleton. Biggest Phase 0 risk — the protocol refactor must not regress existing call sites.
- **Reusable patterns (keep as-is, reference from Biombo):**
  - `actor NHTSAService` at `checkpoint-app/checkpoint/Services/Utilities/NHTSAService.swift` (309 lines) → template for Biombo's backend service.
  - `actor ReceiptOCRService` at `checkpoint-app/checkpoint/Services/OCR/ReceiptOCRService.swift` (152 lines) → template for `FuelOCRService`.
  - `ServiceAttachment.compressedImageData(from:maxSize:quality:)` at `checkpoint-app/checkpoint/Models/ServiceAttachment.swift:115` → template for image compression (parameterize defaults from 800/0.8 to 400/0.5).
- **Extractable components live in `Theme.swift`**: `InstrumentSectionHeader` (line 434), `BrutalistDataRow` (line 473), `AtmosphericBackground` (line 402). All model-free; safe to move into `DesignKit`.

---

## Phase 0 — Monorepo refactor, DesignKit, shared Localization, backend scaffold

**Goal:** Reorganize the repo, extract a theme-agnostic `DesignKit`, centralize localization, scaffold the Biombo backend, and drop scoped CLAUDE.md files throughout for LLM progressive disclosure. Checkpoint must build/test green at the end.

### 0.1 Directory moves
1. `git mv checkpoint-app apps/checkpoint/ios`
2. `git mv checkpoint-website apps/checkpoint/web`
3. Update `apps/checkpoint/ios/checkpoint.xcodeproj` internal paths (Xcode handles most refs, but `Secrets.xcconfig` reference and package relative paths need verification).
4. Update `apps/checkpoint/web/` — `package.json`, `wrangler.toml`, CI paths.
5. Update `docs/CLAUDE.md`-equivalent scoped files and root `CLAUDE.md` to reflect new paths.

### 0.2 `packages/DesignKit/`
1. Create SwiftPM package (iOS 17, library product).
2. Define `ThemeProviding` protocol exposing color tokens, font design, and change events. All current `Theme.*` and `Typography.*` reads resolve through an injected provider.
3. Add `ThemeEnvironment` (`EnvironmentKey` with a default provider) so `Theme.backgroundPrimary` pulls from environment, not from a hardcoded singleton.
4. Move files into the package:
   - `Theme.swift` — tokens + modifiers (`.cardStyle`, `.brutalistBorder`, `.glassCardStyle`, `.screenPadding`)
   - `Typography.swift`, `Spacing.swift`, `ThemeDefinition.swift`
   - `InstrumentSection.swift`, `BrutalistChartStyle.swift`, `TappableCardModifier.swift`, `TouchTarget.swift`
   - Split-out components: `InstrumentSectionHeader.swift`, `BrutalistDataRow.swift`, `AtmosphericBackground.swift`
5. Move `Themes.json` to package bundle resources.
6. Ship two built-in providers in the package:
   - `CheckpointDefaultTheme` (current amber/dark palette — matches existing Checkpoint look)
   - `AestheticBrutalistTheme` (cerulean `#0033BE` + off-white `#F5F0DC` + JetBrains Mono — matches `docs/AESTHETIC.md` for Biombo)
7. Bundle JetBrains Mono font file in the package resources (license permits embedding).

### 0.3 Checkpoint consumes DesignKit
1. Add `DesignKit` local package dependency on Checkpoint iOS + Watch + Widget + WatchWidget targets.
2. Keep `ThemeManager.swift` in Checkpoint; conform it to `DesignKit.ThemeProviding`; register it with `ThemeEnvironment` in `checkpointApp.swift` via `.environment(\.theme, ThemeManager.shared)`.
3. `apps/checkpoint/ios/checkpoint/DesignSystem/` becomes thin re-export shims so the ~1,750 existing call sites compile unchanged. Long-term follow-up: add `import DesignKit` to each view and delete shims.

### 0.4 `packages/Localization/`
1. Create SwiftPM package with a single **String Catalog** (`Shared.xcstrings`) containing `en` + `es` for strings shared by both apps (units, fuel grade names, common UI verbs). App-specific strings stay in per-app catalogs.
2. Expose `L10n.shared.<key>` helpers typed via generated code (Swift-gen or hand-rolled enum).
3. Add per-app String Catalogs:
   - `apps/checkpoint/ios/checkpoint/Resources/Checkpoint.xcstrings` — migrate existing Checkpoint `.strings` content to xcstrings format; add ES translations for the full surface.
   - `apps/biombo/ios/Biombo/Resources/Biombo.xcstrings` — EN + ES from day one.
4. Both apps add `Localization` as local package dep.

### 0.5 Progressive-disclosure CLAUDE.md files

**Why:** Future LLM sessions (and Claude Code on the web) need to orient without loading the entire repo. Scoped CLAUDE.md files let the harness load only the relevant slice for a given task.

Layout:

```
CLAUDE.md                                       # root — monorepo map, top-level conventions
apps/CLAUDE.md                                  # "there are two apps; each has a CLAUDE.md"
apps/checkpoint/CLAUDE.md                       # Checkpoint overview + pointers to ios/web
apps/checkpoint/ios/CLAUDE.md                   # existing content relocated (SwiftUI, SwiftData, build commands)
apps/checkpoint/web/CLAUDE.md                   # existing website CLAUDE.md relocated
apps/biombo/CLAUDE.md                           # Biombo overview + pointers to ios/backend
apps/biombo/ios/CLAUDE.md                       # Biombo iOS specifics (DesignKit theme, AESTHETIC.md ref, build cmd)
apps/biombo/backend/CLAUDE.md                   # Node/TS, Postgres, migration workflow, API contract link
packages/CLAUDE.md                              # "two shared SwiftPM packages"
packages/DesignKit/CLAUDE.md                    # protocol, theme providers, how to add tokens
packages/Localization/CLAUDE.md                 # xcstrings workflow, how to add keys
```

Content rules:
- Each file is **short** (≤ 100 lines). Points out the canonical files and where to go deeper.
- Root `CLAUDE.md` is the most load-bearing — it replaces the current Checkpoint-centric one and redirects to scoped files based on what the task is about.
- Restricted-files warnings (`Secrets.xcconfig`) duplicated in root and in `apps/checkpoint/ios/CLAUDE.md` for redundancy.
- Build commands scoped to their app (`xcodebuild` commands stay inside `ios/CLAUDE.md`, not root).

### 0.6 Biombo backend scaffold (`apps/biombo/backend/`)
1. `package.json` — Node 20+, TypeScript, Fastify (or Hono), `pg`, `drizzle-orm`, Playwright for scraping, Zod for validation.
2. `src/` layout:
   - `src/scraper/daco.ts` — daily DACO fetcher; parses station-level prices (if present) or falls back to municipality-level averages.
   - `src/scraper/brands.ts` — canonical DACO brand list (Puma, Shell, Total, Gulf, Sol, Texaco, …) exported for the iOS app to consume.
   - `src/db/schema.ts` — Drizzle schema: `daco_snapshots`, `daco_station_prices`, `submissions`, `submission_confirmations`, `submission_flags`.
   - `src/api/` — Fastify routes: `GET /prices/current`, `GET /prices/history`, `GET /brands`, `POST /submissions`, `POST /submissions/:id/confirm`, `POST /submissions/:id/flag`, `DELETE /submissions/:id` (owner-only via anonymous device token).
   - `src/jobs/dailyScrape.ts` — cron entry point.
   - `src/index.ts` — server bootstrap.
3. `migrations/` — Drizzle SQL migrations. Image blobs stored as `bytea` (per decision — Postgres-only, infra deferred).
4. `README.md` — documents the API contract; this is the integration seam for the iOS app.
5. `tsconfig.json`, `.eslintrc`, `vitest.config.ts` for service-level tests with a dockerized Postgres (or `pg-mem` for unit-level).

### 0.7 Verification
- `xcodebuild build -scheme checkpoint -destination 'platform=iOS Simulator,name=iPhone 17'` (new path)
- `xcodebuild test -scheme checkpoint -destination 'platform=iOS Simulator,name=iPhone 17'` — all existing tests green
- Visual spot-check: Checkpoint UI unchanged
- `cd apps/biombo/backend && npm test` — scraper + route tests pass against pg-mem or local Postgres
- One manual scrape populates `daco_snapshots`; `GET /prices/current` returns valid JSON

---

## Phase 1 — Biombo iOS MVP (read-only)

**Goal:** Biombo launches, shows PR stations on a brutalist Apple Map + list, renders historical trend chart, reads exclusively from the backend.

1. `apps/biombo/ios/Biombo.xcodeproj` scaffold — main target + test target. Bundle ID `com.418-studio.biombo`, scheme `Biombo`.
2. Add `DesignKit` + `Localization` local package deps. Register `AestheticBrutalistTheme` with `ThemeEnvironment` at launch.
3. `BiomboApp.swift` + `ContentView.swift` — map/list segmented control; 35px off-white frame around viewport per AESTHETIC.md §"The Frame".
4. `Services/LocationService.swift` — `CoreLocation` "When In Use" wrapper.
5. `Services/BiomboAPIService.swift` — actor, static shared, URLSession against backend, in-memory + SwiftData cache. Mirrors `NHTSAService` shape.
6. `Models/CachedFuelPrice.swift` — SwiftData `@Model` per `FUEL_PRICE_TRACKER.md` lines 143-158.
7. `Models/PriceHistoryPoint.swift` — SwiftData `@Model` for trend chart (`stationId`, `date`, `regular`, `premium`, `diesel`).
8. `Models/Brand.swift` — cached DACO brand list with logos (fetched from `/brands`).
9. `Views/FuelMapView.swift` — `MapKit.Map` with custom `MapContent` annotations:
   - Cerulean background, off-white pin shapes, no rounded corners
   - JetBrains Mono price label inline
   - 2px off-white border
   - Custom `MapStyle` applied for cohesion with AESTHETIC.md (monochrome + cerulean tint where MapKit allows)
10. `Views/FuelListView.swift` — distance-sorted list; monospace numerals; section dividers 2px @ 20% opacity.
11. `Views/FuelPriceDetailView.swift` — station detail card; includes 30-day trend chart via `BrutalistChartStyle`; shows last-known DACO price + community median + delta.
12. `Views/Components/PriceAnnotationView.swift`, `StationRow.swift`, `FreshnessIndicator.swift`, `PriceTrendChart.swift`.
13. `Views/FuelSettingsView.swift` — unit toggle (liters default for PR), language override, data source toggle, about.
14. `State/BiomboAppState.swift` — `@Observable`: selected station, view mode, unit, language.
15. Tests:
    - `CachedFuelPriceTests.swift` — in-memory ModelContainer
    - `PriceHistoryPointTests.swift`
    - `BiomboAPIServiceTests.swift` — fixture JSON → parse tests
    - `LocationServiceTests.swift`

### Verification
- `xcodebuild build -scheme Biombo -destination 'platform=iOS Simulator,name=iPhone 17'` succeeds
- Sim launch → location prompt → map loads with backend-sourced stations
- Map matches AESTHETIC.md palette (cerulean dominant, off-white accents, JetBrains Mono labels)
- List sorts by distance; units toggle; language override works (EN/ES)
- Detail view renders 30-day trend chart + DACO comparison

---

## Phase 2 — Crowd-sourced submissions with brand detection

**Goal:** User photographs a price sign → iPhone runs OCR + brand detection → uploads `{image, ocr, parsedPrice, detectedBrand, location}` to backend → backend cross-references DACO → displays delta on map.

### iOS
1. `Services/ImageCompressionService.swift` — 400x400 / JPEG 0.5 / EXIF strip; parameterized port of `ServiceAttachment.compressedImageData`.
2. `Services/FuelOCRService.swift` — adapted from `ReceiptOCRService` (actor, Vision, EN+ES). Returns `[PriceCandidate]` (numeric + confidence) + raw recognized text.
3. `Services/BrandDetectionService.swift` — reads the cached DACO brand list, scans OCR text (and optionally Vision logo detection via `VNImageRequestHandler` + `VNRecognizeTextRequest` on brand wordmarks) for matches, returns best candidate + confidence.
4. `Views/SubmitPriceSheet.swift` — camera/photo picker → live OCR → editable suggestion → auto-populated fuel grade + detected brand (user can override) → submit button.
5. `Services/BiomboAPIService.swift` — `submitPrice(request:) async throws` — multipart upload of image + JSON metadata.

### Backend
1. `POST /submissions` — accepts multipart `{image: bytea, ocr_text, parsed_regular, parsed_premium, parsed_diesel, detected_brand, lat, lng, device_token}`. Stores row + image bytes. Cross-references latest DACO snapshot for that brand+municipality and writes a computed `daco_delta_regular/premium/diesel` column.
2. `GET /prices/current` returns union of (a) latest DACO snapshot and (b) non-expired submissions (48h user, 24h DACO) with delta annotations.
3. `POST /submissions/:id/confirm` and `/flag` — increment counters. Records with `flag_count >= 3` are hidden from `/prices/current` response.
4. Median smoothing: when 3+ submissions exist for same station within 24h, response returns the median as the station's current community price.
5. Rate limiting via device_token (anonymous uuid generated on first launch, stored in keychain) — max 20 submissions/device/day.
6. Image handling: stored as `bytea`; served via `GET /submissions/:id/image` with 1-day cache header. 400x400 max is cheap enough for Postgres at MVP scale.

### Tests
- `FuelOCRServiceTests.swift` — fixture pump-sign images → expected price strings
- `BrandDetectionServiceTests.swift` — fixture OCR → correct brand pick
- `BiomboAPIServiceTests.swift` — mock endpoints for submit flow
- `ImageCompressionServiceTests.swift` — output size + EXIF stripped
- Backend: `submissions.test.ts`, `daco_crossref.test.ts`, `rate_limit.test.ts`

### Verification
- Photo → OCR populates price → brand auto-detected → submit → visible on map within seconds
- DACO delta shown in detail view ("$0.12 above DACO avg for this brand")
- Flag x3 hides record
- Expired (>48h) records disappear

---

## Phase 3 — Polish & ship

1. App icon and launch screen faithful to AESTHETIC.md (cerulean canvas, single bold mark).
2. Onboarding: location permission + brand primer + 2-screen explainer (EN/ES).
3. Offline mode: last cache drives map; "OFFLINE" status chip in the top bar.
4. Error + empty states using AESTHETIC.md technical dashboard conventions (STATUS / VERSION / ERROR-CODE blocks).
5. App Store metadata (EN + ES), screenshots, privacy policy, support URL.
6. Privacy Nutrition Labels: Location (when in use, not linked), Photos (linked, user content), User Content (via our backend).
7. Performance profile map with ~500 annotations.
8. UI tests: launch → map, launch → list, submit flow, offline.

---

## Phase 4 — Checkpoint integration (deferred; ship Phase 3 first)

1. Register URL scheme `biombo://` in Biombo.
2. Add "Find Gas Prices" entry in Checkpoint (**default placement: Settings row**; can move later based on analytics).
3. `UIApplication.canOpenURL` check → deep link or App Store fallback.
4. No App Group until a concrete reason emerges.

---

## Files to create (canonical)

```
packages/DesignKit/
├── Package.swift
└── Sources/DesignKit/
    ├── ThemeProviding.swift                    # NEW protocol
    ├── ThemeEnvironment.swift                  # NEW env injection
    ├── Providers/
    │   ├── CheckpointDefaultTheme.swift        # Amber/dark
    │   └── AestheticBrutalistTheme.swift       # Cerulean/off-white (AESTHETIC.md)
    ├── Theme.swift                             # tokens + modifiers
    ├── Typography.swift
    ├── Spacing.swift
    ├── ThemeDefinition.swift
    ├── InstrumentSection.swift
    ├── BrutalistChartStyle.swift
    ├── TappableCardModifier.swift
    ├── TouchTarget.swift
    ├── Components/
    │   ├── InstrumentSectionHeader.swift
    │   ├── BrutalistDataRow.swift
    │   └── AtmosphericBackground.swift
    └── Resources/
        ├── Themes.json
        └── Fonts/JetBrainsMono-*.ttf

packages/Localization/
├── Package.swift
└── Sources/Localization/
    ├── L10n.swift
    └── Resources/Shared.xcstrings              # EN + ES shared strings

apps/biombo/ios/
├── Biombo.xcodeproj
├── Biombo/
│   ├── BiomboApp.swift
│   ├── ContentView.swift
│   ├── Biombo.entitlements                     # location only (no CloudKit)
│   ├── Info.plist
│   ├── Models/
│   │   ├── CachedFuelPrice.swift
│   │   ├── PriceHistoryPoint.swift
│   │   └── Brand.swift
│   ├── State/BiomboAppState.swift
│   ├── Services/
│   │   ├── BiomboAPIService.swift              # all backend I/O
│   │   ├── FuelOCRService.swift
│   │   ├── BrandDetectionService.swift
│   │   ├── LocationService.swift
│   │   └── ImageCompressionService.swift
│   ├── Views/
│   │   ├── FuelMapView.swift
│   │   ├── FuelListView.swift
│   │   ├── FuelPriceDetailView.swift
│   │   ├── SubmitPriceSheet.swift
│   │   ├── FuelSettingsView.swift
│   │   ├── OnboardingView.swift
│   │   └── Components/
│   │       ├── PriceAnnotationView.swift
│   │       ├── StationRow.swift
│   │       ├── FreshnessIndicator.swift
│   │       └── PriceTrendChart.swift
│   └── Resources/
│       └── Biombo.xcstrings                    # EN + ES
└── BiomboTests/
    ├── CachedFuelPriceTests.swift
    ├── PriceHistoryPointTests.swift
    ├── BiomboAPIServiceTests.swift
    ├── FuelOCRServiceTests.swift
    ├── BrandDetectionServiceTests.swift
    ├── ImageCompressionServiceTests.swift
    └── LocationServiceTests.swift

apps/biombo/backend/
├── package.json
├── tsconfig.json
├── README.md                                   # API contract
├── drizzle.config.ts
├── migrations/
│   ├── 0001_init.sql
│   ├── 0002_submissions.sql
│   └── 0003_submission_interactions.sql
├── src/
│   ├── index.ts
│   ├── db/
│   │   ├── client.ts
│   │   └── schema.ts
│   ├── scraper/
│   │   ├── daco.ts
│   │   └── brands.ts
│   ├── api/
│   │   ├── prices.ts
│   │   ├── submissions.ts
│   │   └── brands.ts
│   └── jobs/
│       └── dailyScrape.ts
└── tests/
    ├── scraper.test.ts
    ├── submissions.test.ts
    ├── daco_crossref.test.ts
    └── rate_limit.test.ts
```

## Files to move / modify

| Path | Change |
|---|---|
| `checkpoint-app/` → `apps/checkpoint/ios/` | `git mv` |
| `checkpoint-website/` → `apps/checkpoint/web/` | `git mv` |
| `apps/checkpoint/ios/checkpoint.xcodeproj/project.pbxproj` | Add `DesignKit` + `Localization` package deps on all 4 targets (main, Watch, Widget, WatchWidget) |
| `apps/checkpoint/ios/checkpoint/DesignSystem/ThemeManager.swift` | Conform to `DesignKit.ThemeProviding`; register with `ThemeEnvironment` |
| `apps/checkpoint/ios/checkpoint/checkpointApp.swift` | Inject `.environment(\.theme, ThemeManager.shared)` at root |
| `apps/checkpoint/ios/checkpoint/DesignSystem/*` | Re-export shims during migration, delete once imports updated |
| `apps/checkpoint/ios/checkpoint/Resources/en.lproj/Localizable.strings` | Migrate to `Checkpoint.xcstrings` with full ES translations |
| `docs/FEATURES.md` | Note Biombo companion app |
| `docs/ARCHITECTURE.md` | Document new monorepo layout + DesignKit protocol |
| `CLAUDE.md` (root) | Rewrite as a monorepo map pointing at scoped CLAUDE.md files |
| `apps/CLAUDE.md`, `apps/checkpoint/CLAUDE.md`, `apps/biombo/CLAUDE.md`, `packages/CLAUDE.md` | NEW orientation stubs |
| `apps/checkpoint/ios/CLAUDE.md`, `apps/checkpoint/web/CLAUDE.md` | Existing CLAUDE.md content relocated with path updates |
| `apps/biombo/ios/CLAUDE.md`, `apps/biombo/backend/CLAUDE.md` | NEW scoped guides |
| `packages/DesignKit/CLAUDE.md`, `packages/Localization/CLAUDE.md` | NEW scoped guides |

---

## Open questions (non-blocking)

1. **Backend deployment target** — infra is deferred per your instruction. Postgres is a given; host (Supabase / Neon / Render / Railway / self-hosted) can be decided closer to Phase 1 ship.
2. **DACO page structure** — site blocks WebFetch (403), so the scraper will need UA spoofing and possibly headless Playwright. Actual selector fragility is the biggest runtime risk; mitigated by aggressive snapshot logging so selector breaks are detected daily.
3. **Phase 4 Checkpoint placement** — defaulting to Settings row; can move based on usage.
4. **Package name `DesignKit`** — if you'd prefer `Studio418UI`, `BrutalistKit`, or another name, flag before Phase 0.

## Verification (end-to-end)

- **After Phase 0:** Repo reorganized; Checkpoint builds and tests green at new paths; Biombo backend scaffold boots locally; one manual scrape populates Postgres; Checkpoint now has ES translations; visual Checkpoint spot-check unchanged.
- **After Phase 1:** Biombo launches at AESTHETIC.md fidelity; map + list + trend chart render from backend; EN/ES both work; DACO comparison visible.
- **After Phase 2:** Photo → OCR + brand detection → submit → backend persists with DACO delta → second device sees record in seconds; flag x3 hides; 48h expiry holds.
- **After Phase 3:** App Store submission package ready.
- **After Phase 4:** Checkpoint deep-links to Biombo (or App Store fallback).

Build commands (note the path change):
```bash
xcodebuild build -scheme checkpoint -destination 'platform=iOS Simulator,name=iPhone 17' \
  -project apps/checkpoint/ios/checkpoint.xcodeproj
xcodebuild build -scheme Biombo -destination 'platform=iOS Simulator,name=iPhone 17' \
  -project apps/biombo/ios/Biombo.xcodeproj
cd apps/biombo/backend && npm run dev
```
Never run xcodebuild in parallel.
