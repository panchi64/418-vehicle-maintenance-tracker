# Fuel Price Tracker — Companion App Plan

> A crowd-sourced fuel price map + DACO official price lookup, built as a **separate companion app** in the same monorepo to keep Checkpoint focused on vehicle maintenance.

---

## Context

Finding gas prices in Puerto Rico is difficult — GasBuddy and Waze have poor local coverage. The idea of adding a fuel price tracker to Checkpoint was evaluated and rejected as an in-app feature because:

1. **Scope mismatch**: A crowd-sourced marketplace is a second product, not a feature. It needs a backend, moderation, image storage, and anti-abuse — none of which Checkpoint currently has.
2. **Persona mismatch**: Maintenance users open the app monthly; gas-price hunters open daily. Serving both poorly is worse than serving one well.
3. **Cold-start problem**: A crowd-sourced map is useless without data density. An indie app can't bootstrap this the way GasBuddy (25 years, 100M+ users) did.
4. **Identity dilution**: Checkpoint's brutalist, focused identity ("one thing, done well") would be muddied by a social/marketplace feature.

**Decision**: Build as a standalone companion app in the monorepo (`fuel-app/`). Checkpoint stays untouched for now; a deep-link button can be added later once the fuel app ships and proves its value.

---

## Suggested App Names

| Name | Rationale |
|------|-----------|
| **Surtidor** | Spanish for "gas pump/dispenser." Authentic to PR, short, brutalist. |
| **Octane** | Clean, fuel-related, English-friendly, memorable. |
| **Gauge** | Instrument metaphor that pairs with Checkpoint's aesthetic. |
| **Litro** | Spanish for "liter" (PR sells fuel in liters). Minimal, distinctive. |
| **Bomba** | PR slang for "gas station." Very local, very short. |

Pick one (or something else entirely) before implementation begins.

---

## Architecture

### Monorepo Layout

```
418-vehicle-maintenance-tracker/
├── checkpoint-app/           # Existing — untouched
├── checkpoint-website/       # Existing — untouched
├── fuel-app/                 # NEW — companion iOS app
│   ├── FuelApp/
│   │   ├── FuelApp.swift
│   │   ├── ContentView.swift
│   │   ├── Models/
│   │   ├── Views/
│   │   ├── Services/
│   │   └── State/
│   ├── FuelAppTests/
│   └── FuelApp.xcodeproj
├── packages/                 # NEW — shared Swift packages
│   └── CheckpointUI/        # Extracted design system
│       ├── Package.swift
│       └── Sources/
│           ├── Theme.swift
│           ├── Typography.swift
│           ├── Spacing.swift
│           └── Modifiers/    # cardStyle, brutalistBorder, etc.
└── docs/
```

### Shared Design System Package (`packages/CheckpointUI/`)

Extract from `checkpoint-app/checkpoint/DesignSystem/` into a local Swift package:

**What moves into the package:**
- `Theme.swift` — color tokens (backgrounds, text, accent, status)
- `Typography.swift` — font scale (brutalistHero through brutalistLabel)
- `Spacing.swift` — spacing tokens (xs through xxl)
- View modifiers: `cardStyle()`, `brutalistBorder()`, `screenPadding()`, `glassCardStyle()`
- Button styles: `PrimaryButtonStyle`, `SecondaryButtonStyle`, `InstrumentButtonStyle`
- Reusable components: `InstrumentSectionHeader`, `BrutalistDataRow`, `AtmosphericBackground`

**What stays in checkpoint-app:**
- `ThemeManager` and dynamic theme switching (app-specific, IAP-gated)
- Custom theme JSON loading
- Any component tightly coupled to Checkpoint's data models

**Migration for Checkpoint:**
- Add `CheckpointUI` as a local package dependency
- Update `import` statements in DesignSystem consumers
- `ThemeManager` stays in-app but configures `CheckpointUI` tokens

**Note on ThemeManager coupling:** The current design system routes all color/font tokens through `ThemeManager.shared.current`, which supports dynamic theme switching (an IAP feature). The shared package will need to define a protocol or configuration point that both apps can satisfy — Checkpoint via its full ThemeManager, and the fuel app via a simpler static configuration. This is the trickiest part of the extraction and should be designed carefully before coding.

