# Biombo

A map of everyday life in Puerto Rico, drawing on community reports plus official feeds. It will have an iOS app and an authority web dashboard. Layers:
- gas
- power / water / signal
- roads
- EV chargers
- businesses and events

**Status: greenfield rebuild, UI first on sample data.** The old gas-price-only app was deleted (last present at commit `b5feb5f`). Port pieces from git history only where `docs/SALVAGE.md` says to, e.g. `git show b5feb5f:apps/biombo/ios/...`.

## Docs (all Biombo docs live here, separate from Checkpoint's `docs/`)

- `docs/DESIGN.md` — design direction. Exploratory; nothing is formalized yet.
- `docs/PRODUCT.md` — product definition (current work).
- `docs/DATA_SOURCES.md` — official data sources planned per layer: access, terms, caveats.
- `docs/SALVAGE.md` — what to keep, rewrite or drop from the old app.
- `docs/legacy/` — the old gas-price app's plan and spec. Kept for reference; superseded by the rebuild.

Checkpoint's `docs/AESTHETIC.md` and `docs/SURFACE_DOCTRINE.md` do **not** govern Biombo.

## Order of work

1. **Design (exploratory)** — see `docs/DESIGN.md`.
2. **Product definition** — `docs/PRODUCT.md` (draft for sign-off).
3. **Build (current)** — the iOS UI first, on sample data; the backend and data entry come later.

## iOS app (`ios/`)

SwiftUI + MapKit, iOS 26, Swift 6 language mode, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. Runs on built-in **sample data**; there is no backend or network yet.

- `Biombo/App/`: entry point and root view.
- `Biombo/Model/`: pure domain primitives from `docs/PRODUCT.md` §4–§10 (Layer, ReportKind and its rules, Place, Report, Freshness, Verification, OutageArea, CrisisState, WatchedPlace, Progress, OfficialNotice). Types are `nonisolated`, with no SwiftUI.
- `Biombo/Data/`: `PlacesProviding`, which is the seam for the future backend client, and `SampleData*` fixtures pinned to `SampleData.now`.
- `Biombo/Answers/`: pure derivations from a snapshot, and the only freshness gate the UI reads. `AnswerResolver` gives one current answer per place and layer, plus drawable outage areas. `NearbyBuilder` builds "Cerca de ti": the answer facts, official cards and sections with row caps. `LayerDigest` gives the Capas mini-answers, and `MapContent`/`PinClusterer` handle zoom tiers and clustering. `HomeDigest` bundles all of it once, for the map, the sheet and Capas. Everything is `nonisolated`, and the localized words live in `Design/*+Appearance.swift`.
  `AvailabilityBuilder` builds "Gasolina y planta" (fuel per station, generators), which the crisis answer reuses; `SourceMix`/`AreaTimeline` describe who says an area is out; `WatchStatusBuilder` answers watched places from the same digest.
