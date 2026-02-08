# Services - Business Logic Layer

This directory contains all service classes that handle business logic, external integrations, and background operations.

## Directory Structure

```
Services/
├── Analytics/           # PostHog analytics (opt-out, privacy-respecting)
│   ├── AnalyticsEvent.swift              # Type-safe event enum with properties
│   ├── AnalyticsScreenTracker.swift      # .trackScreen() ViewModifier
│   └── AnalyticsService.swift            # PostHog wrapper (@Observable @MainActor)
├── Export/              # Document export services
│   └── ServiceHistoryPDFService.swift  # PDF generation for service history
├── Notifications/       # Local notification management (modular architecture)
│   ├── NotificationService.swift           # Core: authorization, categories, singleton
│   ├── NotificationService+Delegate.swift  # UNUserNotificationCenterDelegate
│   ├── NotificationService+Scheduling.swift # Backwards-compatible delegation methods
│   ├── ServiceNotificationScheduler.swift  # Service due notifications
│   ├── MileageReminderScheduler.swift      # Mileage reminder notifications
│   ├── MarbeteNotificationScheduler.swift  # Marbete expiration notifications
│   ├── YearlyRoundupScheduler.swift        # Annual cost roundup notifications
│   └── NotificationNames.swift             # Notification.Name extensions
├── OCR/                 # Vision framework services
│   ├── OdometerImagePreprocessor.swift
│   ├── OdometerOCRService.swift
│   └── VINOCRService.swift
├── Siri/                # Siri voice command integration (see Siri/CLAUDE.md)
│   ├── CheckNextDueIntent.swift            # "What's due on my car?"
│   ├── ListUpcomingServicesIntent.swift    # "What maintenance is coming up?"
│   ├── UpdateMileageIntent.swift           # "Update mileage to X miles"
│   ├── CheckpointShortcuts.swift           # AppShortcutsProvider with phrases
│   └── SiriDataProvider.swift              # Reads data from App Groups
├── Import/              # CSV import from competitor apps
│   └── CSVImportService.swift
├── Sync/                # iCloud & data sync
│   ├── CloudSyncStatusService.swift
│   ├── DataMigrationService.swift
│   └── SyncStatusService.swift
├── Utilities/           # Single-purpose services
│   ├── AppIconService.swift
│   ├── NHTSAService.swift
│   └── PresetDataService.swift
├── WatchConnectivity/   # Apple Watch communication
│   └── WatchSessionService.swift
└── Widget/              # Widget data sharing
    └── WidgetDataService.swift
```

## Service Inventory

### Analytics/ (PostHog Integration)
Privacy-respecting analytics via self-hosted PostHog. First external dependency.

**Architecture:**
- `AnalyticsService` — `@Observable @MainActor` singleton wrapping PostHog SDK
- `AnalyticsEvent` — Type-safe enum with `.name` and `.properties` (categorical/boolean only, no PII)
- `AnalyticsScreenTracker` — `.trackScreen(.home)` ViewModifier for automatic screen events
- Settings managed via `AnalyticsSettings` in `Utilities/`

**Configuration:** Info.plist keys `POSTHOG_API_KEY` and `POSTHOG_HOST` (build-time via xcconfig). If missing, analytics silently disabled.

**Consent:** Opt-out model (enabled by default). Toggle in Settings. PostHog SDK `optIn()`/`optOut()` synced with `AnalyticsSettings.isEnabled`.

**Usage:**
```swift
// Screen tracking (ViewModifier)
.trackScreen(.home)

// Event capture
AnalyticsService.shared.capture(.vehicleAdded(usedOCR: true, usedVINLookup: false, hasNickname: true))
```

### Export/ServiceHistoryPDFService
Generates professional PDF documents with vehicle service history.