### Data Sources

**1. DACO Official Prices (Phase 1 — MVP)**
- Puerto Rico's Departamento de Asuntos del Consumidor publishes daily gas prices
- Scrape or consume their public data feed
- Show read-only list/map of stations with official prices
- No user accounts, no uploads, no moderation needed
- **Research needed**: Confirm DACO data format, URL, update frequency, and legal status of consumption. This is the first task before any code.

**2. Crowd-Sourced Submissions (Phase 2)**
- Users photograph gas station price signs
- OCR suggests the price; user confirms/edits
- Submitted to CloudKit public database
- Anonymized: no username, no profile, no social features

### CloudKit Public Database

**Why CloudKit:**
- Checkpoint already uses CloudKit (private DB for sync) — same Apple Developer account
- No backend to build/operate/pay for
- Built-in rate limiting and anti-abuse
- Privacy-coherent with the existing stack
- Free tier: 10GB assets, 100MB database, 2GB transfer/day

**Schema (CKRecord types):**

```
FuelPriceReport
├── stationName: String          # From MKLocalSearch or user input
├── latitude: Double
├── longitude: Double
├── regularPrice: Double?        # Per-liter price (canonical unit)
├── premiumPrice: Double?
├── dieselPrice: Double?
├── currency: String             # "USD" (PR uses USD)
├── fuelUnit: String             # "liter" or "gallon" (stored canonical, displayed per locale)
├── photoAsset: CKAsset?         # Compressed proof photo
├── source: String               # "user" or "daco"
├── createdAt: Date              # Auto by CloudKit
├── expiresAt: Date              # createdAt + 48h for user reports, + 24h for DACO
├── confirmationCount: Int64     # Other users confirming this price
├── flagCount: Int64             # Reports of bad data
```

**Anonymization:**
- CloudKit public DB records have a `creatorUserRecordID` that Apple stores internally, but it's opaque — other users can't resolve it to a name/email
- The fuel app never queries or displays creator identity
- Users can delete their own submissions (CloudKit tracks creator for this purpose)
- No social features: no usernames, no profiles, no leaderboards

### Local Cache (SwiftData)

A local `@Model` mirrors CloudKit records for offline browsing:

```swift
@Model
final class CachedFuelPrice {
    var recordID: String           // CKRecord.ID reference
    var stationName: String
    var latitude: Double
    var longitude: Double
    var regularPrice: Double?
    var premiumPrice: Double?
    var dieselPrice: Double?
    var source: String
    var reportedAt: Date
    var expiresAt: Date
    var confirmationCount: Int
    var flagCount: Int
    var thumbnailData: Data?       // Tiny preview (~50KB)
}
```

No relationship to `Vehicle` or any Checkpoint model — the fuel app is fully independent.

### Image Handling

- Capture via system camera or photo picker
- Compress aggressively: **400x400 max, JPEG quality 0.5** (~30-50KB per photo)
- Strip EXIF metadata before upload (privacy)
- Store as `CKAsset` in CloudKit
- Local cache stores only the thumbnail (120x120)
- Pattern reused from `ServiceAttachment.compressedImageData()` in Checkpoint

### OCR for Price Extraction

Reuse the pattern from `checkpoint-app/checkpoint/Services/OCR/ReceiptOCRService.swift`:
- Vision framework, on-device, EN + Spanish
- Extract text from pump price sign photo
- Parse for price patterns (e.g., `$0.XX`, `XX.XX`, currency patterns)
- Present as editable suggestion — user confirms or corrects
- **Expectation**: OCR on outdoor price signs will be less reliable than receipts (glare, distance, fonts). The UX must treat OCR as a convenience hint, not a requirement. Manual entry is always the fallback.

### Location Services

- `CoreLocation` for user's current position
- Permission: "When In Use" only — no background tracking
- `MKLocalSearch` to identify nearby gas stations by name/brand
- `MapKit` for map display with custom annotations

---

## UI Design

### Views

