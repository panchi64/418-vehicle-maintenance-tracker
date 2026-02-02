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

### SiriDataProvider
Static methods to read vehicle/service data from App Groups:
```swift
SiriDataProvider.loadServiceData(for: vehicleID) -> SiriServiceData?
SiriDataProvider.loadVehicleList() -> [SiriVehicleInfo]
```

### CheckNextDueIntent
Returns a dialog with the most urgent service:
- "Oil change on Daily Driver is due soon. 5 days remaining."
- "Brake pads on Truck is overdue. 3 days overdue."

If no vehicle is specified, Siri asks "Which vehicle would you like to check?"

### ListUpcomingServicesIntent
Returns a dialog listing 1-3 upcoming services:
- "Here's what's coming up for Daily Driver: Oil change is due in 5 days. Tire rotation in 30 days."

If no vehicle is specified, Siri asks "Which vehicle would you like to check?"

### UpdateMileageIntent
Opens the app with mileage pre-filled for user confirmation:
- Uses `openAppWhenRun = true` to launch app
- Stores pending update in `PendingMileageUpdate.shared`
- App checks for pending updates on `scenePhase == .active`

### PendingMileageUpdate
Singleton holding Siri-initiated mileage update data:
```swift
PendingMileageUpdate.shared.vehicleID  // Vehicle to update
PendingMileageUpdate.shared.mileage    // New mileage value
PendingMileageUpdate.shared.hasPendingUpdate  // Check if pending
PendingMileageUpdate.shared.clear()    // Clear after processing
```

## App Shortcuts Phrases

| Intent | Phrases |
|--------|---------|
| CheckNextDue | "What's due on my car in Checkpoint" |
| ListUpcoming | "What maintenance is coming up in Checkpoint" |
| UpdateMileage | "Update mileage in Checkpoint" |

## Shared Entities

VehicleEntity and VehicleEntityQuery are defined in `CheckpointWidget/` and must be added to **both** the main app and widget targets in Xcode. They provide:
- Vehicle selection in Siri intent parameters
- Vehicle picker in widget configuration

## Integration Points

### ContentView
- Checks `PendingMileageUpdate.shared` when `scenePhase == .active`
- Shows `MileageUpdateSheet` with `prefilledMileage` from Siri

### AppState
- Contains `pendingMileageUpdate` property (unused, for future use)
- Can be extended for additional Siri state management

### MileageUpdateSheet
- Accepts optional `prefilledMileage` parameter
- Uses Siri value if provided, otherwise shows current mileage

## Entitlements

The main app requires the Siri entitlement in `checkpoint.entitlements`:
```xml
<key>com.apple.developer.siri</key>
<true/>
```

## Testing

### Manual Testing
1. **Siri Voice - Read Queries:**
   - "Hey Siri, what's due on my car in Checkpoint"
   - "Hey Siri, what maintenance is coming up in Checkpoint"

2. **Siri Voice - Mileage Update:**
   - "Hey Siri, update mileage in Checkpoint"
   - Siri asks for vehicle and mileage
   - App opens with values pre-filled

3. **Shortcuts App:**
   - Verify Checkpoint shortcuts appear under "App Shortcuts"
   - Create custom shortcuts using the intents

### Automated Testing
See `checkpointTests/Services/Siri/` for unit tests:
- `SiriDataProviderTests` - Data loading from App Groups
- `CheckNextDueIntentTests` - Dialog formatting
- `UpdateMileageIntentTests` - Pending update storage
