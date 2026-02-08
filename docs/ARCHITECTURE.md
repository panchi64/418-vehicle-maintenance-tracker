# Architecture Reference

Detailed architecture reference for the Checkpoint iOS app. For development guidance, see CLAUDE.md files.

## Project Structure

```
checkpoint-app/
├── checkpoint/
│   ├── Models/           # SwiftData entities
│   ├── Views/
│   │   ├── Tabs/         # Home, Services, Costs tabs
│   │   ├── Vehicle/      # Vehicle CRUD views
│   │   ├── Service/      # Service CRUD views
│   │   ├── Settings/     # Settings views
│   │   ├── Onboarding/   # Guided intro, tour overlay, get started card
│   │   └── Components/   # Reusable UI components
│   │       ├── Attachments/  # Photo/document handling
│   │       ├── Camera/       # Vision framework OCR views
│   │       ├── Cards/        # Dashboard cards
│   │       ├── Inputs/       # Form input controls
│   │       ├── Lists/        # List/timeline components
│   │       ├── Navigation/   # Navigation & structural
│   │       └── Sync/         # Data sync UI
│   ├── DesignSystem/     # Theme, Typography, Spacing tokens
│   ├── Services/         # Business logic services
│   │   ├── Analytics/        # PostHog analytics
│   │   ├── Export/           # PDF generation
│   │   ├── Import/           # CSV import (Fuelly, Drivvo, Simply Auto)
│   │   ├── Notifications/    # Local notification management
│   │   ├── OCR/              # Vision framework services
│   │   ├── Siri/             # Siri voice commands & Shortcuts
│   │   ├── Sync/             # iCloud & data sync
│   │   ├── Utilities/        # Single-purpose services
│   │   ├── WatchConnectivity/ # iPhone-side WCSession delegate
│   │   └── Widget/           # Widget data sharing
│   ├── State/            # AppState (@Observable)
│   ├── Utilities/        # Formatters, Settings, helpers
│   └── Resources/        # ServicePresets.json
├── CheckpointWatch/      # watchOS app (services, mileage update, mark done)
├── CheckpointWatchWidget/ # watchOS widget extension (complications)
├── CheckpointWatchTests/ # watchOS unit tests
├── CheckpointWidget/     # WidgetKit extension
│   └── Shared/           # Shared types (colors, settings, pending completions)
├── checkpointTests/      # Unit tests
└── checkpointUITests/    # UI tests
```

## Data Models

### Vehicle
- `name`, `make`, `model`, `year`, `currentMileage`, `vin`
- Has many: services, serviceLogs, mileageSnapshots
- Key computed properties: `effectiveMileage`, `dailyMilesPace`, `paceConfidence`, `allUpcomingItems`, `nextUpItem`

### Service
- `name`, `dueDate`, `dueMileage`, `lastPerformed`, `lastMileage`
- `intervalMonths`, `intervalMiles`, `notificationID`
- Computed `status(currentMileage:)` returns `.overdue`, `.dueSoon`, `.good`, `.neutral`
- Computed `urgencyScore` for sorting by urgency

### ServiceLog
- Records completed service instances
- `performedDate`, `mileageAtService`, `cost`, `notes`
- Links to both `Service` and `Vehicle`

### MileageSnapshot
- Mileage reading for pace calculation
- EWMA (Exponentially Weighted Moving Average) with 30-day half-life

### CostCategory
Enum for categorizing service costs: `.maintenance`, `.repair`, `.upgrade`, `.inspection`, `.other`

### MileageSource
Enum for tracking how mileage was recorded: `.manual`, `.serviceCompletion`

## Onboarding

State machine in `OnboardingState` (`@Observable @MainActor`):
- **Phases:** `.intro` → `.tour(step:)` → `.tourTransition(toStep:)` → `.getStarted` → `.completed`
- **Phase 1 — Intro:** `OnboardingIntroView` as `.fullScreenCover`, 2 paged screens
- **Phase 2 — Tour:** `OnboardingTourOverlay` overlay on real UI with dummy data, 4 steps switching tabs
- **Phase 3 — Get Started:** `OnboardingGetStartedView` with VIN input, manual entry, skip
- **Persistence:** `@AppStorage("hasCompletedOnboarding")`
- **Sample data:** Seeded during tour, cleared on skip/complete

## Service Inventory

