# Intents — Siri, Shortcuts, Spotlight

App Intents, App Entities and Spotlight indexing. `docs/APP_INTENTS.md` (repo root) is the SDK-verified reference for what exists on which iOS version and device tier — check it (or the SDK `.swiftinterface`, or developer.apple.com) before using an App Intents API. Minimum deployment is iOS 26; anything iOS 27-only is `@available(iOS 27, *)`.

## Layout

```
Intents/
├── IntentDependencies.swift    # registers the app's ModelContainer for @Dependency
├── IntentStore.swift           # entity → model resolution, default vehicle, commit; IntentError
├── IntentDonations.swift       # IntentDonationManager calls from the in-app save paths
├── SpotlightIndexer.swift      # CSSearchableIndex.indexAppEntities / deleteAppEntities
├── CheckpointShortcuts.swift   # AppShortcutsProvider — 10 of Apple's max 10 (a new one displaces one)
├── L10n+Siri.swift             # spoken sentences + snippet labels, `siri.` keys
├── Entities/                   # SwiftData-backed App Entities + AppEnum conformances
├── Mileage/                    # UpdateMileageIntent (direct write), GetMileageIntent
├── Vehicles/                   # AddVehicle (VIN via NHTSAClient, starter schedule), SwitchVehicle,
│                               #   GetVehicleDetails (+ VehicleDetail enum), RenewMarbete, CheckRecalls
├── Documents/                  # AddDocument, FindDocument, DocumentImport (image/PDF → document),
│                               #   DocumentEntity+Transfer (Transferable export)
├── History/                    # MarkServiceDone, LogService, LogReceipt, DeleteServiceLog,
│                               #   ExportServiceHistory + ServiceLogging
├── Schedule/                   # Add / Edit / Snooze / StopTracking / Delete service + ServiceScheduling
├── Queries/                    # CheckNextDue, ListUpcoming (not an App Shortcut), ListOverdue, LastServiceQuery,
│                               #   SpendingSummary + DueServices / SpokenValue helpers
├── Snippets/                   # DueServicesSnippetIntent (+ Done button intent),
│                               #   ServiceRecordSnippetIntent (confirmation), SpendingSnippetView,
│                               #   RecallsSnippetView, DocumentSnippetView
└── Schema/                     # Apple Intelligence schema types (docs/APP_INTENTS.md has the map)
    ├── Reminders/              # iOS 27: service = reminder, vehicle = list; ReminderMapping;
    │                           #   placeholder location-trigger/section types the processor demands
    ├── Photos/                 # iOS 27: image document = asset, vehicle = album; open + save photos
    ├── Files/                  # iOS 18 schema (ships on 26): every document = file; open file
    ├── System/                 # search (26) / searchInApp (27), .system.open per entity, EntityRoutes
    └── VisualIntelligence/     # IntentValueQuery over SemanticContentDescriptor → VisualCaptureEntity
                                #   (log receipt / update mileage / add vehicle by VIN), its OpenIntent,
                                #   .visualIntelligence.semanticContentSearch; VisualCaptureStore (memory)
```

Receipt reading itself lives in `Services/Intelligence/` (its own CLAUDE.md).

Notification entity tags live with the notifications (`Services/Notifications/NotificationEntityTags.swift`).

Spanish App Shortcut phrases live in `checkpoint/Resources/AppShortcuts.xcstrings`, keyed by the English phrase. Everything else is in `Localizable.xcstrings`: intent/parameter/entity labels as extracted literals, spoken sentences as manual `siri.*` keys (accessors in `L10n+Siri`, `Vehicles/L10n+SiriVehicles`, `Documents/L10n+SiriDocuments`).

The Controls (Update Mileage, Scan Receipt, Log Service) live in `CheckpointWidget/CheckpointControls.swift`; their `OpenCheckpointScreenIntent` is in the shared `PendingWidgetRoute.swift`. The in-app Siri tips are `Views/Components/Cards/ScreenSiriTip.swift`.

## Rules

