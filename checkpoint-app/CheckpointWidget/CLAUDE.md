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

1. Main app calls `WidgetDataService.updateWidget()` when data changes
2. Data serialized to JSON and stored in shared UserDefaults (key: `"widgetData"`)
3. `WidgetCenter.reloadAllTimelines()` triggers widget refresh
4. Widget's `WidgetProvider.getTimeline()` reads from shared UserDefaults

## Interactive Widgets (iOS 17+)

The medium widget includes a "Done" button (checkmark) on the most urgent service.

**Flow:**
1. User taps checkmark button on medium widget
2. `MarkServiceDoneIntent` executes as an App Intent
3. Completion is queued as `PendingWidgetCompletion` in shared UserDefaults
4. Widget timeline reloads to reflect pending state
5. When main app comes to foreground, `WidgetDataService.processPendingWidgetCompletions()` creates the actual `ServiceLog` entry

## UserDefaults Best Practices

- **Do NOT call `synchronize()`** - It's deprecated and unnecessary
- The `widgetData` key contains the app's currently selected vehicle data
- Widget configuration (per-widget vehicle selection) is stored separately by WidgetKit
