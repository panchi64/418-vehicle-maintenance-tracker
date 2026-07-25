# Widget & Watch App -- UX Audit

## Executive Summary

The Checkpoint widget and Apple Watch experiences are well-architected with a strong brutalist aesthetic consistently applied across all surfaces. The iOS widget system covers all five widget families with thoughtful information hierarchy, interactive mark-done functionality, and configurable mileage display modes. The Watch app provides a focused, read-heavy experience with Digital Crown integration for mileage adjustment and service completion. Watch complications mirror the iOS lock screen widgets with appropriate adaptations.

However, several UX issues span from critical data-correctness problems (hardcoded "MI" labels ignoring the user's distance unit preference) to interaction gaps (no confirmation before marking a service done from a widget, no success feedback on the Watch) and missing polish (duplicated helper code across files, inconsistent empty states). The most impactful improvements center on honoring the user's unit preferences everywhere, adding confirmation/undo for destructive one-tap actions, and improving data freshness communication.

---

## Strengths

1. **Consistent brutalist aesthetic across all surfaces.** Monospace typography, ALL CAPS labels, zero-radius rectangles, 2px dividers, and status-colored squares are applied uniformly across iOS widgets, Watch app, and Watch complications. The design language is unmistakable.

2. **Thoughtful information hierarchy in small and medium widgets.** The small widget leads with vehicle name, then service name, then a large numeric display with contextual label ("DUE AT" / "REMAINING"), and finally a status indicator. The medium widget splits into a focus panel (next service) and an upcoming panel (2-3 more services). Both are glanceable in under 2 seconds.

3. **Interactive widget with pending-completion pipeline.** The mark-done button on both small and medium widgets writes to `PendingWidgetCompletion` in App Group UserDefaults, the widget immediately filters out the completed service from its timeline, and the main app processes the pending completion on foreground. This is a well-designed async handoff pattern.

4. **Configurable widget with three parameters.** Vehicle selection (including "Match App" default), mileage display mode (absolute vs. relative), and distance unit (match app / miles / km) give users meaningful customization without overwhelming them.

5. **Watch app optimistic updates.** Both mileage updates and mark-service-done send the message to the phone AND immediately update the local data store. This means the UI responds instantly even if the phone is not reachable.

6. **Offline resilience with `transferUserInfo` fallback.** When the phone is not reachable, Watch actions are queued via `transferUserInfo` for eventual delivery. The UI shows "WILL SYNC WHEN PHONE IS NEARBY" to set expectations.

7. **Stale data indicator.** The Watch services list shows "DATA MAY BE OUTDATED" when the data is older than 1 hour, helping users understand data freshness.

8. **Lock screen / accessory widgets cover all families.** Inline, circular, rectangular (iOS), plus inline, circular, rectangular, and corner (watchOS) are all implemented with appropriate information density for each size.

9. **Status color system is immediately parseable.** Red = overdue, yellow = due soon, green = good, gray = neutral. The 8x8pt status square is a strong micro-affordance that works at every size.

10. **Per-vehicle widget data keys.** The widget provider supports both "Match App" (reads `widgetData`) and explicit per-vehicle selection (reads `widgetData_{vehicleID}`), allowing users to pin different vehicles to different widget instances.

---

## Issues Found

### Critical

**C1. Watch app and Watch complications hardcode "MI" -- ignoring user's distance unit preference**
- **Location:** `ServicesListView.swift:79`, `MarkServiceDoneView.swift:47`, `MileageUpdateView.swift:29`, `WatchInlineView.swift:38`
- **Description:** The Watch app displays mileage with a hardcoded "MI" label everywhere. If the user has set their preference to kilometers in the app, the Watch still shows "MI". The Watch inline complication also hardcodes "MI" in its `formatDue()` method. This creates a data trust problem -- users in metric countries will see incorrect unit labels.
- **Impact:** Users who use kilometers see misleading unit labels. The mileage values themselves are also likely stored in miles (the app's internal unit) and not converted to kilometers for display.
- **Fix:** The Watch data payload (`WatchVehicleData`) should include the user's distance unit preference. The Watch app and complications should format mileage using that preference, similar to how the iOS widget uses `WidgetDistanceUnit`.

**C2. No confirmation or undo for widget "Mark Done" action**
- **Location:** `MarkServiceDoneIntent.swift:37-50`, `SmallWidgetView.swift:85-106`, `MediumWidgetView.swift:178-199`
- **Description:** Tapping the "DONE" button on a widget immediately marks the service as completed with no confirmation dialog, no undo, and no visual feedback beyond the service disappearing from the timeline. On the small widget especially, the button is close to other tappable areas, making accidental taps likely. The intent uses the vehicle's current mileage (which may be stale) as the mileage at service, with no option to correct it.
- **Impact:** Accidental taps create incorrect service log entries. The user must open the app to find and delete the erroneous log. Since widgets are frequently touched while rearranging the home screen, this is a realistic scenario.
- **Fix:** Consider either (a) having the widget open the app to a confirmation sheet with pre-filled data, or (b) showing a brief "undo" toast in the widget after marking done. At minimum, add a `.invalidatableContent()` modifier and show a brief "LOGGED" state before the service disappears.

**C3. Widget mark-done uses stale mileage without warning**
- **Location:** `MarkServiceDoneIntent.swift:31`, `SmallWidgetView.swift:88`, `MediumWidgetView.swift:181`
- **Description:** The `MarkServiceDoneIntent` records `mileageAtService` as `entry.currentMileage`, which is whatever mileage was cached in the App Group UserDefaults when the widget timeline was last built (up to 1 hour old). If the user has driven significantly since the last timeline update, the logged mileage will be inaccurate.
- **Impact:** Service log entries may have incorrect mileage, throwing off "miles remaining" calculations for recurring services.
- **Fix:** Either (a) refresh mileage from UserDefaults at intent execution time rather than using the timeline entry's cached value, or (b) open the app to a pre-filled confirmation screen where the user can adjust mileage.

### Major

**M1. Medium widget "MARK DONE" button applies to the first (most urgent) service but is placed in the right panel**
- **Location:** `MediumWidgetView.swift:164-168, 173-199`
- **Description:** The "MARK DONE" button is rendered at the bottom of the right panel (the "UPCOMING" services panel), but it actually marks the *first* service (displayed in the left panel) as done. This spatial disconnect is confusing -- the button appears next to the upcoming services but acts on the primary service shown on the opposite side of the widget.
- **Impact:** Users may think the button applies to the nearest listed service, or may not realize which service they are completing.
- **Fix:** Move the "MARK DONE" button to the bottom of the left panel (below the primary service's status indicator), or clearly label which service is being completed.

**M2. Watch mark-done has no success feedback -- auto-dismisses after 500ms with no confirmation**
- **Location:** `MarkServiceDoneView.swift:104-123`
- **Description:** After tapping "MARK DONE" on the Watch, the view sets `isConfirming = true` to disable the button, waits 500ms, then dismisses. There is no haptic feedback, no checkmark animation, and no success message. The user sees the button briefly disable, then the view pops away. If the send failed silently (encoding error at line 82), the user has no indication.
- **Impact:** Users are left uncertain whether the action succeeded. The 500ms delay is long enough to notice but too short to read any hypothetical feedback.
- **Fix:** Add haptic feedback (`WKInterfaceDevice.current().play(.success)`), show a brief checkmark overlay or "DONE" confirmation before dismissing, and handle the encoding error case visibly.

**M3. Watch mileage update has no success feedback either**
- **Location:** `MileageUpdateView.swift:97-114`
- **Description:** Same pattern as M2: tap "SAVE", button disables for 500ms, view dismisses. No haptic, no visual confirmation.
- **Fix:** Add `.sensoryFeedback(.success, trigger:)` or `WKInterfaceDevice.current().play(.success)`, show a brief "SAVED" state.

**M4. Digital Crown step size of 1 is impractical for mileage adjustment**
- **Location:** `MarkServiceDoneView.swift:89-95`, `MileageUpdateView.swift:68-74`
- **Description:** Both the mark-done and mileage update views use `.digitalCrownRotation(by: 1)` with a range of 0-999,999. To adjust mileage by 1,000 miles (a common scenario), the user must scroll the crown 1,000 detents. Even with the quick-adjust buttons (only available on the mileage update view, not on mark-done), the +/-100 buttons require 10 taps to change by 1,000.
- **Impact:** Adjusting mileage via Digital Crown is essentially unusable for meaningful changes. Users will resort to the quick-step buttons exclusively, but those aren't available on the mark-done view at all.
- **Fix:** Increase step size to 10 or 50 for the Digital Crown. Add quick-adjust buttons (+/-100, +/-1000) to the mark-done view too. Consider dynamic acceleration (step size increases with rotation speed).

**M5. Watch services list is capped at 3 items with no indication of more**
- **Location:** `ServicesListView.swift:51`
- **Description:** `services.prefix(3)` hard-caps the list at 3 services. If the user has 5+ tracked services, 2+ are silently hidden with no "and N more" indicator and no way to see them on the Watch.
- **Impact:** Users may not realize they have additional overdue or due-soon services beyond the top 3.
- **Fix:** Add a "N MORE SERVICES" row at the bottom when `services.count > 3`, or show a count badge. Alternatively, remove the cap and let the list scroll naturally (Watch lists are designed for scrolling).

**M6. Empty widget state shows "No Vehicle" with no call to action**
- **Location:** `SmallWidgetView.swift:111-116`, `MediumWidgetView.swift:118-123`
- **Description:** When no vehicle data is available, both widget sizes show "NO SERVICES" (which is inaccurate -- the problem is no vehicle, not no services). The empty entry's `vehicleName` is "No Vehicle" which displays but gives no guidance.
- **Impact:** New users who add a widget before configuring the app see a confusing state with no instruction on what to do.
- **Fix:** When `entry.vehicleID == nil && entry.services.isEmpty`, show a distinct empty state like "TAP TO SET UP" or "ADD A VEHICLE IN CHECKPOINT". Use `widgetURL` or `Link` to deep-link into the app's vehicle setup.

**M7. iOS widget inline text may truncate aggressively**
- **Location:** `AccessoryInlineView.swift:18`
- **Description:** The inline widget concatenates `vehicleName + ": " + serviceName + " . " + dueInfo` into a single line. For a vehicle like "2020 Honda Civic" and a service like "Brake Inspection", the string becomes `"2020 HONDA CIVIC: BRAKE INSPECTION . 5D"` which is 44+ characters. Inline widgets typically display ~25-30 characters.
- **Impact:** Most of the useful information (service name, due info) gets truncated because the vehicle name consumes the available space.
- **Fix:** Drop the vehicle name from inline widgets (it's already implied by context), or abbreviate it to initials (e.g., "2020 HC"). Lead with the most important info: the service name and due status.

### Minor

**m1. Duplicated display helper methods across SmallWidgetView and MediumWidgetView**
- **Location:** `SmallWidgetView.swift:130-200`, `MediumWidgetView.swift:203-272`
- **Description:** `displayLabel(for:)`, `displayValue(for:)`, `displayUnit(for:)`, `statusLabel(for:)`, `formatMileage(_:)`, and `formatNumber(_:)` are identical in both views. This is a maintenance risk -- a fix in one must be replicated in the other.
- **Fix:** Extract shared display helpers into a shared utility (e.g., `WidgetDisplayHelpers.swift` or an extension on `WidgetService`).

**m2. Duplicated `abbreviate(_:)` method across 4 files**
- **Location:** `AccessoryCircularView.swift:37-39`, `WatchCircularView.swift:37-39`, `WatchCornerView.swift:37-39`, `WatchInlineView.swift` (inline via `formatDue`)
- **Description:** The same "take first word, uppercase it" logic is copy-pasted across multiple files.
- **Fix:** Extract into a shared string extension or utility.

**m3. Duplicated `statusIcon(for:)` in iOS accessory views**
- **Location:** `AccessoryCircularView.swift:41-48`, `AccessoryInlineView.swift:53-59`
- **Description:** Both iOS accessory views define the same `statusIcon(for:)` method. The Watch widgets use `status.icon` computed property instead (which is better).
- **Fix:** Add an `icon` computed property to `WidgetServiceStatus` (like `WatchWidgetStatus` already has) and remove the duplicated methods.

**m4. Watch inline complication hardcodes "MI" in formatDue**
- **Location:** `WatchInlineView.swift:38`
- **Description:** `formatDue` always appends "MI" regardless of user preference. If the due description says "500 kilometers remaining", it would extract "500" and format it as "500 MI" -- showing the wrong unit with the wrong value.
- **Fix:** The Watch widget should receive distance unit preference in the data payload and use it consistently.

**m5. iOS widget `containerBackground` is applied twice on small widget**
- **Location:** `SmallWidgetView.swift:121-127`, `CheckpointWidget.swift:48-50`
- **Description:** `SmallWidgetView` defines its own `.containerBackground` with a `ZStack` of `backgroundPrimary` + white overlay, AND the parent `CheckpointWidgetEntryView` wraps all families in `.containerBackground { WidgetColors.backgroundPrimary }`. The inner one wins, but the outer one is dead code for all families that define their own (only small and medium do; accessory widgets don't need it).
- **Fix:** Either remove the outer containerBackground in `CheckpointWidget.swift` (since each view handles its own) or remove the inner ones and use only the outer one. Be consistent.

**m6. Watch corner complication uses `AccessoryWidgetBackground()` which may be visually wrong**
- **Location:** `WatchCornerView.swift:19`
- **Description:** The `accessoryCorner` family is designed to curve along the watch face corner. Using `AccessoryWidgetBackground()` inside a `ZStack` may produce an opaque circular background that doesn't match corner complication expectations. Corner complications typically use `widgetLabel` for text and a simple icon/gauge -- not a filled background.
- **Impact:** The complication may look like a circular blob in the corner of the watch face rather than a clean corner element.
- **Fix:** Remove `AccessoryWidgetBackground()` from the corner view and use a simpler layout (just the icon with `.widgetLabel` for the text).

**m7. Empty state inconsistency: iOS rectangular says "NO SERVICES DUE" with green bar, Watch rectangular says the same but with different semantics**
- **Location:** `AccessoryRectangularView.swift:43-51`, `WatchRectangularView.swift:43-53`
- **Description:** When there are no services, the rectangular widgets show a green bar + "NO SERVICES DUE". This is fine if the user truly has no upcoming services. But if the widget has no data at all (no vehicle configured), the same message appears, which is misleading -- it implies all maintenance is up to date when really no data exists.
- **Fix:** Distinguish between "no services due" (green -- everything is good) and "no data" (gray -- need to set up).

**m8. Watch app mileage header does not respect distance unit preference**
- **Location:** `ServicesListView.swift:79`
- **Description:** `"\(displayMileage.formatted()) MI"` hardcodes the "MI" unit suffix. Same issue as C1 but specifically in the vehicle header.

**m9. Watch mark-done view does not have quick-adjust buttons for mileage**
- **Location:** `MarkServiceDoneView.swift:40-95`
- **Description:** The mileage update view has +/-10 and +/-100 quick-adjust buttons, but the mark-done view only provides Digital Crown rotation (step size 1). Users who want to slightly adjust mileage at service time have no practical way to do so on the mark-done screen.
- **Fix:** Add the same quick-adjust button row from `MileageUpdateView` to `MarkServiceDoneView`.

**m10. Watch "CHECKPOINT" navigation title is large and pushes content down**
- **Location:** `ServicesListView.swift:60`
- **Description:** The `.navigationTitle("CHECKPOINT")` in a list creates a large inline title at the top of the Watch screen. On a 41mm watch, this can consume ~30% of the visible area before any service rows appear. The title is branding, not navigation -- it doesn't tell the user where they are.
- **Fix:** Use a shorter title like the vehicle name, or use `.navigationBarTitleDisplayMode(.inline)` to reduce the title's footprint. Alternatively, remove the navigation title entirely and let the vehicle header serve as the contextual label.

**m11. No deep link from iOS widget tap to specific service in the app**
- **Location:** `CheckpointWidget.swift` (no `widgetURL` set), `SmallWidgetView.swift`, `MediumWidgetView.swift`
- **Description:** Tapping anywhere on the widget (outside the mark-done button) opens the app to its default state. There is no `widgetURL` or `Link` configured to open the specific service detail or the Services tab.
- **Impact:** Users who see an overdue service on the widget and tap to investigate must navigate manually within the app.
- **Fix:** Set `.widgetURL(URL(string: "checkpoint://services/\(serviceID)")!)` to deep-link into the relevant service detail view.

**m12. Timeline update frequency of 1 hour may feel stale for "due soon" services**
- **Location:** `WidgetProvider.swift:139`, `WatchWidgetProvider.swift:128`
- **Description:** Both iOS and watchOS widget providers schedule the next timeline update 1 hour from now. For a service that is "due in 1 day", the status could change from "due soon" to "overdue" during that window without the widget updating.
- **Fix:** For entries with services that are close to their due date (< 24 hours), schedule a timeline update at the exact transition time (midnight or the due date). Use multiple timeline entries.

**m13. `WatchWidgetSharedService` decodes `status` as a raw String instead of an enum**
- **Location:** `WatchWidgetProvider.swift:96-103`
- **Description:** The Watch widget provider decodes status as a `String` and then maps it via `mapStatus()`. This is fragile -- if the iPhone app ever changes status naming (e.g., "dueSoon" vs "due_soon"), the mapping silently falls back to `.neutral`.
- **Fix:** Decode directly as `WatchWidgetStatus` enum (which already conforms to `Codable`), or add a `serviceID` field to match the Watch app's approach.

**m14. PendingWidgetCompletion has no expiry or deduplication**
- **Location:** `PendingWidgetCompletion.swift:24-36`
- **Description:** Pending completions accumulate indefinitely in UserDefaults. If the main app is never opened (or crashes during processing), the pending list grows. There is no deduplication -- tapping "DONE" twice on the same service before the app processes it creates two pending entries.
- **Impact:** Duplicate service log entries could be created if the user taps the widget button multiple times.
- **Fix:** Add a `Set`-based deduplication check on `serviceID` before appending. Add a TTL (e.g., 7 days) and prune expired entries on load.

---

## Detailed Findings

### 1. Widget Glanceability (< 2 seconds)

**Small widget: PASS.** The layout leads with vehicle name (context), service name (what), large number (when), and status square (urgency). All in monospace ALL CAPS. The eye scans top-to-bottom in a natural flow. The `minimumScaleFactor(0.5)` on the number ensures it fits even for 6-digit mileage values.

**Medium widget: PASS with caveat.** The left panel is highly glanceable. The right panel's "UPCOMING" list is secondary but readable. However, the "MARK DONE" button at the bottom-right competes with the upcoming services for attention and can be confused for applying to those services rather than the primary one.

**Lock screen inline: MARGINAL.** The concatenated string is too long for most use cases (see M7). The status icon is useful but the text after it often truncates before the due info is visible.

**Lock screen circular: PASS.** Status icon + abbreviated service name (e.g., "OIL") is effective for the tiny circular format.

**Lock screen rectangular: PASS.** 2px status bar + vehicle name + service name + due description is well-layered.

### 2. Status Color Communication

Colors are used consistently across all surfaces:
- `statusOverdue` (red): immediate attention needed
- `statusDueSoon` (yellow): upcoming deadline
- `statusGood` (green): healthy
- `statusNeutral` (gray): no tracking

The 8x8pt status square in the small widget and Watch rows is a strong micro-indicator. However, the accessory widgets use `.accessoryColor` (system colors) for tinting, which is correct for lock screen rendering (where custom colors are limited by the system).

### 3. Interactive Widget Mark-Done Flow

The flow works: Button -> `MarkServiceDoneIntent.perform()` -> `PendingWidgetCompletion.save()` -> `WidgetCenter.shared.reloadAllTimelines()` -> Widget filters out completed service.

**Gaps:**
- No confirmation before action (C2)
- No visual feedback during/after action
- Uses stale mileage from timeline entry (C3)
- No deduplication if tapped multiple times (m14)
- No expiry on pending completions (m14)

### 4. Widget Configuration

Three parameters are well-chosen:
1. **Vehicle** (entity query with "Match App" default) -- excellent that the default matches the app's current selection
2. **Mileage Display** (absolute vs. relative) -- meaningful for different mental models ("due at 35,000" vs. "500 remaining")
3. **Distance Unit** (match app / miles / km) -- good override capability

**Potential improvement:** Add a "Show Service Count" toggle for the small widget to show "3 due" instead of the next service detail when the user prefers a summary view.

### 5. Watch App Navigation

The Watch app uses a flat `NavigationStack`:
- `ContentView` -> `ServicesListView` (main screen)
  - Navigation link to `MileageUpdateView` (from mileage header)
  - Navigation link to `MarkServiceDoneView` (from service row)

This is appropriately simple for a Watch app. Two taps to reach any action. The vehicle header serves double duty as a mileage update entry point (tapping the mileage row navigates to the mileage editor).

**Gap:** There is no way to switch between vehicles on the Watch. The Watch always shows whatever vehicle the iPhone last synced. Users with multiple vehicles must switch on the phone.

### 6. Watch Digital Crown Interaction

Both `MarkServiceDoneView` and `MileageUpdateView` use `.digitalCrownRotation()` with:
- Range: 0 to 999,999
- Step: 1
- Sensitivity: `.medium`

**Problem:** A step size of 1 means 1 detent = 1 mile/km change. To adjust by 1,000, the user must scroll 1,000 detents. This is effectively unusable (see M4).

The `MileageUpdateView` partially mitigates this with +/-10 and +/-100 quick-adjust buttons, but these are absent from `MarkServiceDoneView` (see m9).

### 7. Watch Data Freshness

**Good:** The `isStale` property (> 1 hour old) triggers "DATA MAY BE OUTDATED" in the services list. The sync error indicator shows connectivity issues.

**Gaps:**
- No "last synced" timestamp visible to the user
- No manual "refresh" pull-to-refresh gesture
- The stale threshold (1 hour) is reasonable but not configurable
- Watch complications have no stale indicator -- they show data without any freshness context

### 8. Watch Complications

Four families are supported: circular, rectangular, inline, corner.

- **Circular:** Status icon + abbreviated name. Effective.
- **Rectangular:** 2px status bar + vehicle + service + due. Good information density.
- **Inline:** Vehicle + service + abbreviated due. Too long, will truncate (same as iOS inline).
- **Corner:** Status icon with widget label. Functional but the `AccessoryWidgetBackground()` may render incorrectly (see m6).

**Gap:** Watch complications use `StaticConfiguration` (no user configuration). The user cannot choose which vehicle to display on the complication -- it always shows whatever the Watch app has cached. This is acceptable for single-vehicle users but problematic for multi-vehicle users.

### 9. Phone-to-Watch Data Sync

**iPhone -> Watch:** Uses `WCSession.updateApplicationContext()`. This is the correct API -- it's coalesced (only the latest data is delivered) and survives app termination.

**Watch -> iPhone:** Uses `sendMessage` with fallback to `transferUserInfo`. Messages are delivered immediately when reachable; queued for later when not.

**Gaps:**
- No retry logic if `sendMessage` fails and `transferUserInfo` also fails (e.g., outstanding transfer limit reached)
- The `lastSyncError` is cleared when phone becomes reachable, even if no new data has been received
- No handling for the case where Watch data store and iPhone get out of sync (e.g., user deletes a vehicle on iPhone while Watch has cached services for it)

### 10. Widget Previews / Placeholders

Both iOS and watchOS widgets define `.placeholder` entries with realistic sample data:
- Vehicle: "My Vehicle" / "MY VEHICLE"
- Services: Oil Change (due soon), Tire Rotation (good), Brake Inspection (overdue)
- Mileage: 34,500

These are well-crafted for the widget gallery. The `.empty` entries show clean empty states.

---

## Code Quality Issues

### CQ1. Massive code duplication between SmallWidgetView and MediumWidgetView
- `displayLabel`, `displayValue`, `displayUnit`, `statusLabel`, `formatMileage`, `formatNumber` are identical in both files (~70 lines each).
- **Risk:** Bug fixes must be applied in two places. If one is missed, the small and medium widgets diverge.

### CQ2. Three separate color enums for the same concept
- `WidgetColors` (iOS widget), `WatchColors` (Watch app), `WatchWidgetColors` (Watch widget) define overlapping but not identical color sets.
- Status colors differ: iOS widget uses custom RGB values while Watch uses system colors. This is partially intentional (system colors tint better on lock screen), but the accent color `#E89B3C` is defined identically in all three -- a candidate for a shared constant.

### CQ3. Three separate status enums for the same concept
- `WidgetServiceStatus`, `WatchServiceStatus`, `WatchWidgetStatus` are all `{overdue, dueSoon, good, neutral}` with the same raw values. The Watch widget decodes status as a raw `String` and maps manually instead of using the enum's `Codable` conformance.

### CQ4. `WatchWidgetSharedService` omits `serviceID` field
- The Watch widget's `WatchWidgetSharedService` struct does not include `serviceID`, even though the Watch app's `WatchService` does. This means Watch complications cannot support interactive mark-done in the future without a data model change.

### CQ5. `MarkServiceDoneIntent` parameter `mileage` is `Int` but `MarkServiceDoneView.mileage` is `Double`
- The iOS widget intent uses `Int` for mileage, while the Watch mark-done view uses `Double` (for Digital Crown binding, which requires `Double`). The Watch converts back to `Int` at send time. This asymmetry is functional but could cause confusion during maintenance.

### CQ6. The `formatDue()` method in `AccessoryInlineView` parses structured data by string matching
- `AccessoryInlineView.formatDue()` searches for "MILES", "OVERDUE", "REMAINING" in the due description string. This is fragile -- if the main app ever changes the phrasing (e.g., "miles left" instead of "remaining"), the parsing breaks silently and falls through to the raw string.
- Better approach: Pass structured data (miles remaining, days remaining) to the widget and format it locally, rather than parsing a pre-formatted description string.

### CQ7. Watch `ContentView` is a trivial wrapper
- `ContentView.swift` contains only a `NavigationStack` wrapping `ServicesListView()`. This is a non-issue functionally but is unnecessary indirection -- the `NavigationStack` could be in `CheckpointWatchApp.body` directly, or `ServicesListView` could include it.

---

## Recommendations

### Priority 1 (Fix Before Ship)

1. **Honor distance unit preference on Watch** (C1, m4, m8). Include `distanceUnit` in `WatchVehicleData` and `WatchApplicationContext`. Update all Watch views and complications to format mileage through a unit-aware helper.

2. **Add confirmation for widget mark-done** (C2). At minimum, have the widget open the app to a pre-filled "Confirm Service Completion" sheet. Alternatively, implement a two-state widget: first tap shows "CONFIRM?", second tap executes.

3. **Deduplicate pending completions** (m14). Check `serviceID` before appending to the pending list. Add a 7-day TTL and prune expired entries.

### Priority 2 (High-Impact Polish)

4. **Fix medium widget button placement** (M1). Move "MARK DONE" to the left panel, below the primary service info.

5. **Add haptic and visual feedback to Watch actions** (M2, M3). Play `.success` haptic, show brief checkmark overlay, then dismiss after 800ms instead of 500ms.

6. **Increase Digital Crown step size** (M4). Use `by: 10` or `by: 50` for mileage adjustment. Add +/-100 and +/-1000 quick-adjust buttons to `MarkServiceDoneView`.

7. **Improve inline widget truncation** (M7). Drop vehicle name or abbreviate to 3-4 characters. Lead with service name and due info.

8. **Show count when services are capped** (M5). Add a "N MORE" indicator when `services.count > 3` on the Watch.

### Priority 3 (Quality of Life)

9. **Extract shared widget display helpers** (m1, m2, m3). Create `WidgetDisplayHelpers.swift` shared between small and medium views. Unify `abbreviate()` and `statusIcon()` into extensions.

10. **Add deep linking from widget tap** (m11). Set `widgetURL` to open the relevant service or the Services tab.

11. **Improve empty states** (M6, m7). Distinguish "no vehicle" from "no services due". Add setup guidance for unconfigured widgets.

12. **Fix corner complication rendering** (m6). Remove `AccessoryWidgetBackground()` from `WatchCornerView`.

13. **Schedule smarter timeline updates** (m12). For near-due services, schedule a timeline entry at the exact status transition time.

14. **Unify status enums and color systems** (CQ2, CQ3). Consider a shared Swift package or shared file target for common types.
