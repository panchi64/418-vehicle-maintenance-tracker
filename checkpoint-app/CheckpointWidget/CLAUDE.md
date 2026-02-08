# CheckpointWidget - Home Screen Widget

This directory contains the WidgetKit extension for home screen widgets.

## Files

| File | Purpose |
|------|---------|
| `CheckpointWidget.swift` | Widget configuration and entry point |
| `CheckpointWidgetBundle.swift` | Widget bundle registration |
| `CheckpointWidgetIntent.swift` | App Intents for widget configuration |
| `WidgetProvider.swift` | Timeline provider for widget data |
| `VehicleEntity.swift` | App Entity for vehicle selection |
| `VehicleEntityQuery.swift` | Entity query for vehicle picker |
| `MarkServiceDoneIntent.swift` | App Intent for interactive "Done" button |
| `Views/SmallWidgetView.swift` | Small widget layout |
| `Views/MediumWidgetView.swift` | Medium widget layout (includes interactive Done button) |
| `Shared/WidgetColors.swift` | Widget-specific color definitions |
| `Shared/DistanceUnitWidget.swift` | Distance unit types for widget display |
| `Shared/SharedWidgetSettings.swift` | Shared settings between app and widget |
| `Shared/PendingWidgetCompletion.swift` | Queued service completions from widget actions |

## Widget Sizes

| Size | Content | Layout |
|------|---------|--------|
| Small | Next 1 service | Single card |
| Medium | Next 2-3 services | Horizontal list |

## App Groups Configuration

**Identifier:** `group.com.418-studio.checkpoint.shared`

Both the main app and widget extension must have this App Group enabled in their entitlements.

## Data Flow

```
┌─────────────────────────────────────────────────────────┐
│ Main App                                                │
│                                                         │
│  1. Data changes → WidgetDataService.updateWidget()     │
│  2. Serialize to JSON                                   │
│  3. Store in shared UserDefaults                        │
│  4. Call WidgetCenter.reloadAllTimelines()              │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│ Shared UserDefaults (App Group)                         │
│                                                         │
│  Key: "widgetData"                                      │
│  Value: JSON { vehicleName, services[], ... }           │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│ Widget Extension                                        │
│                                                         │
│  1. WidgetProvider.getTimeline() called                 │
│  2. Read from shared UserDefaults                       │
│  3. Decode JSON to ServiceEntry                         │
│  4. Return timeline with entries                        │
└─────────────────────────────────────────────────────────┘
```

## Key Types

### ServiceEntry
Timeline entry containing widget display data:
```swift
struct ServiceEntry: TimelineEntry {
    let date: Date
    let vehicleName: String
    let currentMileage: Int
    let services: [WidgetService]
    let configuration: CheckpointWidgetConfigurationIntent
}
```

### WidgetService
Service data optimized for widget display:
```swift
struct WidgetService: Identifiable {
    let name: String
    let status: WidgetServiceStatus
    let dueDescription: String
    let dueMileage: Int?
    let daysRemaining: Int?
}
```

### WidgetServiceStatus
Mirrors main app's `ServiceStatus`:
```swift
enum WidgetServiceStatus: String, Codable {
    case overdue, dueSoon, good, neutral
}
```

## Timeline Provider

`WidgetProvider` implements `AppIntentTimelineProvider`:

```swift
struct WidgetProvider: AppIntentTimelineProvider {
    func timeline(for configuration: ConfigIntent, in context: Context) async -> Timeline<ServiceEntry> {
        let entry = loadEntry(configuration: configuration)
        // Refresh every 4 hours
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 4, to: Date())!
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
}
```

## Interactive Widgets (iOS 17+)

The medium widget includes a "Done" button (checkmark) on the most urgent service, allowing users to mark it complete without opening the app.

**Flow:**
1. User taps checkmark button on medium widget
2. `MarkServiceDoneIntent` executes as an App Intent
3. Completion is queued as `PendingWidgetCompletion` in shared UserDefaults
4. Widget timeline reloads to reflect pending state
5. When main app comes to foreground, `WidgetDataService.processPendingWidgetCompletions()` creates the actual `ServiceLog` entry
6. Widget data refreshes with updated service status

**Key Types:**
- `MarkServiceDoneIntent` — App Intent that queues the completion
- `PendingWidgetCompletion` — Codable struct stored in shared UserDefaults with serviceID, date, and vehicleID
- `WidgetService.serviceID` — Persistent identifier linking widget data back to SwiftData `Service`

## Vehicle Selection (App Intents)

Widgets support selecting which vehicle to display:

1. `VehicleEntity` - Represents a vehicle in widget configuration
2. `VehicleEntityQuery` - Provides vehicle list for picker
3. `CheckpointWidgetConfigurationIntent` - Stores selected vehicle

## Widget Colors

`WidgetColors.swift` provides widget-specific color tokens:
```swift
struct WidgetColors {
    static let statusOverdue = Color.red
    static let statusDueSoon = Color.yellow
    static let statusGood = Color.green
    static let statusNeutral = Color.gray
}
```

## Testing Widgets

Widgets can be previewed in Xcode:
```swift
#Preview(as: .systemSmall) {
    CheckpointWidget()
} timeline: {
    ServiceEntry.placeholder
    ServiceEntry.empty
}
```

## UserDefaults Best Practices

- **Do NOT call `synchronize()`** - It's deprecated and unnecessary. UserDefaults auto-syncs and calling it can hurt performance
- The `widgetData` key contains the app's currently selected vehicle data
- Widget uses `widgetData` as primary source to avoid cross-process synchronization issues
- Widget configuration (per-widget vehicle selection) is stored separately by WidgetKit

## Troubleshooting

**Widget not updating:**
1. Verify App Group is configured on both targets
2. Check `WidgetCenter.shared.reloadAllTimelines()` is called
3. Verify data is being written to shared UserDefaults
4. Note: `reloadAllTimelines()` is a suggestion to iOS, not a guarantee of immediate reload

**Widget shows placeholder:**
1. Check if any vehicles exist
2. Verify JSON serialization is working
3. Check for errors in `WidgetProvider.loadEntry()`

**Widget shows wrong vehicle:**
1. Ensure `WidgetDataService.updateWidget(for:)` is called when vehicle selection changes
2. The `widgetData` key should always contain the currently selected vehicle's data