**Key Features:**
- Brutalist aesthetic: monospace fonts, uppercase labels, 2px borders
- Amber accent (#E89B3C) for headers and branding
- US Letter format (612x792 points)
- Multi-page support with pagination

**Usage:**
```swift
let options = ServiceHistoryPDFService.ExportOptions(
    includeAttachments: false,
    includeTotal: true
)
if let url = ServiceHistoryPDFService.shared.generatePDF(
    for: vehicle,
    serviceLogs: logs,
    options: options
) {
    // Share via UIActivityViewController
}
```

**PDF Contents:**
- App branding header
- Vehicle info (name, VIN, mileage, year, make/model)
- Chronological service history (date, mileage, cost, notes)
- Total spent (optional)
- Footer with generation timestamp and page numbers

### Import/CSVImportService
Imports maintenance history from competitor apps via CSV files.

**Supported Formats:**
- **Fuelly** — fuel and service logs
- **Drivvo** — maintenance records
- **Simply Auto** — service history

**Features:**
- Auto-detects CSV format from column headers
- Maps competitor service types to Checkpoint presets
- Creates ServiceLog entries with date, mileage, cost, and notes
- Returns import summary with count of imported/skipped records

**Usage:**
```swift
let service = CSVImportService()
let result = try await service.importCSV(from: fileURL, for: vehicle, in: modelContext)
// result.imported: Int, result.skipped: Int
```

### Notifications/ (Modular Architecture)
Manages local notifications with focused, single-responsibility schedulers.

**Core Service (`NotificationService.swift`):**
- `@Observable @MainActor` singleton for thread-safe UI binding
- Handles authorization, category setup, and shared configuration
- Delegate methods in `NotificationService+Delegate.swift`

**Schedulers (static methods, no shared state):**
- `ServiceNotificationScheduler` - Service due notifications (30/7/1/0 days before)
- `MileageReminderScheduler` - Bi-weekly mileage update reminders
- `MarbeteNotificationScheduler` - PR vehicle registration expiration
- `YearlyRoundupScheduler` - Annual cost summary (January 2nd)

**Setup:**
```swift
UNUserNotificationCenter.current().delegate = NotificationService.shared
```

**Categories:**
- `SERVICE_DUE` - Service reminder with "Mark Done" / "Remind Tomorrow"
- `MILEAGE_REMINDER` - Odometer update with "Update Now" / "Remind Later"
- `MARBETE_DUE` - Registration reminder with "Remind Tomorrow"
- `YEARLY_ROUNDUP` - Cost summary with "View Costs"

### OCR/OdometerOCRService
Vision framework OCR for reading odometer displays.

**Pipeline:**
1. Image preprocessing (contrast, threshold)
2. VNRecognizeTextRequest with `.accurate` level
3. Number extraction and validation
4. Confidence scoring

**Key Methods:**
- `recognizeOdometer(from:)` - Main OCR entry point
- Returns `OdometerResult` with value and confidence

### OCR/VINOCRService
Vision framework OCR for reading VIN plates.

**Features:**
- 17-character VIN validation
- Handles common OCR mistakes (0/O, 1/I)
- Returns decoded vehicle info

### OCR/OdometerImagePreprocessor
Image preprocessing for better OCR accuracy.

**Preprocessing Steps:**
- Grayscale conversion
- Contrast enhancement
- Adaptive thresholding

### Sync/CloudSyncStatusService
Monitors iCloud sync status.

**Observes:**
- `NSPersistentCloudKitContainer` events
- Import/export progress
- Sync errors

### Sync/SyncStatusService
UI-facing sync status reporting.

**States:**
- `.synced` - All data up to date
- `.syncing` - Sync in progress
- `.error` - Sync failed
- `.offline` - No network

### Sync/DataMigrationService
Handles data migration between containers.

**Use Cases:**
- Local to iCloud migration
- Schema version upgrades

### Utilities/NHTSAService
NHTSA API integration for vehicle data.

**Endpoints:**
- VIN decoding (make, model, year)
- Recall alerts by VIN

**API Base:** `https://vpic.nhtsa.dot.gov/api/`

### Utilities/AppIconService
Manages alternate app icons.

**Features:**
- Lists available icons
- Handles icon switching
- Persists selection

### Utilities/PresetDataService
Loads bundled service presets from JSON.

**Source:** `Resources/ServicePresets.json`

**Categories:** Engine, Brakes, Tires, Fluids, Electrical, etc.

### Widget/WidgetDataService
Shares data with widget extension via App Groups.

**Data Flow:**
1. App calls `updateWidget(for: vehicle)`
2. Data serialized to JSON
3. Stored in shared UserDefaults
4. Widget reads via `WidgetProvider`
5. `WidgetCenter.shared.reloadAllTimelines()` triggers refresh

**App Group:** `group.com.418-studio.checkpoint.shared`

### WatchConnectivity/WatchSessionService
iPhone-side WCSession delegate for Apple Watch communication.

**Architecture:**
- `@Observable @MainActor` singleton with WCSessionDelegate
- Receives `ModelContainer` reference for SwiftData access
- Activated in `checkpointApp.swift` init

**Outgoing (iPhone → Watch):**
- `sendVehicleData()` — called from `WidgetDataService.updateWidgetData()` after widget update
- Uses `WCSession.updateApplicationContext()` (battery-efficient, latest-state-only)

**Incoming (Watch → iPhone):**
- `handleMileageUpdate()` — updates Vehicle.currentMileage, creates MileageSnapshot
- `handleMarkServiceDone()` — creates ServiceLog, updates Service due tracking
- Handles both `sendMessage` (real-time) and `transferUserInfo` (queued offline)

**Watch App Group:** `group.com.418-studio.checkpoint.watch` (separate from iPhone App Group)

## Concurrency Patterns

Services use modern Swift concurrency with `@Observable` and `@MainActor`:
```swift
@Observable
@MainActor
final class NotificationService: NSObject {
    static let shared = NotificationService()
    var isAuthorized = false
    // ...
}
```

Schedulers are stateless structs with static methods:
```swift
struct ServiceNotificationScheduler {
    static func scheduleNotification(for service: Service, vehicle: Vehicle) -> String? {
        // ...
    }
}
```

For long-running operations, use background actors or `Task.detached`.

## Error Handling

Services throw domain-specific errors:
```swift
enum OCRError: Error {
    case imageLoadFailed
    case noTextDetected
    case invalidOdometerValue
}
```

Callers should handle errors appropriately:
```swift
do {
    let result = try await OdometerOCRService.shared.recognizeOdometer(from: image)
} catch OCRError.noTextDetected {
    // Show guidance to user
}
```
