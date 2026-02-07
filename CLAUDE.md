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

### Data Models (in `Models/`)
- **Vehicle:** name, make, model, year, currentMileage, VIN; has many services/serviceLogs/mileageSnapshots
- **Service:** due tracking (date/mileage), intervals, status computation (overdue/dueSoon/good/neutral)
- **ServiceLog:** completed service records with cost, notes, attachments
- **MileageSnapshot:** driving pattern analysis for mileage estimation

### Key Services (in `Services/`)
- **Notifications/:** modular architecture with focused schedulers (Service, Mileage, Marbete, YearlyRoundup); core `NotificationService` uses `@Observable @MainActor`
- **OCR/OdometerOCRService, VINOCRService:** Vision framework OCR for camera capture
- **Utilities/NHTSAService:** VIN decoding and recall alerts via NHTSA API
- **Widget/WidgetDataService:** App Groups data sharing with widget (`@MainActor`)
- **WatchConnectivity/WatchSessionService:** iPhone-side WCSession delegate for Apple Watch communication
- **Sync/CloudSyncStatusService, SyncStatusService:** iCloud sync status monitoring

### Widget Extension
- Uses App Groups: `group.com.418-studio.checkpoint.shared`
- Small widget: next upcoming service
- Medium widget: next 2-3 services
- Data synced via UserDefaults in shared container

### Apple Watch App (CheckpointWatch)
- **Min watchOS:** 10.0
- **Data sync:** WatchConnectivity (`updateApplicationContext` iPhone→Watch, `sendMessage`/`transferUserInfo` Watch→iPhone)
- **Watch App Group:** `group.com.418-studio.checkpoint.watch` (separate from iPhone App Group)
- **No SwiftData on Watch** — lightweight JSON in UserDefaults, iPhone is source of truth
- **Screens:** Services list, mileage update (digital crown), mark service done
- **Complications:** Circular, rectangular, inline, corner (all `.accessory*` families)
- **iPhone integration point:** `WidgetDataService.updateWidgetData()` → `WatchSessionService.sendVehicleData()`

## Project Structure

```
checkpoint-app/
├── checkpoint/
│   ├── Models/           # SwiftData entities (see Models/CLAUDE.md)
│   ├── Views/
│   │   ├── Tabs/         # Home, Services, Costs tabs
│   │   ├── Vehicle/      # Vehicle CRUD views
│   │   ├── Service/      # Service CRUD views
│   │   ├── Settings/     # Settings views
│   │   └── Components/   # Reusable UI components (see Views/CLAUDE.md)
│   │       ├── Attachments/  # Photo/document handling
│   │       ├── Camera/       # Vision framework OCR views
│   │       ├── Cards/        # Dashboard cards
│   │       ├── Inputs/       # Form input controls
│   │       ├── Lists/        # List/timeline components
│   │       ├── Navigation/   # Navigation & structural
│   │       └── Sync/         # Data sync UI
│   ├── DesignSystem/     # Theme, Typography, Spacing tokens (see DesignSystem/CLAUDE.md)
│   ├── Services/         # Business logic services (see Services/CLAUDE.md)
│   │   ├── Notifications/    # Local notification management
│   │   ├── OCR/              # Vision framework services
│   │   ├── Sync/             # iCloud & data sync
│   │   ├── Utilities/        # Single-purpose services
│   │   ├── WatchConnectivity/ # iPhone-side WCSession delegate
│   │   └── Widget/           # Widget data sharing
│   ├── State/            # AppState (@Observable)
│   ├── Utilities/        # Formatters, Settings, helpers
│   └── Resources/        # ServicePresets.json
├── CheckpointWatch/      # watchOS app (services, mileage update, mark done)
├── CheckpointWatchWidget/ # watchOS widget extension (complications)
├── CheckpointWatchTests/ # watchOS unit tests
├── CheckpointWidget/     # WidgetKit extension (see CheckpointWidget/CLAUDE.md)
├── checkpointTests/      # Unit tests (see checkpointTests/CLAUDE.md)
└── checkpointUITests/    # UI tests
```

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

## Feature Tracking

Feature implementation status is tracked in `docs/FEATURES.md`. When implementing new features:
1. Mark the feature as ✅ (implemented) in the Status column
2. Add corresponding tests for the new functionality
3. Commit both the implementation and the status update together

## Additional Documentation

### Product & Strategy (`docs/`)
- `docs/MARKET_RESEARCH.md` - Competitive analysis of the vehicle maintenance app market and positioning strategy
- `docs/ROADMAP.md` - Version milestones and planned feature releases
- `docs/FEATURES.md` - Feature catalog with implementation status tracking
- `docs/MONETIZATION.md` - Pricing and feature tier strategy (free core, optional paid sync, no ads)

### Design & UX (`docs/`)
- `docs/AESTHETIC.md` - Design language and visual philosophy (brutalist-tech-modernist)
- `docs/NOTIFICATION_TONE.md` - Voice and messaging guidelines for notifications (mechanical, dry-humored, vehicle "speaks" to user)
- `docs/UNITS_AND_INTERVALS.md` - UX spec for maintenance tracking units (miles/km/months/days), dual-interval display logic, and user-configurable priority setting

### Data & Reliability (`docs/`)
- `docs/DATA_RELIABILITY.md` - Data strategy, local-first principles, backup/sync architecture, and mileage estimation

### Codebase (`checkpoint-app/`)
- `checkpoint-app/CLAUDE.md` - Detailed iOS development patterns
- `checkpoint-app/checkpoint/Models/CLAUDE.md` - Entity relationships and data patterns
- `checkpoint-app/checkpoint/Services/CLAUDE.md` - Service layer architecture
- `checkpoint-app/checkpoint/Views/CLAUDE.md` - View components and UI patterns
- `checkpoint-app/checkpoint/DesignSystem/CLAUDE.md` - Design tokens and modifiers
- `checkpoint-app/CheckpointWidget/CLAUDE.md` - Widget extension guide
- `checkpoint-app/checkpointTests/CLAUDE.md` - Testing patterns and setup
