# Intents — Siri, Shortcuts, Spotlight

App Intents, App Entities and Spotlight indexing. `docs/APP_INTENTS.md` (repo root) is the SDK-verified reference for what exists on which iOS version and device tier — check it (or the SDK `.swiftinterface`, or developer.apple.com) before using an App Intents API. Minimum deployment is iOS 26; anything iOS 27-only is `@available(iOS 27, *)`.

## Layout

```
Intents/
├── IntentDependencies.swift    # registers the app's ModelContainer for @Dependency
├── SpotlightIndexer.swift      # CSSearchableIndex.indexAppEntities / deleteAppEntities
├── Entities/
│   ├── ModelBackedEntity.swift # shared shape + fetch path for SwiftData-backed entities
│   ├── VehicleEntity.swift     # + VehicleEntityQuery
│   ├── ServiceEntity.swift
│   ├── ServiceLogEntity.swift
│   ├── VisitEntity.swift
│   ├── DocumentEntity.swift    # Document = ServiceAttachment; OCR text indexed
│   ├── ServicePresetEntity.swift  # PresetDataService catalog, not indexed
│   ├── IntentEnums.swift       # AppEnum conformances of the app's own enums
│   └── View+OnScreenEntity.swift  # .appEntityIdentifier wrapper for detail screens
├── CheckNextDueIntent.swift, ListUpcomingServicesIntent.swift  # read SiriDataProvider snapshots
├── UpdateMileageIntent.swift   # opens the mileage sheet prefilled
├── CheckpointShortcuts.swift   # AppShortcutsProvider (max 10 shortcuts)
├── SiriDataProvider.swift      # App Group snapshot reader (legacy read path)
└── L10n+Siri.swift             # spoken sentences, `siri.` keys
```

## Rules

- **One data path.** Intents run in the app process. Read and write through `@Dependency var container: ModelContainer` (registered by `IntentDependencies.register` at launch and again on the container swap in `checkpointApp`). Never open a second container. Only out-of-process code (widget, Controls) reads App Group snapshots.
- **Call services, not views.** Writes go through the same services the UI uses (`VehicleService`, `ServiceCompletionService`, `LoggedServiceWriter`, `MileageCommit`, …); spend figures through `CostAnalyticsService`. If an intent needs logic that lives in a view, extract it into a service first, with tests.
- **Entities are Sendable snapshots.** A `ModelBackedEntity` is built on the main actor from one model (`init(model:)`) and fetched only through `entities(ids:in:)` / `entities(matching:in:)` — queries, the indexer and tests share that path. IDs are the model's `UUID`. Queries hop to the main actor through `EntityFetch`.
- **Enums conform in place.** `CostPeriod`, `CostCategory`, `DocumentType`, `ServiceStatus` are `nonisolated` with only their L10n/theme members `@MainActor`, so they can be `AppEnum`s. Raw values are persisted by saved shortcuts — never rename one.
- **Navigation goes through `PendingRoute`.** An intent that opens the app sets `PendingRouteStore.shared.route` (`checkpoint/State/PendingRoute.swift`); `ContentView` is its one consumer. Notifications and the widget's `PendingWidgetRoute` feed the same store. **No URL schemes** (security invariant).
- **Spotlight follows data changes.** `SpotlightIndexer.scheduleReindex` runs wherever widget data refreshes (`ContentView.updateWidgetData`, `WidgetDataService`'s CloudKit remote-change pass). Don't add per-write indexing hooks.
- **Tag detail screens** with `.onScreenEntity(_:id:)` so Apple Intelligence can act on "this".

## Two `VehicleEntity` types

The app's `VehicleEntity` (here) is SwiftData-backed and indexed. The widget extension has its own snapshot-backed `VehicleEntity` in `CheckpointWidget/` for its configuration picker; it is not compiled into the app. The widget's keeps its name because saved widget configurations reference it.

## Entitlements

The main app requires the Siri entitlement in `checkpoint.entitlements`:
```xml
<key>com.apple.developer.siri</key>
<true/>
```
