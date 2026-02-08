# Services - Business Logic Layer

This directory contains all service classes that handle business logic, external integrations, and background operations.

## Directory Structure

```
Services/
├── Analytics/           # PostHog analytics (opt-out, privacy-respecting)
├── Export/              # PDF generation for service history
├── Notifications/       # Local notification management (modular architecture)
├── OCR/                 # Vision framework services (odometer, VIN)
├── Siri/                # Siri voice commands & Shortcuts (see Siri/CLAUDE.md)
├── Import/              # CSV import from competitor apps
├── Sync/                # iCloud & data sync
├── Utilities/           # Single-purpose services (NHTSA, app icons, presets)
├── WatchConnectivity/   # Apple Watch communication
└── Widget/              # Widget data sharing via App Groups
```

For detailed service descriptions, see `docs/ARCHITECTURE.md`.

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