- **One data path.** Intents run in the app process. Read and write through `@Dependency var container: ModelContainer` (registered by `IntentDependencies.register` at launch and again on the container swap in `checkpointApp`). Never open a second container. Only out-of-process code (widget, Controls) reads App Group snapshots.
- **`perform()` is `@MainActor`.** Intent structs are nonisolated (the `AppIntent` protocol is), so mark `perform()` and any static helper that touches models `@MainActor`, then use `container.mainContext`.
- **Resolve and commit through `IntentStore`.** A missing vehicle parameter means the vehicle the app has selected (`IntentStore.vehicle(for:in:)`). Every write ends in `IntentStore.commit(vehicle, in:)` — derived surfaces (`DerivedSurfaces`: reminders, icon, widget), an explicit save (the process may suspend before autosave), and a Spotlight pass. Writes whose action already refreshed use `IntentStore.save`.
- **Call services, not views.** Writes go through the same code the UI uses: `LoggedServiceWriter` (fed a `ServiceLogFormModel` by `ServiceLogging`), `ServiceVisitWriter`, `ServiceCompletionService`, `MileageUpdateAction`, `Service.apply(_ ServiceEdit)`, `ServiceDeleteAction`, `ServiceLogDeleteAction`, `CostAnalyticsService`. If an intent needs logic that lives in a view, extract it into a service first, with tests.
- **Ask before the irreversible.** Deletes (`DeleteServiceIntent`, `DeleteServiceLogIntent`, voice deletes are services and logs only — no vehicle or document deletes), Stop Tracking, Renew Marbete, Mark Done and Log Service — and their schema twins, Update Reminder when it completes and Delete Reminders — call `requestConfirmation` before writing; Mark Done and Log Service show `ServiceRecordSnippetIntent` so a misheard value is visible. Update Mileage asks only when `MileageReadingCheck` flags the reading. Keep the write in a static function the tests can call; `perform()` itself can't pass a confirmation in a unit test.
- **Distances are spoken in the user's unit.** Convert with `DistanceSettings.shared.unit.toMiles` on the way in; format with `SpokenValue` on the way out.
- **Dialogs are whole `siri.*` sentences** built from `SpokenValue`-formatted values — never concatenated. Add EN and ES for every new key.
- **Entities are Sendable snapshots.** A `ModelSnapshotEntity` is built on the main actor from one model (`init(model:)`) and fetched only through `entities(ids:in:)` / `entities(matching:in:)` / `models(ids:in:)`. IDs are the model's `UUID`. Queries hop to the main actor through `EntityFetch`. `ModelBackedEntity` adds `IndexedEntity`: those are the ones Spotlight indexes.
- **Schema types are separate types over the same models.** A schema macro can't be applied to a type that exists on iOS 26, so each iOS 27 schema entity is its own `@available(iOS 27, *)` `ModelSnapshotEntity` whose `models(ids:in:)` delegates to the iOS 26 entity's (same UUID for the same record). Schema types aren't indexed, which would list every record twice. A schema intent that duplicates an iOS 26 intent sets `isAssistantOnly = true`. Leave unsupported schema properties `nil`, but declare them: the metadata processor rejects a schema type missing any (see docs/APP_INTENTS.md).
- **Opening goes through `EntityRoutes`.** Every open and search intent resolves an ID to a `PendingRoute` there, so a record opens on the same screen whichever entity type named it.
- **Enums conform in place.** `CostPeriod`, `CostCategory`, `DocumentType`, `ServiceStatus` are `nonisolated` with only their L10n/theme members `@MainActor`, so they can be `AppEnum`s. Raw values are persisted by saved shortcuts — never rename one.
- **Navigation goes through `PendingRoute`.** An intent that opens the app sets `PendingRouteStore.shared.route` (`checkpoint/State/PendingRoute.swift`); `ContentView` is its one consumer. **No URL schemes** (security invariant).
- **Snippets follow SURFACE_DOCTRINE.** One primary element per snippet (two channels, never color alone — `StatusTag` for status), theme tokens and brutalist fonts only. A snippet with buttons is a `SnippetIntent`; its buttons run hidden (`isDiscoverable = false`) intents, and the system re-runs the snippet's `perform()` afterwards.
- **Donate in-app actions only.** `IntentDonations` is called from the app's save paths (Mark Done, [+] log, Mark all done, schedule, mileage sheet, Add Vehicle, a document added to the library, Mark Renewed). An intent Siri ran is donated by the system.
- **Spotlight follows data changes.** `SpotlightIndexer.scheduleReindex` runs wherever widget data refreshes and on `IntentStore` commits. Don't add per-write indexing hooks elsewhere.
- **Tag detail screens** with `.onScreenEntity(_:id:)` so Apple Intelligence can act on "this".
- **Receipts log like speech.** `LogReceiptIntent` reads the file (`ReceiptExtractionService`, swappable via `makeExtractor` for tests), shows `ServiceRecordSnippetIntent`, and writes through `ServiceLogging` with an `Occasion` that carries the shop, line items and the receipt attachment. Shop or line items → a visit (`Occasion.needsVisit`); the total counts once.
- **Network through `NHTSAClient`.** Add Vehicle (VIN → `VehicleService.fillingFromVIN`) and Check Recalls reach NHTSA through a swappable static `nhtsa` client (`NHTSAService.shared` by default); tests stub it. A failed VIN lookup never blocks: Siri asks for the make instead.
- **A question that can be declined uses `requestChoice`.** `requestConfirmation` throws on "no"; Add Vehicle's "with the usual schedule?" and Check Recalls' "add as planned?" are two real options (iOS 26 `requestChoice`), and neither option is `.cancel` (that one throws). Add Vehicle asks before it writes, so dismissing the question saves nothing.
- **Files out are `IntentFile`s or `Transferable` entities.** Export Service History returns the PDF; `DocumentEntity` exports its bytes (`DocumentEntity+Transfer`, read through `IntentDependencies.container` because the system calls it outside any perform flow), so Find Document chains into Share/Mail.
- **One `OpenIntent` per target type.** The metadata processor rejects two ("OpenIntent targets should be unique"). A second way to open the same entity is a plain `.foreground` intent (`SwitchVehicleIntent`).
- **Siri tips need App Shortcuts.** `SiriTipView` shows nothing for an intent outside `CheckpointShortcuts`; the tips use Check Next Due, Update Mileage, Spending Summary and Find Document.
- **Visual Intelligence opens, never writes.** The value query only classifies and keeps captures in memory (`VisualCaptureStore`, 30 min); tapping a result routes (`.logReceipt`, `.mileageReading`, `.addVehicle`) to the screen that asks. The app may have only one `IntentValueQuery` over `SemanticContentDescriptor`. The Simulator SDK has no VisualIntelligence module, so the query and schema intent sit behind `#if canImport(VisualIntelligence)`.

