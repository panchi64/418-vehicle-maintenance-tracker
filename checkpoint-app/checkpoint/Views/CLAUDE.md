# Views - UI Layer

This directory contains all SwiftUI views organized by feature area.

## Directory Structure

```
Views/
├── Tabs/                # Main tab views
│   ├── HomeTab.swift
│   ├── ServicesTab.swift
│   ├── CostsTab.swift
│   └── CostsTab+Analytics.swift  # Analytics computed properties extension
├── Vehicle/             # Vehicle CRUD views
│   ├── AddVehicleView.swift
│   ├── EditVehicleView.swift
│   └── VehiclePickerSheet.swift
├── Service/             # Service CRUD views
│   ├── AddServiceView.swift
│   ├── EditServiceView.swift
│   ├── ServiceDetailView.swift
│   └── MarkServiceDoneSheet.swift
├── Settings/            # Settings views
│   └── SettingsView.swift
└── Components/          # Reusable UI components
    ├── Attachments/     # Photo/document handling
    ├── Camera/          # Vision framework OCR views
    ├── Cards/           # Dashboard cards
    ├── Inputs/          # Form input controls
    ├── Lists/           # List/timeline components
    ├── Navigation/      # Navigation & structural
    └── Sync/            # Data sync UI
```

## Component Subdirectories

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
| `OCRProcessingIndicator.swift` | Processing state during OCR operations |
| `OdometerCameraView.swift` | Camera viewfinder for odometer |
| `OdometerCaptureView.swift` | Full capture flow with guidance |

### Components/Cards/
| Component | Purpose |
|-----------|---------|
| `CategoryBreakdownCard.swift` | Cost breakdown by category with proportion bar |
| `CostSummaryCard.swift` | Total spent hero card |
| `CumulativeCostChartCard.swift` | Area chart showing cumulative spending pace (Swift Charts) |
| `MonthlyBreakdownCard.swift` | Monthly cost summary with bars (legacy, replaced by MonthlyTrendChartCard) |
| `MonthlyTrendChartCard.swift` | Vertical bar chart of monthly spending, stacked by category (Swift Charts) |
| `NextUpCard.swift` | Hero card for most urgent service |
| `QuickMileageUpdateCard.swift` | Inline mileage entry card |
| `QuickSpecsCard.swift` | Vehicle specs display |
| `QuickStatsBar.swift` | Summary statistics bar |
| `RecallAlertCard.swift` | NHTSA recall warning |
| `StatsCard.swift` | Compact stat display (label + value) |
| `YearlyCostRoundupCard.swift` | Annual cost summary |

### Components/Inputs/
| Component | Purpose |
|-----------|---------|
| `ErrorMessageRow.swift` | Inline error message with dismiss button |
| `InstrumentSegmentedControl.swift` | Styled segmented control |
| `InstrumentTextField.swift` | Styled text field |
| `MarbetePicker.swift` | Month/year picker for PR registration |
| `MileageInputField.swift` | Formatted mileage input with commas |
| `ServiceTypePicker.swift` | Service preset selector |

### Components/Lists/
| Component | Purpose |
|-----------|---------|
| `ExpenseRow.swift` | Service log expense item display |
| `ListDivider.swift` | Consistent list divider with configurable padding |
| `MaintenanceTimeline.swift` | Chronological service history |
| `RecentActivityFeed.swift` | Recent actions list |
| `ServiceRow.swift` | Service list item with status |

### Components/Navigation/
| Component | Purpose |
|-----------|---------|
| `BrutalistTabBar.swift` | Custom tab bar |
| `EmptyStateView.swift` | Standardized empty state with icon, title, message |
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

## Navigation Patterns

### Sheets (Modal)
Used for create/edit operations:
```swift
.sheet(isPresented: $showAddService) {
    AddServiceView(vehicle: vehicle)
}
```

### Push Navigation
Used for detail views:
```swift
NavigationLink(value: service) {
    ServiceRow(service: service)
}
.navigationDestination(for: Service.self) { service in
    ServiceDetailView(service: service)
}
```

## State Patterns

### Environment Objects
`AppState` provides global navigation state:
```swift
@Environment(AppState.self) private var appState
```

### SwiftData Queries
Views query data declaratively:
```swift
@Query(sort: \Vehicle.name) private var vehicles: [Vehicle]
```

### ModelContext
For mutations:
```swift
@Environment(\.modelContext) private var modelContext

func save() {
    modelContext.insert(newVehicle)
}
```

## Form Conventions

Standard form structure:
```swift
Form {
    Section("Details") {
        InstrumentTextField("Name", text: $name)
        // ...
    }

    Section {
        Button("Save") { save() }
            .buttonStyle(.primary)
    }
}
```

## Preview Setup

All views include previews with in-memory data:
```swift
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Vehicle.self, configurations: config)

    return ContentView()
        .modelContainer(container)
}
```
