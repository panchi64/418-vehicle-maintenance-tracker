# Checkpoint iOS App - Development Guide

## Project Overview

Checkpoint is a vehicle maintenance tracker iOS app built with SwiftUI and SwiftData. It allows users to manage vehicles, log/schedule maintenance services, and receive notifications when services are due.

## Architecture

### Technology Stack
- **UI Framework:** SwiftUI
- **Data Persistence:** SwiftData
- **Notifications:** UserNotifications framework
- **Widget:** WidgetKit
- **Minimum iOS Version:** iOS 17.0

### Design Philosophy
- Dark mode first (amber accent #E89B3C)
- "What's next?" first - most urgent item shown prominently
- Glanceable, not a chore
- Zero-friction data entry

## Project Structure

```
checkpoint-app/
├── checkpoint/                          # Main app bundle
│   ├── checkpointApp.swift              # App entry point with SwiftData setup
│   ├── ContentView.swift                # Root content view
│   ├── Models/                          # SwiftData models
│   │   ├── Vehicle.swift                # Vehicle entity
│   │   ├── Service.swift                # Service entity with status logic
│   │   ├── ServiceLog.swift             # Completed service records
│   │   └── ServicePreset.swift          # Bundled service type presets
│   ├── DesignSystem/                    # Theme and design tokens
│   │   ├── Theme.swift                  # Colors, button styles, card styles
│   │   ├── Typography.swift             # SF Pro font hierarchy
│   │   └── Spacing.swift                # 4pt base unit spacing system
│   ├── Views/
│   │   ├── DashboardView.swift          # Main dashboard screen
│   │   ├── VehiclePickerSheet.swift     # Vehicle selection modal
│   │   ├── Vehicle/
│   │   │   ├── AddVehicleView.swift     # Add new vehicle form
│   │   │   └── EditVehicleView.swift    # Edit/delete vehicle form
│   │   ├── Service/
│   │   │   ├── AddServiceView.swift     # Dual-mode: log or schedule service
│   │   │   ├── ServiceDetailView.swift  # Service details with history
│   │   │   └── EditServiceView.swift    # Edit/delete service form
│   │   └── Components/
│   │       ├── NextUpCard.swift         # Hero service card
│   │       ├── ServiceRow.swift         # Service list item
│   │       ├── StatusDot.swift          # Status indicator
│   │       ├── VehicleSelector.swift    # Vehicle selector button
│   │       ├── ServiceTypePicker.swift  # Preset picker component
│   │       └── MileageInputField.swift  # Formatted mileage input
│   ├── Services/
│   │   ├── NotificationService.swift    # Local notification management
│   │   └── PresetDataService.swift      # Load bundled presets
│   ├── Resources/
│   │   └── ServicePresets.json          # 10 bundled service presets
│   └── Assets.xcassets/                 # Colors and app icons
├── checkpointTests/                     # Unit tests
│   ├── Models/                          # Model tests
│   ├── Views/                           # View tests
│   └── Services/                        # Service tests
├── checkpointUITests/                   # UI tests
└── CheckpointWidget/                    # Home screen widget extension
    ├── CheckpointWidget.swift           # Widget configuration
    ├── CheckpointWidgetBundle.swift     # Widget bundle
    ├── WidgetProvider.swift             # Timeline provider
    ├── Views/
    │   ├── SmallWidgetView.swift        # Small widget
    │   └── MediumWidgetView.swift       # Medium widget
    └── Shared/
        └── WidgetColors.swift           # Widget color definitions
```

## Key Models

### Vehicle
- `name`, `make`, `model`, `year`, `currentMileage`, `vin`
- Has many `services` and `serviceLogs` (cascade delete)

### Service
- `name`, `dueDate`, `dueMileage`, `lastPerformed`, `lastMileage`
- `intervalMonths`, `intervalMiles`, `notificationID`
- Computed `status(currentMileage:)` returns `.overdue`, `.dueSoon`, `.good`, `.neutral`
- Computed `urgencyScore` for sorting by urgency

### ServiceLog
- Records completed service instances
- `performedDate`, `mileageAtService`, `cost`, `notes`
- Links to both `Service` and `Vehicle`

### ServicePreset
- Bundled service types with `ServiceCategory` enum
- `defaultIntervalMonths`, `defaultIntervalMiles`

## Design System

### Colors (from Theme.swift)
- **Background:** `backgroundPrimary`, `backgroundElevated`, `backgroundSubtle`
- **Text:** `textPrimary`, `textSecondary`, `textTertiary`
- **Accent:** `accent` (amber #E89B3C), `accentMuted`
- **Status:** `statusOverdue` (red), `statusDueSoon` (yellow), `statusGood` (green), `statusNeutral` (gray)

### Typography (from Typography.swift)
- `displayLarge`: 34pt Bold rounded
- `headlineLarge`: 28pt Semibold
- `headline`: 22pt Semibold
- `title`: 17pt Semibold
- `bodyText`: 17pt Regular
- `bodySecondary`: 15pt Regular
- `caption`: 13pt Medium

### Spacing (from Spacing.swift)
- `xs`: 4pt, `sm`: 8pt, `listItem`: 12pt
- `md`: 16pt, `screenHorizontal`: 20pt
- `lg`: 24pt, `xl`: 32pt, `xxl`: 48pt

### Modifiers
- `.cardStyle()` - Elevated card with gradient overlay
- `.screenPadding()` - Standard horizontal padding
- `.buttonStyle(.primary)` / `.buttonStyle(.secondary)`

## Navigation Pattern

- **Sheets** for create/edit (modal, cancelable)
- **Navigation push** for detail views (back navigation)

```
DashboardView (root)
├── VehiclePickerSheet (sheet)
│   └── AddVehicleView (presented)
├── EditVehicleView (sheet)
├── ServiceDetailView (push from card/row)
│   └── EditServiceView (sheet)
│   └── MarkServiceDoneSheet (sheet)
├── AddServiceView (sheet from quick-add FAB)
```

## Notifications

`NotificationService` handles:
- Permission requests
- Scheduling at 9 AM on due date
- Actions: "Mark as Done", "Remind Tomorrow"
- Delegate handling for foreground/action responses

Configure in `checkpointApp.swift` with:
```swift
UNUserNotificationCenter.current().delegate = NotificationService.shared
```

## Widget

Uses App Groups (`group.com.checkpoint.shared`) for shared SwiftData access:
- Small widget: Next upcoming service
- Medium widget: Next 2-3 services

## Testing

Run tests with:
```bash
xcodebuild test -scheme checkpoint -destination 'platform=iOS Simulator,name=iPhone 16'
```

Test coverage targets:
- Models: 90%+ (computed properties, validation, relationships)
- Services: 80%+ (mocked dependencies)
- Views: Key interactions tested

## Common Tasks

### Adding a new Service Type Preset
1. Add to `Resources/ServicePresets.json`
2. Include `name`, `category`, `defaultIntervalMonths`, `defaultIntervalMiles`

### Adding a new Status Color
1. Add color to `Assets.xcassets/Colors/`
2. Add static property in `Theme.swift`
3. Update `ServiceStatus.color` in `Service.swift`

### Creating a new View
1. Follow existing patterns in `Views/` directory
2. Use `Theme` colors, `Spacing` tokens, `Typography` fonts
3. Add `#Preview` with in-memory model container
4. Create corresponding test file in `checkpointTests/Views/`

## Important Notes

- All data persisted via SwiftData with automatic iCloud sync (when configured)
- Widget requires App Group capability on both main app and widget targets
- Notifications require authorization - check `isAuthorized` before scheduling
- Service due status considers both date AND mileage thresholds

## Xcode Setup Required

Before building, configure the following in Xcode:

### 1. Widget Extension Target
1. File > New > Target > Widget Extension
2. Name it "CheckpointWidget"
3. Add the files from `CheckpointWidget/` directory to the new target

### 2. App Groups Capability
Add `group.com.checkpoint.shared` capability to BOTH targets:
1. Select the main app target > Signing & Capabilities > + Capability > App Groups
2. Add `group.com.checkpoint.shared`
3. Repeat for the CheckpointWidget target

### 3. Resources
Ensure `ServicePresets.json` is added to "Copy Bundle Resources" in Build Phases

### 4. SourceKit Indexing
After opening the project in Xcode, some "Cannot find X in scope" errors may appear in the IDE. These are SourceKit indexing issues that resolve after:
- Building the project (Cmd+B)
- Giving Xcode time to index the project
- Restarting Xcode if needed

The project compiles successfully despite these transient warnings.

## Widget Data Flow

The widget uses UserDefaults (via App Groups) for data sharing:
1. Main app calls `WidgetDataService.shared.updateWidget(for: vehicle)` when data changes
2. Data is serialized to JSON and stored in shared UserDefaults
3. Widget reads from UserDefaults via `WidgetProvider.loadEntry()`
4. `WidgetCenter.shared.reloadAllTimelines()` triggers widget refresh
