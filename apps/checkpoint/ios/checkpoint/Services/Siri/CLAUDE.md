# Siri - Voice Command Integration

This directory contains App Intents for Siri voice commands and Shortcuts integration.

## Architecture

```
Siri/
├── CheckNextDueIntent.swift       # "What's due on my car?"
├── ListUpcomingServicesIntent.swift # "What maintenance is coming up?"
├── UpdateMileageIntent.swift      # "Update mileage to X miles"
├── CheckpointShortcuts.swift      # AppShortcutsProvider with phrases
└── SiriDataProvider.swift         # Reads data from App Groups
```

## Data Flow

### Read-Only Intents (CheckNextDue, ListUpcoming)
```
Main App                          Shared Storage                    Siri
┌────────────────┐              ┌────────────────┐              ┌────────────────┐
│ Data changes   │─────────────>│ App Groups     │<─────────────│ Siri Intent    │
│ WidgetData     │   writes     │ UserDefaults   │    reads     │ reads data,    │
│ Service        │              │                │              │ returns dialog │
└────────────────┘              └────────────────┘              └────────────────┘
```

### Write Intent (UpdateMileage)
```
Siri                              App (Foreground)
┌────────────────┐              ┌────────────────────────────────┐
│ "Update to     │─────────────>│ Opens with mileage pre-filled  │
│  52,000 miles" │  opens app   │ User confirms → SwiftData save │
└────────────────┘              └────────────────────────────────┘
```

## Key Types

- `SiriDataProvider` — Static methods to read vehicle/service data from App Groups
- `CheckNextDueIntent` — Returns dialog with most urgent service
- `ListUpcomingServicesIntent` — Returns dialog listing 1-3 upcoming services
- `UpdateMileageIntent` — Opens app with mileage pre-filled (`openAppWhenRun = true`), stores in `PendingMileageUpdate.shared`

## Shared Entities

VehicleEntity and VehicleEntityQuery are defined in `CheckpointWidget/` and must be added to **both** the main app and widget targets in Xcode. They provide vehicle selection in Siri intent parameters and widget configuration.

## Integration Points

- **ContentView** — Checks `PendingMileageUpdate.shared` when `scenePhase == .active`, shows `MileageUpdateSheet` with `prefilledMileage`
- **AppState** — Contains `pendingMileageUpdate` property for future use

## Entitlements

The main app requires the Siri entitlement in `checkpoint.entitlements`:
```xml
<key>com.apple.developer.siri</key>
<true/>
```