### Analytics/ (PostHog Integration)
- `AnalyticsService` — `@Observable @MainActor` singleton wrapping PostHog SDK
- `AnalyticsEvent` — Type-safe enum with `.name` and `.properties` (categorical/boolean only, no PII)
- `AnalyticsScreenTracker` — `.trackScreen(.home)` ViewModifier
- Configuration via Info.plist keys `POSTHOG_API_KEY` and `POSTHOG_HOST` (build-time via xcconfig)
- Opt-out model (enabled by default), toggle in Settings

### Export/ServiceHistoryPDFService
- Generates PDF with vehicle service history
- Brutalist aesthetic: monospace fonts, uppercase labels, 2px borders, amber accent
- US Letter format, multi-page support

### Import/CSVImportService
- Auto-detects CSV format from column headers (Fuelly, Drivvo, Simply Auto)
- Maps competitor service types to Checkpoint presets
- Returns import summary with count of imported/skipped records

### Notifications/ (Modular Architecture)
- **Core:** `NotificationService` — `@Observable @MainActor` singleton for authorization, categories
- **Schedulers (stateless structs with static methods):**
  - `ServiceNotificationScheduler` — Service due notifications (30/7/1/0 days before)
  - `MileageReminderScheduler` — Bi-weekly mileage update reminders
  - `MarbeteNotificationScheduler` — PR vehicle registration expiration
  - `YearlyRoundupScheduler` — Annual cost summary (January 2nd)
- **Categories:** `SERVICE_DUE`, `MILEAGE_REMINDER`, `MARBETE_DUE`, `YEARLY_ROUNDUP`

### OCR/
- `OdometerOCRService` — Vision framework OCR for odometer displays (preprocessing → VNRecognizeTextRequest → number extraction)
- `VINOCRService` — 17-character VIN validation, handles common OCR mistakes (0/O, 1/I)
- `OdometerImagePreprocessor` — Grayscale, contrast enhancement, adaptive thresholding

### Sync/
- `CloudSyncStatusService` — Monitors iCloud sync via NSPersistentCloudKitContainer events
- `SyncStatusService` — UI-facing sync status (`.synced`, `.syncing`, `.error`, `.offline`)
- `DataMigrationService` — Local to iCloud migration, schema upgrades

### Utilities/
- `NHTSAService` — VIN decoding and recall alerts via NHTSA API
- `AppIconService` — Alternate app icon management
- `PresetDataService` — Loads bundled service presets from JSON

### Widget/WidgetDataService
- Shares data with widget extension via App Groups (`group.com.418-studio.checkpoint.shared`)
- Data flow: App → JSON → shared UserDefaults → Widget reads → `WidgetCenter.reloadAllTimelines()`

### WatchConnectivity/WatchSessionService
- `@Observable @MainActor` singleton with WCSessionDelegate
- **Outgoing (iPhone → Watch):** `sendVehicleData()` via `WCSession.updateApplicationContext()`
- **Incoming (Watch → iPhone):** `handleMileageUpdate()`, `handleMarkServiceDone()`
- Watch App Group: `group.com.418-studio.checkpoint.watch`

## Widget Extension

### Widget Sizes
| Size | Content | Layout |
|------|---------|--------|
| Small | Next 1 service | Single card |
| Medium | Next 2-3 services | Horizontal list with interactive Done button |

### Key Types
- `ServiceEntry` — Timeline entry with vehicleName, currentMileage, services[]
- `WidgetService` — Service data optimized for widget display (name, status, dueDescription)
- `WidgetServiceStatus` — Mirrors main app's ServiceStatus (overdue, dueSoon, good, neutral)
- `VehicleEntity` / `VehicleEntityQuery` — App Entity for vehicle selection in widget configuration
- `MarkServiceDoneIntent` — App Intent for interactive "Done" button
- `PendingWidgetCompletion` — Codable struct queued in shared UserDefaults

### Widget Colors
```swift
struct WidgetColors {
    static let statusOverdue = Color.red
    static let statusDueSoon = Color.yellow
    static let statusGood = Color.green
    static let statusNeutral = Color.gray
}
```

## Apple Watch App (CheckpointWatch)

- **Min watchOS:** 10.0
- **Data sync:** WatchConnectivity (`updateApplicationContext` iPhone→Watch, `sendMessage`/`transferUserInfo` Watch→iPhone)
- **Watch App Group:** `group.com.418-studio.checkpoint.watch` (separate from iPhone App Group)
- **No SwiftData on Watch** — lightweight JSON in UserDefaults, iPhone is source of truth
- **Screens:** Services list, mileage update (digital crown), mark service done
- **Complications:** Circular, rectangular, inline, corner (all `.accessory*` families)

