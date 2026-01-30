# Views - UI Layer

This directory contains all SwiftUI views organized by feature area.

## Directory Structure

```
Views/
├── Tabs/                # Main tab views
│   ├── HomeTab.swift
│   ├── ServicesTab.swift
│   └── CostsTab.swift
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
| `OdometerCameraView.swift` | Camera viewfinder for odometer |
| `OdometerCaptureView.swift` | Full capture flow with guidance |

### Components/Cards/
| Component | Purpose |
|-----------|---------|
| `NextUpCard.swift` | Hero card for most urgent service |
| `QuickMileageUpdateCard.swift` | Inline mileage entry card |
| `QuickSpecsCard.swift` | Vehicle specs display |
| `QuickStatsBar.swift` | Summary statistics bar |
| `RecallAlertCard.swift` | NHTSA recall warning |
| `YearlyCostRoundupCard.swift` | Annual cost summary |

### Components/Inputs/
| Component | Purpose |
|-----------|---------|
| `InstrumentSegmentedControl.swift` | Styled segmented control |
| `InstrumentTextField.swift` | Styled text field |
| `MileageInputField.swift` | Formatted mileage input with commas |
| `ServiceTypePicker.swift` | Service preset selector |

### Components/Lists/
| Component | Purpose |
|-----------|---------|
| `MaintenanceTimeline.swift` | Chronological service history |
| `RecentActivityFeed.swift` | Recent actions list |
| `ServiceRow.swift` | Service list item with status |

### Components/Navigation/
| Component | Purpose |
|-----------|---------|
| `BrutalistTabBar.swift` | Custom tab bar |
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