## Two `MarkServiceDone` intents, two `VehicleEntity` types

`MarkServiceDoneIntent` (here) writes directly. The widget's Done button is `WidgetMarkDoneIntent` in `CheckpointWidget/`: it runs in the widget process, queues a `PendingWidgetCompletion`, and is hidden from Shortcuts.

The app's `VehicleEntity` (here) is SwiftData-backed and indexed. The widget extension has its own snapshot-backed `VehicleEntity` in `CheckpointWidget/` for its configuration picker; it is not compiled into the app. The widget's keeps its name because saved widget configurations reference it.

## Tests

`checkpointTests/Services/Intents/IntentTestCase` registers an in-memory container (CloudKit off — with it on, the iOS 27 simulator traps on the first save) as the dependency, selects one vehicle and pins miles. `runUnanswered` runs a confirming intent with no one to answer, to prove nothing is written before a yes. `StubNHTSA` (in `VehicleIntentTests`) stands in for the network: hand it to `VehicleService.fillingFromVIN`, `AddVehicleIntent.identify`, `CheckRecallsIntent.openRecalls`, or set `CheckRecallsIntent.nhtsa` / `AddVehicleIntent.nhtsa` (and restore it). iOS 27 schema tests skip below 27; run them on an iOS 27 simulator too.

`AppIntentsTesting` (iOS 27) can't run in this unit-test target. It drives the intents out of process, so it needs a UI-testing target that launches a team-signed app. Not set up yet; see docs/APP_INTENTS.md.

## Entitlements

The main app requires the Siri entitlement in `checkpoint.entitlements`:
```xml
<key>com.apple.developer.siri</key>
<true/>
```
