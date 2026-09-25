# CheckpointWidget - Home Screen Widget

This directory contains the WidgetKit extension for home screen widgets.

## Widget Sizes

| Size | Content | Layout |
|------|---------|--------|
| Small | Next 1 service | Single card |
| Medium | Next 2-3 services | Horizontal list with interactive Done button |

## App Groups Configuration

**Identifier:** `group.com.418-studio.checkpoint.shared`

Both the main app and widget extension must have this App Group enabled in their entitlements.

## Data Flow

Two triggers write the shared snapshot and reload timelines:

**App-foreground path:**
1. Main app calls `WidgetDataService.updateWidget()` when data changes
2. Data serialized to JSON and stored in shared UserDefaults (key: `"widgetData"`)
3. `WidgetCenter.reloadAllTimelines()` triggers widget refresh
4. Widget's `WidgetProvider.getTimeline()` reads from shared UserDefaults

**CloudKit remote-change path:**
`WidgetDataService` observes `.NSPersistentStoreRemoteChange` (debounced) and, on
each remote change, `handleRemoteChange` re-serializes every vehicle's snapshot from
the synced model store before reloading timelines once — so the widget reflects data
another device pushed, not the stale JSON it superseded.

## Interactive Widgets (iOS 17+)

The medium widget includes a "Done" button (checkmark) on the most urgent service.

**Flow:**
1. User taps checkmark button on medium widget
2. `MarkServiceDoneIntent` executes as an App Intent
3. Completion is queued as `PendingWidgetCompletion` in shared UserDefaults
4. Widget timeline reloads to reflect pending state
5. When main app comes to foreground, `WidgetDataService.processPendingWidgetCompletions()` creates the actual `ServiceLog` entry

## Tap → Service Detail (no URL scheme)

The app registers no URL scheme (security invariant), so no `widgetURL`/`Link`. Service rows and heroes wrap in `OpenServiceButton` → `OpenServiceIntent` (`supportedModes = .foreground`, runs in the app). It stores a `PendingWidgetRoute` in the App Group and posts `PendingWidgetRoute.queuedNotification`; `ContentView.consumePendingWidgetRoute()` takes it (on that post or on `enterForeground`) and sets `NotificationService.pendingRoute = .services(...)`, reusing notification navigation. `Shared/PendingWidgetRoute.swift` is compiled into both targets (SharedEntities group in the pbxproj).

## Rendering Modes & Type

- Status is always shape + word (`WidgetStatusTag` / `WidgetStatusMark`): overdue filled square, due soon outlined square, on track short rule. In `.accented`/`.vibrant` (tinted, clear, Lock Screen) marks draw in `.primary` — never rely on hue.
- Hero figure and status tag are `widgetAccentable()`. The cerulean `containerBackground` is removable (StandBy, tinted/clear).
- System content margins — no `contentMarginsDisabled()`, no manual outer padding.
- Fonts are text styles (`Font.widget*`); only `WidgetNumeral` uses a size, scaled relative to `.largeTitle`.
- Mileage figures only move on app writes, so `ServiceEntry.updatedAt` drives an "AS OF" cue (always on medium; small/rectangular once it predates today).

## UserDefaults Best Practices

- **Do NOT call `synchronize()`** - It's deprecated and unnecessary
- The `widgetData` key contains the app's currently selected vehicle data
- Widget configuration (per-widget vehicle selection) is stored separately by WidgetKit
