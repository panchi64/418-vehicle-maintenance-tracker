# Apple Watch Complication Implementation Plan

## Overview

Add Apple Watch **complications** to Checkpoint - small widgets that appear on watch faces showing at-a-glance vehicle maintenance info. This is NOT a full Watch app; the Watch app target is minimal (required by Apple as a container) but the actual feature is the complications.

**Key insight**: watchOS WidgetKit complications require a Watch app target as a container, but the app itself can be a simple placeholder. Users interact via complications on their watch face, not by launching an app.

## Architecture

```
checkpoint (iOS)
    │
    ├── CheckpointWidget (iOS Widget) ──────────┐
    │       Uses: WidgetProvider, accessory views       │  Shared App Group
    │                                                    │  UserDefaults JSON
    ├── CheckpointWatch (minimal watchOS container) ◄───┤
    │       Just a placeholder - "Open Checkpoint on iPhone"
    │                                                    │
    └── CheckpointWatchComplication (WidgetKit ext) ────┘
            Reuses: accessory views from iOS widget
```

**App Group**: `group.com.418-studio.checkpoint.shared` (already configured)

## Targets to Create

| Target | Type | Purpose |
|--------|------|---------|
| `CheckpointWatch` | watchOS App (10.0+) | **Minimal container** (required by Apple) |
| `CheckpointWatchComplication` | Widget Extension | WidgetKit complications (the actual feature) |

## Complication Families

| Family | Where it appears | Content | View |
|--------|------------------|---------|------|
| `.accessoryCorner` | Corner slots on watch faces | Status + abbrev name | **NEW** |
| `.accessoryCircular` | Circular complication slots | Status icon + abbrev | **REUSE** existing |
| `.accessoryRectangular` | Rectangular slots, Smart Stack | Vehicle + service + due | **REUSE** existing |
| `.accessoryInline` | Single line at top of face | `VEHICLE: SERVICE - DUE` | **REUSE** existing |

## Files to Create

### Watch Complication Extension (the actual feature)
- `CheckpointWatchComplication/CheckpointWatchComplicationBundle.swift` - Entry point
- `CheckpointWatchComplication/WatchComplicationWidget.swift` - Widget config
- `CheckpointWatchComplication/WatchComplicationProvider.swift` - Timeline provider
- `CheckpointWatchComplication/Views/WatchAccessoryCornerView.swift` - Corner-specific view
- `CheckpointWatchComplication/CheckpointWatchComplication.entitlements` - App Group

### Minimal Watch App Container (required by Apple)
- `CheckpointWatch/CheckpointWatchApp.swift` - App entry
- `CheckpointWatch/ContentView.swift` - Simple placeholder view
- `CheckpointWatch/CheckpointWatch.entitlements` - App Group

## Files to Modify

- `CheckpointWidget/Views/AccessoryCircularView.swift` - Add Watch complication target membership
- `CheckpointWidget/Views/AccessoryRectangularView.swift` - Add Watch complication target membership
- `CheckpointWidget/Views/AccessoryInlineView.swift` - Add Watch complication target membership
- `CheckpointWidget/Shared/WidgetColors.swift` - Add Watch complication target membership
- `CheckpointWidget/WidgetProvider.swift` - Extract ServiceEntry/WidgetService to shared file
- `docs/FEATURES.md` - Mark Apple Watch complication as ✅

## Implementation Phases

### Phase 0: Load iOS Development Skill
1. Invoke the `ios-development` skill to load Swift/SwiftUI best practices
2. This ensures proper patterns for watchOS WidgetKit development

### Phase 1: Extract Shared Models
1. Create `CheckpointWidget/Shared/SharedWidgetModels.swift`
2. Move `ServiceEntry`, `WidgetService`, `WidgetServiceStatus` to shared file
3. Update iOS widget imports
4. Verify iOS widgets still work

### Phase 2: Minimal Watch App Container
1. In Xcode: File → New → Target → watchOS App
2. Name: `CheckpointWatch`, embed in `checkpoint`
3. Add App Group entitlement: `group.com.418-studio.checkpoint.shared`
4. Replace ContentView with minimal placeholder:
```swift
struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "car.fill")
                .font(.largeTitle)
            Text("CHECKPOINT")
                .font(.headline)
            Text("Add complication to watch face")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
```

### Phase 3: Watch Complication Extension
1. In Xcode: File → New → Target → Widget Extension (watchOS)
2. Name: `CheckpointWatchComplication`, embed in `CheckpointWatch`
3. Add App Group entitlement
4. Implement `WatchComplicationProvider` (copy loadEntry logic from iOS WidgetProvider)
5. Configure supported families: `.accessoryCorner`, `.accessoryCircular`, `.accessoryRectangular`, `.accessoryInline`
6. Share existing accessory views by adding target membership in Xcode
7. Create `WatchAccessoryCornerView` for corner-specific layout

### Phase 4: Testing
1. Build and run on Watch simulator
2. Add complications to watch face
3. Verify data updates from iOS app
4. Test all 4 complication families
5. Update FEATURES.md

## Complication Content Design

### accessoryCorner (NEW)
```
┌──────────┐
│   [!]    │  ← Status icon
│   OIL    │  ← First word of service
└──────────┘
```

### accessoryCircular (REUSE)
```
   ┌───┐
   │ ! │  ← Status icon
   │OIL│  ← Abbreviated name
   └───┘
```

### accessoryRectangular (REUSE)
```
┌──────────────────────┐
│ ▌DAILY DRIVER        │  ← 2px status bar + vehicle
│  OIL CHANGE          │  ← Service name
│  500 MI REMAINING    │  ← Due description
└──────────────────────┘
```

### accessoryInline (REUSE)
```
CAMRY: OIL CHANGE - 500 MI
```

## Data Flow

1. iOS app calls `WidgetDataService.shared.updateWidget(for:)` on changes
2. Data serialized to JSON in shared App Group UserDefaults
3. `WidgetCenter.shared.reloadAllTimelines()` triggers refresh
4. Watch complication reads from same UserDefaults via `WatchComplicationProvider`

**Timeline refresh**: Every 4 hours (watchOS battery conservation)

## Verification

1. **Build Watch target**:
   ```bash
   xcodebuild build -scheme CheckpointWatch \
     -destination 'platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)'
   ```

2. **Test complications**:
   - Run Watch app in simulator
   - Long-press watch face → Edit → Add complication
   - Select Checkpoint complications
   - Verify all 4 families render correctly

3. **Test data sync**:
   - Update mileage in iOS app
   - Verify Watch complication updates (may need to wait for timeline refresh)

4. **Test empty state**:
   - Delete all vehicles in iOS app
   - Verify complication shows placeholder gracefully

## Sources

- [Creating accessory widgets and watch complications | Apple Developer](https://developer.apple.com/documentation/widgetkit/creating-accessory-widgets-and-watch-complications)
- [Go further with Complications in WidgetKit - WWDC22](https://developer.apple.com/videos/play/wwdc2022/10051/)
- [From ClockKit to WidgetKit - Sleekible](https://www.sleekible.com/2024/02/04/clockkit-to-widgetkit.html)

---

_Created: January 2026_