**Map View (primary)**
- Full-screen MapKit map with brutalist styling
- Custom annotations showing price + freshness indicator
- Color coding: green (fresh, < 6h), amber (aging, 6-24h), gray (stale, 24-48h)
- Tap annotation → detail card with all grades, photo, confirm/flag buttons
- "Center on me" button

**List View (alternative)**
- Sorted by distance from user
- Station name, brand, prices, freshness, distance
- Toggle between map and list via segmented control

**Submit Sheet**
- Camera capture or photo picker
- OCR processing indicator → suggested price (editable)
- Fuel grade selector (Regular / Premium / Diesel)
- Station auto-detected via `MKLocalSearch` at current location
- "Submit" button — one-tap when OCR works, minimal typing otherwise

**Settings**
- Unit preference (liters / gallons) — default from locale
- Data source toggle (DACO only / DACO + community / community only)
- Clear cache
- About / privacy policy

### Puerto Rico Specifics

- Default unit: **liters** (PR sells fuel in liters, priced per liter)
- Currency: **USD** (PR uses US dollars)
- Common fuel grades: Regular, Premium, Diesel
- Common station brands: Puma, Shell, Total, Gulf, Sol, Texaco
- Spanish localization: mandatory from day one (app already supports ES via L10n patterns in Checkpoint)

---

## Phased Rollout

### Phase 0: Foundation
- [ ] Research DACO data availability (format, URL, update frequency, legality)
- [ ] Extract `CheckpointUI` shared package from `checkpoint-app/checkpoint/DesignSystem/`
- [ ] Migrate Checkpoint to consume `CheckpointUI` as a local package dependency
- [ ] Verify Checkpoint builds and tests pass after migration

### Phase 1: MVP — DACO Read-Only
- [ ] Create `fuel-app/` Xcode project scaffold
- [ ] Integrate `CheckpointUI` package
- [ ] Implement `CoreLocation` permission flow
- [ ] Build map view with `MapKit` (brutalist annotations)
- [ ] Build list view (sorted by distance)
- [ ] Implement DACO data service (fetch + parse official prices)
- [ ] Local cache with SwiftData (`CachedFuelPrice`)
- [ ] Settings view (units, about)
- [ ] Spanish localization
- [ ] Unit tests for data parsing, model logic, location utilities

### Phase 2: Crowd-Sourced Submissions
- [ ] Set up CloudKit public database container
- [ ] Implement `FuelPriceService` (actor-based, mirrors `NHTSAService` pattern)
- [ ] Camera capture + photo compression pipeline
- [ ] OCR price extraction service (adapted from `ReceiptOCRService`)
- [ ] Submit sheet UI
- [ ] Upload flow: compress photo → strip EXIF → create CKRecord → upload
- [ ] Merge DACO + community data in map/list views
- [ ] Freshness/expiry logic (visual aging, auto-hide expired)
- [ ] Confirm/flag buttons on price detail cards
- [ ] Median smoothing: if 3+ reports exist for a station, display median price

### Phase 3: Polish & Ship
- [ ] App icon and branding
- [ ] Onboarding flow (location permission, brief explanation)
- [ ] Offline mode (graceful degradation when no network)
- [ ] Error states and empty states
- [ ] App Store metadata, screenshots, privacy policy
- [ ] Privacy Nutrition Labels (location when in use, photos, CloudKit)
- [ ] Performance profiling (map with many annotations)
- [ ] UI tests

### Phase 4: Checkpoint Integration (Deferred)
- [ ] Register URL scheme in fuel app
- [ ] Add "Find Gas Prices" button in Checkpoint (location TBD — Settings, Costs footer, or Home)
- [ ] `canOpenURL` check → launch fuel app or link to App Store
- [ ] Shared App Group for passing vehicle context (optional, probably unnecessary)

### Future Considerations (Not Planned)
- Smart triggers (Bluetooth disconnect detection at gas stations) — complex, invasive, defer indefinitely
- Widget showing nearest cheapest gas
- Apple Watch complication
- Notifications when prices drop in your area — only if users explicitly request it
- Revenue model (if needed): tip jar mirroring Checkpoint's model, never ads

---

## Risks & Open Questions

