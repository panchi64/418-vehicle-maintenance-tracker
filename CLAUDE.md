# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Checkpoint is a vehicle maintenance tracker iOS app built with SwiftUI and SwiftData. Users manage vehicles, log/schedule maintenance services, track costs, and receive notifications when services are due.

**Tech Stack:** SwiftUI, SwiftData, WidgetKit, UserNotifications, Vision (OCR)
**Minimum iOS:** 17.0
**Design:** Dark mode first, amber accent (#E89B3C), brutalist aesthetic (zero corner radius)

## Repository Structure

This is a monorepo with two main directories:

- **`checkpoint-app/`** — iOS app (SwiftUI, SwiftData, WidgetKit, Apple Watch)
- **`checkpoint-website/`** — Marketing website (SolidJS, Solid Start, Tailwind CSS, Cloudflare Pages)

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

### Service Model: Dual-Axis Tracking
- Services track due status on **two parallel axes**: date (`dueDate`) and mileage (`dueMileage`). Any logic that applies to one axis must apply to the other — if you add/change date-based behavior, check the mileage equivalent and vice versa.
- `Service.deriveDueFromIntervals(anchorDate:anchorMileage:)` is the single source of truth for converting intervals into deadlines. All code paths that create or recalculate service deadlines must use this method rather than reimplementing the derivation inline.
- `hasDueTracking` (`dueDate != nil || dueMileage != nil`) gates all upcoming/scheduled views. A service without at least one deadline is invisible to the user.

### Business Logic Placement
- Derivation and computation logic belongs in `@Model` classes, not in views. Views should call model methods, then apply UI-specific overrides if needed (e.g., user-entered custom dates).
- When multiple code paths need the same computation, extract it to one method on the model rather than duplicating across views. If you find yourself writing the same `if let` derivation in two places, that's a signal to consolidate.

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

## Concurrency

- Never use `nonisolated(unsafe)` or `@unchecked Sendable`. For static constants with `Sendable` types (e.g., `String`), use `nonisolated static let` to opt out of actor isolation safely.

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