## View Components

### Components/Attachments/
| Component | Purpose |
|-----------|---------|
| `AttachmentGrid.swift` | Grid display of service log attachments |
| `AttachmentPicker.swift` | Photo picker with camera/library options |
| `AttachmentThumbnail.swift` | Individual attachment thumbnail |

### Components/Camera/
| Component | Purpose |
|-----------|---------|
| `ConfidenceIndicator.swift` | OCR confidence level display |
| `OCRConfirmationView.swift` | Confirm/edit OCR results |
| `OCRProcessingIndicator.swift` | Processing state during OCR |
| `OdometerCameraView.swift` | Camera viewfinder for odometer |
| `OdometerCaptureView.swift` | Full capture flow with guidance |

### Components/Cards/
| Component | Purpose |
|-----------|---------|
| `CategoryBreakdownCard.swift` | Cost breakdown by category |
| `CostSummaryCard.swift` | Total spent hero card |
| `CumulativeCostChartCard.swift` | Area chart of cumulative spending |
| `MonthlyTrendChartCard.swift` | Vertical bar chart of monthly spending |
| `NextUpCard.swift` | Hero card for most urgent service |
| `QuickMileageUpdateCard.swift` | Inline mileage entry card |
| `QuickSpecsCard.swift` | Vehicle specs display |
| `QuickStatsBar.swift` | Summary statistics bar |
| `RecallAlertCard.swift` | NHTSA recall warning |
| `StatsCard.swift` | Compact stat display |
| `YearlyCostRoundupCard.swift` | Annual cost summary |

### Components/Inputs/
| Component | Purpose |
|-----------|---------|
| `ErrorMessageRow.swift` | Inline error message |
| `InstrumentSegmentedControl.swift` | Styled segmented control |
| `InstrumentTextField.swift` | Styled text field |
| `MarbetePicker.swift` | Month/year picker for PR registration |
| `MileageInputField.swift` | Formatted mileage input |
| `ServiceTypePicker.swift` | Service preset selector |

### Components/Lists/
| Component | Purpose |
|-----------|---------|
| `ExpenseRow.swift` | Service log expense item |
| `ListDivider.swift` | Consistent list divider |
| `MaintenanceTimeline.swift` | Chronological service history |
| `RecentActivityFeed.swift` | Recent actions list |
| `ServiceRow.swift` | Service list item with status |

### Components/Navigation/
| Component | Purpose |
|-----------|---------|
| `BrutalistTabBar.swift` | Custom tab bar |
| `EmptyStateView.swift` | Standardized empty state |
| `FloatingActionButton.swift` | FAB for quick add |
| `StatusDot.swift` | Colored status indicator |
| `VehicleHeader.swift` | Vehicle info header |
| `VehicleSelector.swift` | Vehicle picker button |

### Components/Sync/
| Component | Purpose |
|-----------|---------|
| `ConflictResolutionView.swift` | iCloud conflict resolution UI |

## Tab Architecture

```
ContentView
└── TabView (BrutalistTabBar)
    ├── HomeTab
    │   ├── VehicleHeader
    │   ├── NextUpCard
    │   ├── QuickStatsBar
    │   └── RecentActivityFeed
    ├── ServicesTab
    │   ├── VehicleHeader
    │   └── List of ServiceRow
    └── CostsTab
        ├── VehicleHeader
        ├── YearlyCostRoundupCard
        └── Cost breakdown
```

## Test Coverage

### Model Tests
- **VehicleTests** — Vehicle creation, relationships, displayName, effectiveMileage, dailyMilesPace, marbete
- **ServiceTests** — Status computation, urgency scoring, due date/mileage thresholds, edge cases
- **MileageSnapshotTests** — EWMA pace calculation, recency weighting, minimum data requirements, confidence
- **ServiceLogTests** — Log creation, relationships, attachment handling
- **ServiceAttachmentTests** — Attachment creation, thumbnail generation, MIME types
- **MarbeteTests** — Expiration date calculation, status computation, days remaining
- **CSVImportServiceTests** — Format auto-detection, row parsing, malformed data handling
- **ContextualInsightsTests** — Time/miles since last service, average cost, times serviced
- **PendingWidgetCompletionTests** — Encoding/decoding, queue/dequeue, processing
- **VINRegistrationTests** — Character count display, validation state transitions, auto-fill feedback