| Risk | Severity | Mitigation |
|------|----------|------------|
| DACO data unavailable or changes format | High | Research first (Phase 0). If unavailable, launch with crowd-sourced only and accept cold-start. |
| CloudKit public DB quota exceeded | Medium | Aggressive image compression, cache on client, monitor usage. Free tier allows 2GB transfer/day — likely sufficient for PR market. |
| Cold-start for crowd-sourced data | High | DACO provides baseline. Community data is additive, not required. |
| OCR unreliable on outdoor signs | Low | OCR is a suggestion, not a requirement. Manual entry always available. |
| Abuse / fake prices | Medium | Median smoothing, flag/report, 48h auto-expiry, CloudKit rate limiting. |
| ThemeManager extraction complexity | Medium | Design the protocol interface carefully in Phase 0 before touching code. |
| Two apps to maintain | Medium | Shared package reduces drift. Fuel app is simpler (no SwiftData relationships, no notifications, no widgets initially). |
| App Store rejection (crowdsourced UGC) | Low | Apple allows UGC with report/flag mechanism. No social features reduces scrutiny. |

---

## Files to Create

```
fuel-app/
├── FuelApp/
│   ├── FuelApp.swift                          # App entry point
│   ├── ContentView.swift                      # Map/List toggle root view
│   ├── Models/
│   │   └── CachedFuelPrice.swift              # SwiftData local cache model
│   ├── Views/
│   │   ├── FuelMapView.swift                  # MapKit map with annotations
│   │   ├── FuelListView.swift                 # Distance-sorted station list
│   │   ├── FuelPriceDetailView.swift          # Station detail card
│   │   ├── SubmitPriceSheet.swift             # Camera + OCR + submit flow
│   │   ├── FuelSettingsView.swift             # Units, data source, about
│   │   └── Components/
│   │       ├── PriceAnnotationView.swift      # Custom map pin
│   │       ├── StationRow.swift               # List row
│   │       └── FreshnessIndicator.swift       # Visual freshness badge
│   ├── Services/
│   │   ├── DACOService.swift                  # DACO data fetch + parse
│   │   ├── FuelPriceCloudService.swift        # CloudKit public DB CRUD
│   │   ├── FuelOCRService.swift               # Price extraction from photos
│   │   ├── LocationService.swift              # CoreLocation wrapper
│   │   └── ImageCompressionService.swift      # Photo compression + EXIF strip
│   └── State/
│       └── FuelAppState.swift                 # Observable app state
├── FuelAppTests/
│   ├── CachedFuelPriceTests.swift
│   ├── DACOServiceTests.swift
│   └── FuelOCRServiceTests.swift
└── FuelApp.xcodeproj

packages/
└── CheckpointUI/
    ├── Package.swift
    └── Sources/CheckpointUI/
        ├── Theme.swift
        ├── Typography.swift
        ├── Spacing.swift
        └── Modifiers/
            ├── CardStyle.swift
            ├── BrutalistBorder.swift
            ├── ButtonStyles.swift
            ├── GlassCardStyle.swift
            └── ScreenPadding.swift
```

## Files to Modify (in Checkpoint)

| File | Change |
|------|--------|
| `checkpoint-app/checkpoint.xcodeproj` | Add local package dependency on `CheckpointUI` |
| `checkpoint-app/checkpoint/DesignSystem/*` | Thin out to re-exports or remove in favor of package imports |
| Various views importing DesignSystem types | Update `import` statements |

---

## Verification

**Phase 0 verification:**
1. `xcodebuild build -scheme checkpoint` succeeds after package extraction
2. `xcodebuild test -scheme checkpoint` — all existing tests pass
3. Visual spot-check: Checkpoint UI unchanged after migration

**Phase 1 verification:**
1. `xcodebuild build -scheme FuelApp` succeeds
2. Launch in Simulator → location permission prompt → map loads
3. DACO data populates map with PR gas station prices
4. List view shows stations sorted by distance
5. Unit toggle switches between liters and gallons

**Phase 2 verification:**
1. Submit flow: take photo → OCR suggests price → confirm → appears on map
2. Second device sees the submission within ~30 seconds
3. Confirm button increments count
4. Flag button increments count; price hidden after 3 flags
5. Prices older than 48h disappear from map
