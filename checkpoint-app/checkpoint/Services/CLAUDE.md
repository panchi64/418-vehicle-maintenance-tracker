# Services - Business Logic Layer

This directory contains all service classes that handle business logic, external integrations, and background operations.

## Directory Structure

```
Services/
├── Notifications/       # Local notification management
│   └── NotificationService.swift
├── OCR/                 # Vision framework services
│   ├── OdometerImagePreprocessor.swift
│   ├── OdometerOCRService.swift
│   └── VINOCRService.swift
├── Sync/                # iCloud & data sync
│   ├── CloudSyncStatusService.swift
│   ├── DataMigrationService.swift
│   └── SyncStatusService.swift
├── Utilities/           # Single-purpose services
│   ├── AppIconService.swift
│   ├── NHTSAService.swift
│   └── PresetDataService.swift
└── Widget/              # Widget data sharing
    └── WidgetDataService.swift
```

## Service Inventory

### Notifications/NotificationService
Manages local notifications for service due dates.

**Key Features:**
- Schedules notifications at 9 AM on due dates
- Action buttons: "Mark as Done", "Remind Tomorrow"
- Handles foreground display and action responses
- Uses `UNUserNotificationCenter`

**Setup:**
```swift
UNUserNotificationCenter.current().delegate = NotificationService.shared
```

**Categories:**
- `SERVICE_DUE` - Standard service reminder
- `MARBETE_DUE` - Vehicle registration reminder

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

## Concurrency Patterns

Services use Swift concurrency:
```swift
@MainActor
class NotificationService {
    static let shared = NotificationService()

    func schedule(_ service: Service) async throws {
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