- `Biombo/State/`: `@Observable` stores. They are pure: views fetch data and hand it to the store. App-scoped ones (`WatchStore`, `DeviceStore` for connection and outbox, `SampleSwitches`) are injected with `.environment`; watched places are saved by the app through `WatchedPlacesStorage`, never by the store.
- **Crisis:** `CrisisRules.step` (Model) is the trigger model from PRODUCT.md §8; on sample data crisis comes from the snapshot variant (`-crisis`, or Ajustes › Muestra in debug builds). Offline, `RootView` ages the snapshot to the device clock (`DeviceStore.state(lastSyncedAt:)`, then `PlacesSnapshot.aged(to:)`) so it follows the usual freshness rules. Crisis and connection show as `StatusPills` over the map, never above the answer.
- **Contributing:** `ReportContextBuilder` (Answers) decides what Quick Report is about (snap radii in `ContributionRules`), `ReportVocabulary` its verbs, `ReportFiling` new vs. confirmation and the `ReportReceipt` sent state. `Features/Report/ReportSender` routes a report (outbox offline, held price, confirmation) into `ContributionStore` (history, votes, owned places; the app saves its `ledger` via `DeviceStorage.contributions`) and `DeviceStore` (outbox, saved via `DeviceStorage.outbox`; `RootView` replays it on reconnect through `ReportSender.replay`, so replays are filed like fresh reports). Deshacer restores the vote a reply replaced, never just deletes it. `LocalContributions` folds this device's reports, votes and owner seals into the snapshot so they follow the usual rules; `VerificationRules.confirmingNeighbours` is the one neighbour count. `ProgressLedger` turns outcomes into points; `OwnerClaimFlow`/`OwnerTextFilter` (Model) drive owner verification behind the `OwnerVerifying` seam (sample code 2468). Services behind seams (`\.ownerVerifier`, `\.priceSignReader`) are injected by `BiomboApp` through the environment (`App/Services.swift`); no view builds a sample one. There is no `PriceSignReading` yet, so price photos are evidence only.
- **First run and routes:** `RootView` shows `Features/Onboarding` (3 steps, `OnboardingFlow` in State) until `Preferences.hasOnboarded`; the chosen layers are a `LayerChoice` (Model, `@AppStorage`) that Capas keeps updating and crisis ignores. Anything outside home that wants a screen (a Control, a widget tap, onboarding's "Vigilar un lugar") goes through `AppRouter` (State) → `HomeRouting`. Controls and widgets leave a `PendingScreen` in the App Group; `BiomboApp` moves it into the router on activation.
- **Siri (`Biombo/Intents/`):** App Intents run in the app process over the live stores through `IntentContext` (`@Dependency`, registered in `BiomboApp.init`). Report by voice (`ReportConditionIntent`: `VoiceReport` → confirmation snippet → outbox, filed by `RootView`'s replay), `CheckConditionIntent` (`ConditionAnswer`), `CheckWatchedPlaceIntent`, `CheckFuelIntent` (`GasPick`), `WatchPlaceIntent`; `BiomboShortcuts` has the phrases (ES in code, EN in `Resources/AppShortcuts.xcstrings`). Spoken words are in `Design/Voice+Appearance.swift`. Keep testable logic in static funcs; `perform()` can't be unit-tested. The on-device model (`Features/Intelligence/OnDeviceSummarizer`) is used only for the labelled "Resumen automático" on the watch list, behind `SummaryGate`.
- **Widgets and Controls (`BiomboWidgets/`, a WidgetKit extension):** "Gasolina cerca" and a watched place, plus the Reportar / "No hay luz aquí" / "Volvió la luz" Controls. The extension never loads places: `Features/SystemSurfaces/WidgetPublishing` writes a `WidgetSnapshot` (words already localized, each glance with a device-clock `freshUntil`) to the App Group `group.com.418-studio.biombo` whenever it changes, and the widget says "Sin reportes recientes" past it. `BiomboShared/` (App Group snapshot, `BiomboScreen`/`OpenBiomboScreenIntent`, the palette) is compiled into both targets, so its code is explicitly `nonisolated`; the extension has no default MainActor isolation and its own `Localizable.xcstrings`.
- `Biombo/Features/<Area>/`: screens, one folder per area. `Place/` is the detail sheet for every layer, built from `PlaceDetailBuilder` (Answers) once per selection: `PriceLadder` (DACO comparison), `PriceTrend`, `ConfirmQuestion`/`ConfirmStep`, `MapsHandOff` ("Abrir en…").
- `Biombo/Design/`: the Theme (crisis tint swap), `TextRole` type roles (serif for place names, rounded tabular numerals), spacing and size metrics, and the symbol-plus-word appearance of layers and labels. Reusable components go here.
- `Biombo/Resources/`: the asset catalog, `Localizable.xcstrings`, `InfoPlist.xcstrings` and `AppShortcuts.xcstrings` (Siri phrases, keyed by each shortcut's first Spanish phrase).

**Project:** `Biombo.xcodeproj` is generated by `ruby scripts/create_biombo_xcodeproj.rb`, run from the repo root (targets Biombo, BiomboWidgets embedded in it, BiomboTests; entitlements in `ios/Biombo-Support/` and `ios/BiomboWidgets-Support/`). It uses synchronized folders, so new files need no project edit. Change project settings in the script, not only in Xcode.

**Palette:** the colours live only in `ios/BiomboShared/Palette.xcassets` (shared with the widget extension), as `*.colorset` with Any, Dark and High Contrast variants. Read them as `Color(.ink)`. Swift colour extensions are off because names like `tint` and `fill` clash with SwiftUI. To regenerate, run `python3 ios/scripts/generate_palette.py` (source: `ios/scripts/palette.json`). Add `--import-tokens <tokens.json>` to refresh from a design export. Don't hand-edit the colour sets. No design docs in the repo (see `docs/DESIGN.md`).

**Art:** postcard plates, ink vignettes and the painted island are PNGs in `Assets.xcassets/Art`, rendered from the design canvas boards by `python3 ios/scripts/render_art.py --boards <canvas/project>` (headless Chromium; light, dark and line-only high-contrast variants). The island's lon/lat bounds it prints must match `PaintedGround`. Don't hand-edit these image sets.

**Info.plist:** generated from build settings, plus `ios/Biombo-Support/Info.plist` for keys with no build setting (`LSApplicationQueriesSchemes` for Google Maps and Waze).

**Launch arguments:** `-skipOnboarding` or `-onboarding` to skip or replay the first run; `-crisis` for crisis mode; `-offline` or `-weakSignal` for the connection; `-sampleWatches` to start with the sample watch list; `-sampleOutbox` to refill the outbox; `-sampleContributions` to reset Tu aporte, votes and seals to the sample device's; `-vantage 18.1401,-66.2661` to stand at Farmacia del Pueblo and claim it; `-vantage lat,lon` to move "cerca" (confirming needs you within 300 m, e.g. `-vantage 18.3755,-66.1190` beside Puma Los Filtros). Debug builds also have Ajustes › Muestra.

**Build and test.** Run only one `xcodebuild` at a time. Use the simulator UDID, because `name=iPhone 17` is ambiguous once iOS 27 runtimes exist:
```
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild build -project apps/biombo/ios/Biombo.xcodeproj -scheme Biombo -destination 'id=<iPhone 17 UDID>'
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test  -project apps/biombo/ios/Biombo.xcodeproj -scheme Biombo -destination 'id=<iPhone 17 UDID>'
```
Tests use Swift Testing, in `BiomboTests/`. Judge freshness against a fixed `now`, never `Date()`.

**Rules**
- Spanish is the source language of the String Catalog, with English translations. Use full-sentence templates with plural variations and never concatenate strings.
- Never show colour alone: status, layer and verification each carry a symbol and a word. Support Dynamic Type through the AX sizes, 44pt targets, VoiceOver labels, Reduce Motion, and Increase Contrast through the asset-catalog variants.
- Every rule number is *proposed* in PRODUCT.md, so keep each one in a single named place (`ReportKind+Rules`, `FreshnessPolicy`, `VerificationRules`).
- Keep files under ~250 lines. Never use `nonisolated(unsafe)` or `@unchecked Sendable`.
- Copy Checkpoint's patterns and never import its code.

## Identity

- **Bundle ID:** `com.418-studio.biombo`
- **Languages:** Spanish-first, with an English parallel.
