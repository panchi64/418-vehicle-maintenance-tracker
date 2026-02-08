# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Checkpoint is a vehicle maintenance tracker iOS app built with SwiftUI and SwiftData. Users manage vehicles, log/schedule maintenance services, track costs, and receive notifications when services are due.

**Tech Stack:** SwiftUI, SwiftData, WidgetKit, UserNotifications, Vision (OCR)
**Minimum iOS:** 17.0
**Design:** Dark mode first, amber accent (#E89B3C), brutalist aesthetic (zero corner radius)

## Restricted Files

- **`Secrets.xcconfig`** — Contains API keys. NEVER read, cat, display, or access this file in any way.

## Build & Test Commands

All commands run from `checkpoint-app/` directory:

```bash
# Build
xcodebuild build -scheme checkpoint -destination 'platform=iOS Simulator,name=iPhone 17'

# Run all tests
xcodebuild test -scheme checkpoint -destination 'platform=iOS Simulator,name=iPhone 17'

# Unit tests only
xcodebuild test -scheme checkpoint -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:checkpointTests

# UI tests only (must shutdown simulators first)
xcrun simctl shutdown all && \
xcodebuild test -scheme checkpoint -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:checkpointUITests

# Specific test class
xcodebuild test -scheme checkpoint -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:checkpointTests/VehicleTests
```

**Critical:** Never run multiple xcodebuild commands in parallel - this spawns multiple simulators and causes crashes. Always run tests sequentially.

## Architecture

### State Management
- `AppState` class (in `State/`) uses `@Observable` macro for reactive state
- Manages tab navigation, sheet presentations, vehicle selection
- SwiftData `@Query` for declarative data fetching
- `ModelContext` injected via environment for data mutations

### Navigation
- Tab-based: Home, Services, Costs
- Sheets for create/edit modals
- Push navigation for detail views
- Vehicle selector persists at top of all tabs

## Design System

Use tokens from `DesignSystem/`:
- **Colors:** `Theme.backgroundPrimary`, `Theme.accent`, `Theme.statusOverdue`, etc.
- **Typography:** `Typography.headline`, `Typography.bodyText`, `Typography.caption`, etc.
- **Spacing:** `Spacing.sm` (8pt), `Spacing.md` (16pt), `Spacing.lg` (24pt), etc.
- **Modifiers:** `.cardStyle()`, `.screenPadding()`, `.buttonStyle(.primary)`

## Testing

Test setup uses in-memory ModelContainer:
```swift
let config = ModelConfiguration(isStoredInMemoryOnly: true)
modelContainer = try! ModelContainer(for: Vehicle.self, configurations: config)
```

Tests should verify actual functionality - avoid hacky workarounds that circumvent proper testing.

## Common Tasks

### Adding a new Service Type Preset
1. Add to `Resources/ServicePresets.json`
2. Include `name`, `category`, `defaultIntervalMonths`, `defaultIntervalMiles`

### Adding a new Status Color
1. Add color to `Assets.xcassets/Colors/`
2. Add static property in `Theme.swift`
3. Update `ServiceStatus.color` in `Service.swift`

## Important Notes

- All data persisted via SwiftData with automatic iCloud sync (when configured)
- Widget requires App Group capability on both main app and widget targets
- Notifications require authorization - check `isAuthorized` before scheduling
- Service due status considers both date AND mileage thresholds
- App is portrait-only via `UISupportedInterfaceOrientations` + `UIRequiresFullScreen` in Info.plist

## Feature Tracking

Feature implementation status is tracked in `docs/FEATURES.md`. When implementing new features:
1. Mark the feature as ✅ (implemented) in the Status column
2. Add corresponding tests for the new functionality
3. Commit both the implementation and the status update together

## Additional Documentation

See `docs/` for product strategy, design specs, analytics, and troubleshooting guides. See `docs/ARCHITECTURE.md` for detailed architecture reference (project structure tree, component inventories, service descriptions, data models, widget internals).
