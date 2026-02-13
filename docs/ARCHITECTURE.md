# Architecture Reference

Detailed architecture reference for the Checkpoint iOS app. For development guidance, see CLAUDE.md files.

## Project Structure

```
checkpoint-app/
├── checkpoint/
│   ├── ContentView.swift           # Root view with TabView
│   ├── ContentView+Helpers.swift   # Sheet presentation & helper methods
│   ├── Models/                     # SwiftData entities & enums
│   │   ├── Vehicle.swift
│   │   ├── Service.swift
│   │   ├── ServiceLog.swift
│   │   ├── ServiceAttachment.swift
│   │   ├── MileageSnapshot.swift
│   │   ├── ServicePreset.swift
│   │   ├── CostCategory.swift
│   │   ├── UpcomingItem.swift          # Protocol for unified urgency sorting
│   │   ├── ServiceCluster.swift        # Service bundling model
│   │   ├── ClimateZone.swift           # Climate zone enum for seasonal reminders
│   │   └── SeasonalReminder.swift      # Seasonal maintenance reminder definitions
│   ├── Views/
│   │   ├── Tabs/
│   │   │   ├── HomeTab.swift
│   │   │   ├── HomeTab+Helpers.swift       # Helper methods extracted from HomeTab
│   │   │   ├── HomeTab+EmptyStates.swift   # Empty state views for HomeTab
│   │   │   ├── ServicesTab.swift
│   │   │   ├── CostsTab.swift
│   │   │   └── CostsTab+Analytics.swift
│   │   ├── Vehicle/
│   │   │   ├── AddVehicleView.swift
│   │   │   ├── EditVehicleView.swift
│   │   │   ├── EditVehicleVINSection.swift      # VIN input section extracted from EditVehicleView
│   │   │   ├── EditVehicleOdometerSection.swift  # Odometer section extracted from EditVehicleView
│   │   │   └── VehiclePickerSheet.swift
│   │   ├── Service/
│   │   │   ├── AddServiceView.swift
│   │   │   ├── EditServiceView.swift
│   │   │   ├── ServiceDetailView.swift
│   │   │   ├── ServiceLogDetailView.swift
│   │   │   ├── EditServiceLogView.swift
│   │   │   ├── MarkServiceDoneSheet.swift
│   │   │   ├── MarkClusterDoneSheet.swift
│   │   │   └── ServiceClusterDetailSheet.swift
│   │   ├── Settings/
│   │   │   ├── SettingsView.swift
│   │   │   ├── SeasonalRemindersToggle.swift    # Extracted setting toggle
│   │   │   ├── DistanceUnitPickerView.swift     # Extracted setting picker
│   │   │   ├── AppIconToggle.swift              # Extracted setting toggle
│   │   │   ├── ServiceBundlingToggle.swift      # Extracted setting toggle
│   │   │   ├── MileageEstimatesToggle.swift     # Extracted setting toggle
│   │   │   ├── ClimateZonePickerView.swift
│   │   │   ├── ClusteringMileageWindowPicker.swift
│   │   │   ├── ClusteringDaysWindowPicker.swift
│   │   │   ├── DueSoonDaysThresholdPicker.swift
│   │   │   ├── DueSoonMileageThresholdPicker.swift
│   │   │   ├── ThemePickerView.swift
│   │   │   ├── ThemePreviewCard.swift
│   │   │   ├── SyncSettingsSection.swift
│   │   │   ├── AnalyticsSettingsSection.swift
│   │   │   ├── TipJarView.swift
│   │   │   ├── CSVImportView.swift
│   │   │   └── CSVImport/                      # Multi-step CSV import flow
│   │   │       ├── CSVImportPickFileStep.swift
│   │   │       ├── CSVImportConfigureStep.swift
│   │   │       ├── CSVImportPreviewStep.swift
│   │   │       └── CSVImportSuccessStep.swift
│   │   ├── Onboarding/
│   │   │   ├── OnboardingIntroView.swift
│   │   │   ├── OnboardingTourOverlay.swift
│   │   │   ├── OnboardingTourTransitionCard.swift
│   │   │   └── OnboardingGetStartedView.swift
│   │   └── Components/
│   │       ├── Attachments/    # Photo/document handling
│   │       ├── Camera/         # Vision framework OCR views
│   │       ├── Cards/          # Dashboard cards
│   │       ├── Export/         # Share sheet & export options
│   │       ├── Feedback/       # Toasts & feature hints
│   │       ├── Inputs/         # Form input controls
│   │       ├── Lists/          # List/timeline components
│   │       └── Navigation/     # Navigation & structural
│   ├── DesignSystem/
│   │   ├── Theme.swift             # Color tokens
│   │   ├── ThemeDefinition.swift   # Theme definitions (colors, names)
│   │   ├── ThemeManager.swift      # Theme selection & persistence
│   │   ├── Typography.swift        # Font tokens
│   │   ├── Spacing.swift           # Spacing tokens
│   │   ├── BrutalistChartStyle.swift  # Chart styling constants
│   │   ├── TappableCardModifier.swift # Card interaction modifier
│   │   └── TouchTarget.swift       # Minimum touch target sizes
│   ├── Extensions/
│   │   ├── Color+Hex.swift             # Color hex string conversion
│   │   └── Array+ServiceFiltering.swift # .overdue(), .dueSoon(), .good() filtering
│   ├── Services/
│   │   ├── Analytics/        # PostHog analytics
│   │   ├── Export/           # PDF generation
│   │   ├── Import/           # CSV import (Fuelly, Drivvo, Simply Auto)
│   │   ├── Notifications/    # Local notification management
│   │   ├── OCR/              # Vision framework services
│   │   ├── Siri/             # Siri voice commands & Shortcuts
│   │   ├── StoreKit/         # StoreKit 2 purchase engine
│   │   ├── Sync/             # iCloud & data sync
│   │   ├── Utilities/        # Single-purpose services
│   │   ├── WatchConnectivity/ # iPhone-side WCSession delegate
│   │   └── Widget/           # Widget data sharing
│   ├── State/               # AppState (@Observable)
│   ├── Utilities/           # Formatters, Settings, helpers, AppGroupConstants
│   └── Resources/           # ServicePresets.json
├── CheckpointWatch/         # watchOS app
│   ├── CheckpointWatchApp.swift
│   ├── ContentView.swift
│   ├── DesignSystem/
│   │   └── WatchDesignTokens.swift
│   ├── Models/
│   │   ├── WatchServiceData.swift
│   │   └── WatchDataStore.swift
│   ├── Services/
│   │   └── WatchConnectivityService.swift
│   └── Views/
│       ├── ServicesListView.swift
│       ├── ServiceRowView.swift
│       ├── MileageUpdateView.swift
│       └── MarkServiceDoneView.swift
├── CheckpointWatchWidget/   # watchOS widget extension (complications)
│   ├── CheckpointWatchWidgetBundle.swift
│   ├── CheckpointWatchWidget.swift
│   ├── WatchWidgetProvider.swift
│   ├── Shared/
│   │   └── WatchWidgetColors.swift
│   └── Views/
│       ├── WatchCircularView.swift
│       ├── WatchRectangularView.swift
│       ├── WatchInlineView.swift
│       └── WatchCornerView.swift
├── CheckpointWatchTests/    # watchOS unit tests
├── CheckpointWidget/        # WidgetKit extension (iOS)
│   ├── CheckpointWidgetBundle.swift
│   ├── CheckpointWidget.swift
│   ├── CheckpointWidgetIntent.swift
│   ├── WidgetProvider.swift
│   ├── VehicleEntity.swift
│   ├── VehicleEntityQuery.swift
│   ├── MarkServiceDoneIntent.swift
│   ├── Shared/
│   │   ├── WidgetColors.swift
│   │   ├── DistanceUnitWidget.swift
│   │   └── PendingWidgetCompletion.swift
│   └── Views/
│       ├── SmallWidgetView.swift
│       ├── MediumWidgetView.swift
│       ├── AccessoryCircularView.swift
│       ├── AccessoryRectangularView.swift
│       └── AccessoryInlineView.swift
├── checkpointTests/         # Unit tests
└── checkpointUITests/       # UI tests
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

### ServiceCluster
- Groups nearby services for bundled shop visits
- Configured via `ClusteringSettings` (mileage window, days window)

### CostCategory
Enum for categorizing service costs: `.maintenance`, `.repair`, `.upgrade`, `.inspection`, `.other`

### MileageSource
Enum for tracking how mileage was recorded: `.manual`, `.serviceCompletion`

### ClimateZone
Enum for seasonal maintenance reminders with 5 zones:
- `.coldWinter` — Northeast, Midwest, Mountain (harsh winters, road salt)
- `.mildFourSeason` — Mid-Atlantic, Pacific NW (moderate winters)
- `.hotDry` — Southwest, desert (extreme heat, minimal rain)
- `.hotHumid` — Southeast, Gulf Coast (heat, humidity, heavy rain)
- `.tropical` — Hawaii, PR, USVI (year-round warm)

Each zone has `displayName` and `description`. Stored via `@AppStorage` in `SeasonalSettings`.

### SeasonalReminder
Static catalog of seasonal maintenance reminders filtered by climate zone and calendar date:
- `id`, `name`, `description`, `icon`, `targetMonth`, `displayWindow`, `climateZones`, `category`
- 8 built-in reminders: antifreeze check, winter/summer tire swap, undercarriage inspection, AC system check, wiper blade check, battery check, coolant level check
- `activeReminders(for:on:settings:)` — Filters by zone, display window, dismissals, and suppressions
- `isWithinDisplayWindow(on:)` — Active from `displayWindow` days before the 1st of `targetMonth` through end of month
- `toPrefill()` → `SeasonalPrefill` — Pre-fill data for creating a tracked service from a reminder

Settings managed by `SeasonalSettings` (`@MainActor`, `@AppStorage`-backed):
- `isEnabled` — Global toggle for seasonal reminders
- `isSuppressed(_:)` — Permanently hide a specific reminder
- `isDismissed(_:year:)` — Dismiss for the current year

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
- Multi-step UI flow: Pick File → Configure → Preview → Success (in `Views/Settings/CSVImport/`)

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

### Siri/ (Voice Commands & Shortcuts)

App Intents-based Siri integration with 3 intents and a data provider:

| Component | Purpose |
|-----------|---------|
| `CheckNextDueIntent` | "What's due on my car?" — Returns dialog with most urgent service |
| `ListUpcomingServicesIntent` | "What maintenance is coming up?" — Lists up to 3 upcoming services |
| `UpdateMileageIntent` | "Update mileage to X miles" — Opens app with mileage pre-filled |
| `CheckpointShortcuts` | `AppShortcutsProvider` registering phrases for all 3 intents |
| `SiriDataProvider` | Reads vehicle/service data from App Groups (mirrors widget data access) |

**Data flow:** Siri intents read from the same App Group UserDefaults that widgets use. Read-only intents (`CheckNextDue`, `ListUpcoming`) return `IntentDialog` directly. The write intent (`UpdateMileage`) sets `openAppWhenRun = true` and stores pending data in `PendingMileageUpdate.shared` for the app to process on launch.

**Key types:**
- `SiriServiceData` — Vehicle name, ID, mileage, and services array
- `SiriService` — Name, status, due description, days remaining
- `SiriServiceStatus` — `.overdue`, `.dueSoon`, `.good`, `.neutral` with `dialogPrefix`
- `PendingMileageUpdate` — `@MainActor` singleton holding vehicleID and mileage from Siri

### StoreKit/ (Monetization)

StoreKit 2 purchase engine for Pro unlock and tip jar:

- `StoreManager` — `@Observable @MainActor` singleton managing products, purchases, and entitlements
- **Product IDs:** `pro.unlock` (non-consumable), `tip.small`, `tip.medium`, `tip.large` (consumable)
- **Entitlement checking:** Iterates `Transaction.currentEntitlements` to verify Pro status
- **Transaction listener:** Background `Task.detached` listening for `Transaction.updates`
- **Restore:** `AppStore.sync()` for purchase restoration
- **Debug mode:** `isPro = true` by default in DEBUG builds; `simulatePurchase()` for testing
- **Settings integration:** Syncs Pro status to `PurchaseSettings.shared.isPro`
- **UI:** `TipJarView` in Settings for tip purchases

### Sync/
- `SyncStatusService` — Consolidated iCloud sync status, network monitoring, remote change observation, and retry with backoff (`.synced`, `.syncing`, `.error`, `.disabled`, `.noAccount`)
- `DataMigrationService` — Local to iCloud migration, schema upgrades

### Utilities/
- `NHTSAService` — VIN decoding and recall alerts via NHTSA API
- `AppIconService` — Alternate app icon management
- `PresetDataService` — Loads bundled service presets from JSON
- `ServiceClusteringService` — Groups nearby services for bundled shop visits
- `HapticService` — Haptic feedback patterns
- `ToastService` — In-app toast notifications

### Widget/WidgetDataService
- Shares data with widget extension via App Groups (`group.com.418-studio.checkpoint.shared`)
- Data flow: App → JSON → shared UserDefaults → Widget reads → `WidgetCenter.reloadAllTimelines()`

### WatchConnectivity/WatchSessionService
- `@Observable @MainActor` singleton with WCSessionDelegate
- **Outgoing (iPhone → Watch):** `sendVehicleData()` via `WCSession.updateApplicationContext()`
- **Incoming (Watch → iPhone):** `handleMileageUpdate()`, `handleMarkServiceDone()`
- Watch App Group: `group.com.418-studio.checkpoint.watch`

## App Group Constants

Centralized in `Utilities/AppGroupConstants.swift` to avoid hardcoded strings:

```swift
enum AppGroupConstants {
    static let iPhoneWidget = "group.com.418-studio.checkpoint.shared"
    static let watchApp = "group.com.418-studio.checkpoint.watch"
}
```

Used by: `WidgetDataService`, `SiriDataProvider`, `WatchSessionService`, widget extensions.

## Widget Extension (iOS)

### Widget Sizes
| Size | Content | Layout |
|------|---------|--------|
| Small | Next 1 service | Single card |
| Medium | Next 2-3 services | Horizontal list with interactive Done button |
| Lock Screen (Circular) | Status icon + days remaining | Compact circular |
| Lock Screen (Rectangular) | Service name + due description | Two-line accessory |
| Lock Screen (Inline) | Service name + status | Single line text |

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
- **Design tokens:** `WatchDesignTokens.swift` for Watch-specific styling

### Watch App Structure
| Component | Purpose |
|-----------|---------|
| `WatchDataStore` | Local data storage via App Group UserDefaults |
| `WatchConnectivityService` | Watch-side WCSession delegate |
| `WatchServiceData` | Codable models for Watch data transfer |
| `ServicesListView` | List of upcoming services |
| `MileageUpdateView` | Digital crown mileage entry |
| `MarkServiceDoneView` | Mark service as completed |

### Watch Widget (Complications)

4 widget families supported via `CheckpointWatchWidget`:

| Family | View | Content |
|--------|------|---------|
| `.accessoryCircular` | `WatchCircularView` | Status icon with days remaining |
| `.accessoryRectangular` | `WatchRectangularView` | Service name, status, due description |
| `.accessoryInline` | `WatchInlineView` | Single-line service summary |
| `.accessoryCorner` | `WatchCornerView` | Corner complication with status |

**Data flow:** `WatchWidgetProvider` (a `TimelineProvider`) reads `WatchWidgetData` from the Watch App Group UserDefaults (`watchVehicleData` key). Timeline refreshes hourly. Staleness detected if data is older than 1 hour.

**Key types:**
- `WatchWidgetEntry` — Timeline entry with vehicleName, mileage, optional service, staleness flag
- `WatchWidgetService` — Service name, status, due description, due mileage, days remaining
- `WatchWidgetStatus` — `.overdue`, `.dueSoon`, `.good`, `.neutral` with color and icon mappings
- `WatchWidgetColors` — Watch-specific color constants

## View Components

### Components/Attachments/
| Component | Purpose |
|-----------|---------|
| `AttachmentGrid.swift` | Grid display of service log attachments |
| `AttachmentPicker.swift` | Photo picker with camera/library options |
| `AttachmentThumbnail.swift` | Individual attachment thumbnail |
| `ReceiptTextView.swift` | Display extracted receipt text |

### Components/Camera/
| Component | Purpose |
|-----------|---------|
| `ConfidenceIndicator.swift` | OCR confidence level display |
| `OCRConfirmationView.swift` | Confirm/edit OCR results |
| `OCRProcessingIndicator.swift` | Processing state during OCR |
| `OdometerCameraView.swift` | Camera viewfinder for odometer |
| `OdometerCaptureView.swift` | Full capture flow with guidance |
| `ReceiptScannerView.swift` | Receipt document scanning |

### Components/Cards/
| Component | Purpose |
|-----------|---------|
| `CategoryBreakdownCard.swift` | Cost breakdown by category |
| `ChartPlaceholderCard.swift` | Placeholder when chart has no data |
| `CostSummaryCard.swift` | Total spent hero card |
| `CumulativeCostChartCard.swift` | Area chart of cumulative spending |
| `MileageUpdateSheet.swift` | Full mileage update sheet (extracted from QuickMileageUpdateCard) |
| `MonthlyBreakdownCard.swift` | Monthly cost breakdown |
| `MonthlyTrendChartCard.swift` | Vertical bar chart of monthly spending |
| `NextUpCard.swift` | Hero card for most urgent service |
| `QuickMileageUpdateCard.swift` | Inline mileage entry card |
| `QuickSpecsCard.swift` | Vehicle specs display |
| `QuickStatsBar.swift` | Summary statistics bar |
| `RecallAlertCard.swift` | NHTSA recall warning |
| `SeasonalReminderCard.swift` | Climate-aware seasonal maintenance card |
| `ServiceClusterCard.swift` | Bundled services suggestion card |
| `StatsCard.swift` | Compact stat display |
| `YearlyCostRoundupCard.swift` | Annual cost summary |

### Components/Export/
| Component | Purpose |
|-----------|---------|
| `ExportOptionsSheet.swift` | Export format selection sheet |
| `ShareSheet.swift` | iOS share sheet wrapper |

### Components/Feedback/
| Component | Purpose |
|-----------|---------|
| `FeatureHintView.swift` | Feature discovery hints |
| `ToastView.swift` | In-app toast notification |

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

## Tab Architecture

```
ContentView
├── ContentView+Helpers.swift (sheet presentation logic)
└── TabView (BrutalistTabBar)
    ├── HomeTab
    │   ├── HomeTab+Helpers.swift (helper methods)
    │   ├── HomeTab+EmptyStates.swift (empty state views)
    │   ├── VehicleHeader
    │   ├── NextUpCard
    │   ├── SeasonalReminderCard (climate-zone filtered)
    │   ├── ServiceClusterCard (bundled services)
    │   ├── QuickStatsBar
    │   └── RecentActivityFeed
    ├── ServicesTab
    │   ├── VehicleHeader
    │   └── List of ServiceRow
    └── CostsTab
        ├── CostsTab+Analytics.swift (chart logic)
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
- **ServicePresetTests** — Preset loading and validation
- **MarbeteTests** — Expiration date calculation, status computation, days remaining
- **CostCategoryTests** — Category enum properties
- **SeasonalReminderTests** — Display window calculation, zone filtering, active reminders

