# Feature Discovery Integration Guide

This directory contains the feature discovery system for displaying one-time contextual hints.

## Files

| File | Purpose |
|------|---------|
| `FeatureHintView.swift` | Brutalist-styled hint component |
| `/Utilities/FeatureDiscovery.swift` | Singleton tracking hint visibility |

## How It Works

1. **FeatureDiscovery** tracks which hints have been seen using UserDefaults
2. **FeatureHintView** displays hints inline near the feature they describe
3. User taps "GOT IT" → hint dismisses permanently
4. Hint never appears again (survives app restart)

## Available Features

| Feature | Icon | Message | Where to Place |
|---------|------|---------|----------------|
| `.vinLookup` | `barcode.viewfinder` | "Scan your VIN to auto-fill vehicle details" | After VIN input section |
| `.odometerOCR` | `camera.viewfinder` | "Point your camera at the odometer to capture mileage" | After odometer input field |
| `.swipeNavigation` | `hand.draw` | "Swipe left or right to switch tabs" | Bottom of HomeTab |
| `.serviceBundling` | `square.stack.3d.up` | "Services due around the same time are grouped together" | When first cluster appears |

## Usage Pattern

### Basic Usage

```swift
import SwiftUI

struct MyView: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Your content...

            // Show hint if never seen before
            if FeatureDiscovery.shared.shouldShowHint(for: .vinLookup) {
                FeatureHintView(for: .vinLookup)
            }
        }
    }
}
```

### With Custom Text (if needed)

```swift
if FeatureDiscovery.shared.shouldShowHint(for: .vinLookup) {
    FeatureHintView(
        feature: .vinLookup,
        icon: "barcode.viewfinder",
        message: "Custom message here"
    )
}
```

## Integration Examples

### 1. VIN Lookup Hint
**File:** `checkpoint/Views/Vehicle/AddVehicleFlow/VehicleDetailsStep.swift`
**Location:** After VIN input section (line ~56)

```swift
// VIN Section
VStack(alignment: .leading, spacing: Spacing.sm) {
    InstrumentSectionHeader(title: "Identification")

    VINInputSection(formState: formState)

    // Feature hint: VIN scanning
    if FeatureDiscovery.shared.shouldShowHint(for: .vinLookup) {
        FeatureHintView(for: .vinLookup)
    }
}
```

### 2. Odometer OCR Hint
**File:** `checkpoint/Views/Vehicle/AddVehicleFlow/VehicleDetailsStep.swift`
**Location:** After odometer input field (line ~49)

```swift
// Odometer OCR error
if let error = formState.odometerOCRError {
    ErrorMessageRow(message: error) {
        formState.clearOdometerError()
    }
}

// Feature hint: Odometer OCR
if FeatureDiscovery.shared.shouldShowHint(for: .odometerOCR) {
    FeatureHintView(for: .odometerOCR)
}
```

### 3. Swipe Navigation Hint
**File:** `checkpoint/Views/Tabs/HomeTab.swift`
**Location:** Bottom of ScrollView content (after recent activity feed)

```swift
// Recent Activity
RecentActivityFeed(
    serviceLogs: recentServiceLogs,
    mileageSnapshots: recentMileageSnapshots
)

// Feature hint: Tab swipe navigation
if FeatureDiscovery.shared.shouldShowHint(for: .swipeNavigation) {
    FeatureHintView(for: .swipeNavigation)
        .padding(.top, Spacing.lg)
}
```

### 4. Service Bundling Hint
**File:** `checkpoint/Views/Tabs/ServicesTab.swift` or wherever service clusters are displayed
**Location:** Above first service cluster

```swift
// When clustering is enabled and clusters exist
if ClusteringSettings.shared.isEnabled && serviceClusters.isNotEmpty {
    // Feature hint: Service bundling
    if FeatureDiscovery.shared.shouldShowHint(for: .serviceBundling) {
        FeatureHintView(for: .serviceBundling)
            .padding(.bottom, Spacing.md)
    }

    // Display clusters...
    ForEach(serviceClusters) { cluster in
        ServiceClusterCard(cluster: cluster)
    }
}
```

## App Initialization

Register defaults in `checkpointApp.swift`:

```swift
init() {
    // Register UserDefaults defaults
    FeatureDiscovery.registerDefaults()
    ClusteringSettings.registerDefaults()
    // ...
}
```

## Testing & Debugging

### Reset All Hints (for testing)

```swift
// In Xcode preview or debug build
FeatureDiscovery.shared.resetAllHints()
```

### Reset Specific Hint

```swift
FeatureDiscovery.shared.resetHint(for: .vinLookup)
```

### Check Hint Status

```swift
let shouldShow = FeatureDiscovery.shared.shouldShowHint(for: .vinLookup)
print("VIN lookup hint visible: \(shouldShow)")
```

## Design Notes

### Brutalist Styling
- **Zero corner radius** - Sharp edges
- **Monospace fonts** - `.brutalistSecondary` for message, `.brutalistLabel` for button
- **Amber accent** - Icon and button text
- **2px borders** - Theme.borderWidth with 30% opacity
- **80% opacity background** - Theme.surfaceInstrument

### Animation
- Fade in on appear
- Fade + scale down on dismiss
- Duration: Theme.animationMedium (0.2s)

### Accessibility
- VoiceOver reads message and button
- Button has clear tap target
- High contrast colors meet WCAG AA

## Best Practices

1. **Place hints near the feature** - Don't show VIN hint on the home screen
2. **One hint at a time** - Don't overwhelm users with multiple hints
3. **Show on first relevant interaction** - VIN hint on first vehicle creation
4. **Keep messages concise** - One sentence, action-focused
5. **Use appropriate icons** - SF Symbols that match the feature

## Migration Path

If you need to add a new feature hint:

1. Add case to `FeatureDiscovery.Feature` enum
2. Add message and icon in computed properties
3. Place `FeatureHintView` in appropriate view
4. Test that dismissal persists across app restarts

Example:

```swift
// In FeatureDiscovery.swift
enum Feature: String, CaseIterable {
    case vinLookup
    case odometerOCR
    case swipeNavigation
    case serviceBundling
    case newFeature  // Add here

    var message: String {
        switch self {
        // ...
        case .newFeature:
            return "Your hint message here"
        }
    }

    var icon: String {
        switch self {
        // ...
        case .newFeature:
            return "sf.symbol.name"
        }
    }
}
```

## Files to Modify (When Integrating)

1. `/checkpointApp.swift` - Register defaults
2. `/Views/Vehicle/AddVehicleFlow/VehicleDetailsStep.swift` - VIN and odometer hints
3. `/Views/Tabs/HomeTab.swift` - Swipe navigation hint
4. `/Views/Tabs/ServicesTab.swift` - Service bundling hint (if using clusters)

---

**Note:** This is a lightweight system. Hints are NOT modals or tutorials - they appear inline, contextually, and dismiss permanently when acknowledged.
