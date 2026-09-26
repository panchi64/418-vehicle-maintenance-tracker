# Intents — Siri, Shortcuts, Spotlight

App Intents, App Entities and Spotlight indexing. `docs/APP_INTENTS.md` (repo root) is the SDK-verified reference for what exists on which iOS version and device tier — check it (or the SDK `.swiftinterface`, or developer.apple.com) before using an App Intents API. Minimum deployment is iOS 26; anything iOS 27-only is `@available(iOS 27, *)`.

## Layout

```
Intents/
├── IntentDependencies.swift    # registers the app's ModelContainer for @Dependency
├── IntentStore.swift           # entity → model resolution, default vehicle, commit; IntentError
├── IntentDonations.swift       # IntentDonationManager calls from the in-app save paths
├── SpotlightIndexer.swift      # CSSearchableIndex.indexAppEntities / deleteAppEntities
├── CheckpointShortcuts.swift   # AppShortcutsProvider — 9 of Apple's max 10
├── L10n+Siri.swift             # spoken sentences + snippet labels, `siri.` keys
├── Entities/                   # SwiftData-backed App Entities + AppEnum conformances
├── Mileage/                    # UpdateMileageIntent (direct write), GetMileageIntent
├── History/                    # MarkServiceDone, LogService, DeleteServiceLog + ServiceLogging
├── Schedule/                   # Add / Edit / Snooze / StopTracking / Delete service + ServiceScheduling
├── Queries/                    # CheckNextDue, ListUpcoming, ListOverdue, LastServiceQuery,
│                               #   SpendingSummary + DueServices / SpokenValue helpers
└── Snippets/                   # DueServicesSnippetIntent (+ Done button intent),
                                #   ServiceRecordSnippetIntent (confirmation), SpendingSnippetView
```

Spanish App Shortcut phrases live in `checkpoint/Resources/AppShortcuts.xcstrings`, keyed by the English phrase. Everything else is in `Localizable.xcstrings`: intent/parameter/entity labels as extracted literals, spoken sentences as manual `siri.*` keys.

## Rules

- **One data path.** Intents run in the app process. Read and write through `@Dependency var container: ModelContainer` (registered by `IntentDependencies.register` at launch and again on the container swap in `checkpointApp`). Never open a second container. Only out-of-process code (widget, Controls) reads App Group snapshots.
- **`perform()` is `@MainActor`.** Intent structs are nonisolated (the `AppIntent` protocol is), so mark `perform()` and any static helper that touches models `@MainActor`, then use `container.mainContext`.
- **Resolve and commit through `IntentStore`.** A missing vehicle parameter means the vehicle the app has selected (`IntentStore.vehicle(for:in:)`). Every write ends in `IntentStore.commit(vehicle, in:)` — derived surfaces (`DerivedSurfaces`: reminders, icon, widget), an explicit save (the process may suspend before autosave), and a Spotlight pass. Writes whose action already refreshed use `IntentStore.save`.
- **Call services, not views.** Writes go through the same code the UI uses: `LoggedServiceWriter` (fed a `ServiceLogFormModel` by `ServiceLogging`), `ServiceVisitWriter`, `ServiceCompletionService`, `MileageUpdateAction`, `Service.apply(_ ServiceEdit)`, `ServiceDeleteAction`, `ServiceLogDeleteAction`, `CostAnalyticsService`. If an intent needs logic that lives in a view, extract it into a service first, with tests.
- **Ask before the irreversible.** Deletes (`DeleteServiceIntent`, `DeleteServiceLogIntent`, voice deletes are services and logs only), Stop Tracking, Mark Done and Log Service call `requestConfirmation` before writing; Mark Done and Log Service show `ServiceRecordSnippetIntent` so a misheard value is visible. Update Mileage asks only when `MileageReadingCheck` flags the reading. Keep the write in a static function the tests can call; `perform()` itself can't pass a confirmation in a unit test.
- **Distances are spoken in the user's unit.** Convert with `DistanceSettings.shared.unit.toMiles` on the way in; format with `SpokenValue` on the way out.
- **Dialogs are whole `siri.*` sentences** built from `SpokenValue`-formatted values — never concatenated. Add EN and ES for every new key.
- **Entities are Sendable snapshots.** A `ModelBackedEntity` is built on the main actor from one model (`init(model:)`) and fetched only through `entities(ids:in:)` / `entities(matching:in:)` / `models(ids:in:)`. IDs are the model's `UUID`. Queries hop to the main actor through `EntityFetch`.
- **Enums conform in place.** `CostPeriod`, `CostCategory`, `DocumentType`, `ServiceStatus` are `nonisolated` with only their L10n/theme members `@MainActor`, so they can be `AppEnum`s. Raw values are persisted by saved shortcuts — never rename one.
- **Navigation goes through `PendingRoute`.** An intent that opens the app sets `PendingRouteStore.shared.route` (`checkpoint/State/PendingRoute.swift`); `ContentView` is its one consumer. **No URL schemes** (security invariant).
- **Snippets follow SURFACE_DOCTRINE.** One primary element per snippet (two channels, never color alone — `StatusTag` for status), theme tokens and brutalist fonts only. A snippet with buttons is a `SnippetIntent`; its buttons run hidden (`isDiscoverable = false`) intents, and the system re-runs the snippet's `perform()` afterwards.
- **Donate in-app actions only.** `IntentDonations` is called from the app's save paths (Mark Done, [+] log, Mark all done, schedule, mileage sheet). An intent Siri ran is donated by the system.
- **Spotlight follows data changes.** `SpotlightIndexer.scheduleReindex` runs wherever widget data refreshes and on `IntentStore` commits. Don't add per-write indexing hooks elsewhere.
- **Tag detail screens** with `.onScreenEntity(_:id:)` so Apple Intelligence can act on "this".

## Two `MarkServiceDone` intents, two `VehicleEntity` types

`MarkServiceDoneIntent` (here) writes directly. The widget's Done button is `WidgetMarkDoneIntent` in `CheckpointWidget/`: it runs in the widget process, queues a `PendingWidgetCompletion`, and is hidden from Shortcuts.

The app's `VehicleEntity` (here) is SwiftData-backed and indexed. The widget extension has its own snapshot-backed `VehicleEntity` in `CheckpointWidget/` for its configuration picker; it is not compiled into the app. The widget's keeps its name because saved widget configurations reference it.

## Tests

`checkpointTests/Services/Intents/IntentTestCase` registers an in-memory container as the dependency, selects one vehicle and pins miles. `runUnanswered` runs a confirming intent with no one to answer, to prove nothing is written before a yes. `AppIntentsTesting` is iOS 27-only — not used yet.

## Entitlements

The main app requires the Siri entitlement in `checkpoint.entitlements`:
```xml
<key>com.apple.developer.siri</key>
<true/>
```