### Service Tests
- **CSVImportServiceTests** — Format auto-detection, row parsing, malformed data handling
- **ServiceClusteringTests** — Service bundling within mileage/date windows
- **NotificationServiceTests** — Notification authorization, scheduling
- **NHTSAServiceTests** — VIN decoding, recall API
- **AppIconServiceTests** — Alternate icon management
- **OdometerOCRServiceTests** — OCR text extraction, number parsing
- **OdometerImagePreprocessorTests** — Image preprocessing pipeline
- **ReceiptOCRServiceTests** — Receipt text extraction
- **OCRErrorTests** — Error type handling
- **SyncStatusServiceTests** — Consolidated sync status, SyncError properties, retry logic
- **DataMigrationServiceTests** — Migration logic
- **ServiceHistoryPDFServiceTests** — PDF generation
- **WidgetDataServiceTests** — Widget data serialization
- **StoreManagerTests** — StoreKit purchase flow, entitlements
- **ToastServiceTests** — Toast notification lifecycle

### Siri Tests
- **SiriDataProviderTests** — Data loading from App Groups
- **CheckNextDueIntentTests** — Dialog formatting for next due service
- **UpdateMileageIntentTests** — Pending mileage update storage

### View Tests
- **HomeTabTests** — Home tab rendering and data display
- **ServicesTabTests** — Services tab rendering
- **CostsTabTests** — Costs tab rendering
- **SettingsViewTests** — Settings toggle states
- **AddVehicleViewTests** — Vehicle creation form
- **EditVehicleViewTests** — Vehicle edit form
- **AddServiceViewTests** — Service creation form
- **ServiceDetailViewTests** — Service detail display
- **ServiceLogDetailViewTests** — Log detail display
- **EditServiceLogViewTests** — Log editing
- **VehiclePickerSheetTests** — Vehicle selection
- **VehicleHeaderTests** — Header display

### Component Tests
- **MaintenanceTimelineTests** — Timeline rendering
- **OdometerCaptureViewTests** — OCR capture flow
- **YearlyCostRoundupCardTests** — Annual summary card
- **OCRConfirmationViewTests** — OCR result confirmation
- **BrutalistTabBarTests** — Tab bar rendering
- **RecallAlertCardTests** — Recall card display
- **QuickSpecsCardTests** — Vehicle specs card
- **MileageInputFieldTests** — Mileage input validation
- **ServiceTypePickerTests** — Service type selection

### Design System Tests
- **ColorHexTests** — Hex color conversion
- **ThemeDefinitionTests** — Theme properties
- **ThemeManagerTests** — Theme selection persistence
- **TappableCardModifierTests** — Card interaction behavior

### Utility Tests
- **DistanceUnitTests** — Miles/km conversion
- **DistanceSettingsTests** — Distance preference persistence
- **SyncSettingsTests** — Sync preference persistence
- **MileageEstimateSettingsTests** — Estimate toggle persistence
- **SeasonalSettingsTests** — Seasonal reminder preferences
- **CostValidationTests** — Cost input validation
- **OnboardingStateTests** — Onboarding state machine transitions
- **PurchaseSettingsTests** — Pro status persistence
- **AppIconSettingsTests** — Icon selection persistence
- **FormattersTests** — Number/date formatting
- **AppGroupConstantsTests** — App Group identifier validation
- **VehicleSelectionPersistenceTests** — Vehicle selection persistence

### Integration Tests
- **ContextualInsightsTests** — Time/miles since last service, average cost, times serviced
- **PendingWidgetCompletionTests** — Encoding/decoding, queue/dequeue, processing
- **VINRegistrationTests** — Character count display, validation state transitions, auto-fill feedback
- **AnalyticsEventTests** — Event taxonomy, property types
- **AnalyticsSettingsTests** — Opt-out toggle

### Widget Tests
- **AccessoryWidgetTests** — Lock screen widget rendering
- **PendingWidgetCompletionTests** — Widget completion queue

### Extension Tests
- **ServiceFilteringTests** — Array filtering extensions for service status
