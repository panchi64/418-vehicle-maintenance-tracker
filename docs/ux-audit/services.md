# Services Tab & Service Management -- UX Audit

## Executive Summary

The Services tab and its associated flows form the core operational backbone of Checkpoint. Overall, the architecture is **solid and well-organized** -- the dual-mode Record/Remind approach, preset system, mark-done flow, and service clustering are genuinely thoughtful features. However, the audit uncovered **3 critical issues, 8 major issues, and 12 minor issues** that collectively introduce friction, confusion, and inconsistency across the service management experience. The most impactful problems are: (1) Record mode lacks a "Remind Me Next Time" on by default, making one-off logging the path of least resistance when recurring tracking should be encouraged; (2) MarkClusterDoneSheet is significantly feature-incomplete compared to its single-service counterpart; and (3) EditServiceView does not re-derive due dates from intervals, creating a silent data integrity gap.

---

## Strengths

1. **Record vs Remind dual-mode is a genuinely good idea.** Separating "I did this" from "Remind me to do this" matches real user mental models. The segmented control at the top of AddServiceView makes mode switching low-friction.

2. **Preset system with category browsing.** The ServiceTypePicker provides both a custom text input and a browsable preset sheet organized by category. This covers both power users (type the name) and casual users (browse and pick). Interval auto-fill from presets reduces data entry.

3. **Service clustering.** Detecting nearby-due services and offering "Mark All Done" is a genuine differentiator. The ServiceClusterDetailSheet provides a clear summary with individual service drill-down.

4. **ServiceRow information density.** The row packs status indicator, service name, last-performed context, mini progress bar, and miles/days remaining into a compact layout without feeling cluttered. The pulse animation on urgent items draws attention without being obnoxious.

5. **MaintenanceTimeline.** The timeline view with month groupings, 8x8 square nodes, and 2px spine is a solid brutalist implementation. Mixing upcoming and completed items gives a full picture.

6. **Service detail insights.** ServiceDetailView surfaces time-since-last, miles-since-last, average cost, and times-serviced. This is genuinely useful context that helps users make decisions.

7. **Mark-done sheet pre-fills intelligently.** MarkServiceDoneSheet pre-fills mileage from vehicle's current mileage and shows planned notes from the scheduled service -- reducing friction and preserving context.

8. **Search across OCR text.** ServicesTab search filters across service names, notes, AND extracted text from receipt attachments. This is a power-user feature that most competitors lack entirely.

9. **Accessibility labels.** ServiceRow, ServiceDetailView history rows, and timeline items all include `accessibilityLabel`, `accessibilityValue`, and `accessibilityHint`. Good foundation for VoiceOver support.

10. **Export capability.** The Service History section includes a PDF export button directly in the section header. Discoverable and contextually placed.

---

## Issues Found

### Critical

**C1. "Remind Me Next Time" defaults to OFF in Record mode -- users will forget to set up recurring tracking**

- **File:** `AddServiceView.swift:47` -- `@State private var scheduleRecurring: Bool = false`
- **Impact:** When a user records an oil change, the toggle to schedule the next one is buried under "Reminder" and defaults to off. Most users will tap Save without scrolling down to the Reminder section, resulting in a one-off log with no future tracking. The whole point of a maintenance tracker is to know when things are due next.
- **Recommendation:** When a user selects a preset that has `defaultIntervalMonths` or `defaultIntervalMiles`, auto-enable `scheduleRecurring = true`. The user can still disable it, but the default should match the intent of selecting a preset with intervals. Alternatively, consider a more prominent "Next service" section that appears after the cost/mileage fields.

**C2. MarkClusterDoneSheet is severely feature-incomplete compared to MarkServiceDoneSheet**

- **File:** `MarkClusterDoneSheet.swift`
- **Missing compared to single mark-done:**
  - No cost entry field (comment on line 158 says "User can edit individual logs later" -- but this adds significant friction)
  - No attachment picker
  - No haptic feedback (`HapticService.shared.success()` missing)
  - No toast confirmation (no `ToastService.shared.show(...)`)
  - No analytics event capture
  - No cost category selection
  - No `appState.recordCompletedAction()` call
- **Impact:** Users who use cluster completion (a promoted feature) get a degraded experience. No cost entry means users must go back and edit each log individually -- defeating the purpose of "bundling." Missing haptics and toast make the action feel like it didn't register.
- **Recommendation:** Add cost, cost category, attachments, haptic, toast, and analytics to match MarkServiceDoneSheet parity. Consider per-service cost entry rows within the cluster sheet.

**C3. EditServiceView does not re-derive due dates from updated intervals**

- **File:** `EditServiceView.swift:198-206` -- `saveChanges()` directly sets `service.dueDate` and `service.dueMileage` without calling `deriveDueFromIntervals`.
- **Impact:** If a user edits a service to change `intervalMonths` from 6 to 12, the `dueDate` is NOT automatically recalculated. The old due date remains unless the user also manually toggles the due date. This creates a silent data integrity gap where intervals and deadlines drift out of sync.
- **Recommendation:** When intervals change, offer to re-derive the due date. At minimum, if the user has changed an interval value, call `deriveDueFromIntervals(anchorDate:anchorMileage:)` using `lastPerformed`/`lastMileage` (or current date/mileage if no history) and then apply any user overrides on top.

---

### Major

**M1. Record mode mileage is required but the "Required" placeholder is easy to miss**

- **File:** `AddServiceView.swift:234-239`
- The mileage field uses `placeholder: "Required"` but there is no inline validation message or visual indicator that this is the blocking field when the save button is disabled. Users may wonder why "Save" is grayed out.
- **Recommendation:** Add a red outline or inline error message when the user taps Save with empty mileage. Or mark the field with an asterisk and use `.isRequired: true` like the service name field in EditServiceView.

**M2. Timeline view does not support status filtering or search**

- **File:** `ServicesTab.swift:108-140` -- Status filter and filter indicator are conditionally shown only in list mode (`appState.servicesViewMode == .list`).
- **Impact:** When in Timeline mode, the search field is still visible but the status filter chips disappear. Users can search by text but cannot filter by status (overdue/due soon/good). Timeline shows ALL items including completed logs, making it harder to find specific statuses.
- **Recommendation:** Either apply the existing search filter to timeline items too (it currently only filters `filteredServices` and `filteredLogs` which the timeline doesn't use -- the timeline uses `vehicleServiceLogs` and `services` directly), or clearly communicate that timeline mode shows everything.

**M3. Service history in ServicesTab is not filterable by status**

- **File:** `ServicesTab.swift:67-90` -- `filteredLogs` only applies search text, not status filter.
- **Impact:** The status filter (All/Overdue/Due Soon/Good) only affects the "Upcoming" section. The "Service History" section below always shows all logs matching the search. The filter indicator at line 121 says "SHOWING X OF Y" but only counts `filteredServices`, not logs. This is misleading when a user expects the filter to apply globally.
- **Recommendation:** Either make the filter indicator say "X OF Y UPCOMING SERVICES" to clarify scope, or apply status filtering to history as well (by the status of the parent service).

**M4. No undo/confirmation for service deletion from EditServiceView**

- **File:** `EditServiceView.swift:167-176` -- Delete confirmation dialog exists, but deletion is immediate and permanent with no undo.
- **Impact:** Deleting a service also cascades to delete ALL service logs (line 175: "This will also delete all service history"). A user who accidentally confirms loses all historical data for that service. There is no way to recover.
- **Recommendation:** Consider a soft-delete approach, or at minimum, show the count of logs that will be deleted in the confirmation: "This will delete Oil Change and 12 service history entries. This cannot be undone."

**M5. AddServiceView's Remind mode "When Is It Due?" section has confusing conditional logic**

- **File:** `AddServiceView.swift:324-415`
- The "When Is It Due?" section switches behavior based on whether interval fields are filled. With an interval, it shows a read-only derived date. Without an interval, it shows a toggle to set a custom date. This means:
  - User types interval months -> date appears automatically (good)
  - User clears interval months -> date disappears, replaced by a toggle (confusing)
  - User types interval months AND wants a different date -> no obvious way to override
- **Impact:** The conditional UI is clever but may confuse users who don't understand why the date picker appeared/disappeared. The connection between "Repeat Interval" and "When Is It Due?" sections isn't explicitly communicated.
- **Recommendation:** Add helper text explaining the relationship: "Due date is calculated from your interval. Clear the interval to set a custom date." Or allow an override toggle even when intervals are set.

**M6. ServiceTypePicker preset sheet uses Capsule clip shape -- violates brutalist design system**

- **File:** `ServiceTypePicker.swift:219` -- `.clipShape(Capsule())` on CategoryChip
- **Impact:** The brutalist design system mandates zero corner radius everywhere (`Theme.cardCornerRadius = 0`). The capsule-shaped category filter chips in the preset picker sheet introduce rounded corners, breaking visual consistency.
- **Recommendation:** Replace `Capsule()` with `Rectangle()` to match the brutalist aesthetic.

**M7. ServiceTypePicker preset sheet uses native List style instead of brutalist components**

- **File:** `ServiceTypePicker.swift:122-183` -- Uses `List` with default styling instead of custom VStack with instrument card style.
- **Impact:** The preset picker sheet visually departs from the rest of the app's aesthetic. It uses default iOS List separators, row styling, and section headers instead of `InstrumentSectionHeader`, `Theme.surfaceInstrument` backgrounds, and `Theme.gridLine` borders.
- **Recommendation:** Restyle the picker to use the app's brutalist component library for consistency.

**M8. MarkServiceDoneSheet missing cost category selector**

- **File:** `MarkServiceDoneSheet.swift:74-100` -- Has cost field but no `CostCategory` picker.
- **Impact:** When marking a service done, the user can enter a cost but cannot categorize it (maintenance/repair/upgrade). The ServiceLog is created with `costCategory: nil` (line 153). This means cost analytics on the Costs tab will have uncategorized entries, degrading the quality of category breakdowns.
- **Recommendation:** Add a `CostCategory` segmented control (same as AddServiceView line 221-227) that appears when a cost value is entered.

---

### Minor

**m1. Inconsistent navigation title casing**

- AddServiceView: "Record Service" / "Set Reminder" (Title Case)
- EditServiceView: "Edit Service" (Title Case)
- EditServiceLogView: "Edit Service Log" (Title Case)
- MarkServiceDoneSheet: "Mark as Done" (Sentence Case with lowercase "as")
- MarkClusterDoneSheet: "Mark All Done" (Title Case without "as")
- ServiceClusterDetailSheet: "Bundle Services" (Title Case)
- ServiceLogDetailView: "Service Log" (Title Case)
- **Recommendation:** Standardize to consistent Title Case across all sheets.

**m2. ServiceRow has redundant tap handling**

- **File:** `ServiceRow.swift:103` uses `.tappableCard(action: onTap)`, but the parent `ServicesTab.swift:174-185` wraps it in a `Button` that ALSO sets `appState.selectedService`. This means tapping the row triggers both the Button action AND the tappableCard's onTap -- both of which do the same thing.
- **Recommendation:** Remove either the outer Button wrapper or the inner `onTap` closure to avoid double-handling.

**m3. DateFormatter instances created inline in multiple views**

- **Files:** `AddServiceView.swift:332-336`, `ServiceDetailView.swift:385-388`, `MaintenanceTimeline.swift:252-255`
- Each creates a new `DateFormatter` per view render cycle. While Swift caches formatters internally, this is unnecessary allocation churn.
- **Recommendation:** Use the existing `Formatters.mediumDate` or add new formatters to the `Formatters` enum.

**m4. MaintenanceTimeline mileage-only services default to "30 days from now"**

- **File:** `MaintenanceTimeline.swift:52-58` -- Hardcoded `Date.now.addingTimeInterval(86400 * 30)` for mileage-only services.
- **Impact:** A service that is 10,000 miles away will appear at the same timeline position as one that is 100 miles away -- both show as "30 days from now." This undermines the timeline's temporal accuracy.
- **Recommendation:** Use `service.predictedDueDate(currentMileage:dailyPace:)` (already available on the Service model) to estimate a more accurate timeline position.

**m5. ServicesTab "Upcoming" section title is hardcoded, not localized**

- **File:** `ServicesTab.swift:170` -- `InstrumentSectionHeader(title: "Upcoming")` and line 205 `"Service History"` are hardcoded English strings, not using `L10n`.
- **Recommendation:** Use localized strings for consistency with other localized content.

**m6. EditServiceLogView cannot delete existing attachments**

- **File:** `EditServiceLogView.swift:39-41` -- Existing attachments are shown read-only. Users can add new attachments but cannot remove existing ones.
- **Impact:** If a user accidentally attaches the wrong receipt, they have no way to remove it from the log.
- **Recommendation:** Add delete capability for existing attachments (swipe-to-delete or a remove button).

**m7. MarkClusterDoneSheet "Save" button label is generic**

- **File:** `MarkClusterDoneSheet.swift:54`
- The button says "Save" but the action is marking multiple services as complete. A more descriptive label like "Mark All Done" or "Complete 3 Services" would better communicate the action.
- **Recommendation:** Use `"Mark \(cluster.serviceCount) Done"` or similar.

**m8. ServiceDetailView dismisses after mark-done completes**

- **File:** `ServiceDetailView.swift:86-89` -- When `didCompleteMark` is true, the detail view auto-dismisses.
- **Impact:** After marking a service done, the user is kicked back to the services list. They cannot immediately see the updated status, new due dates, or the log they just created. This breaks the user's context.
- **Recommendation:** Stay on the detail view and let it refresh to show updated status. Users can navigate back manually.

**m9. No empty state explanation for timeline with upcoming-only services**

- **File:** `ServicesTab.swift:144-149` -- Timeline empty state checks `vehicleServiceLogs.isEmpty`, but a user might have scheduled services (upcoming) with no completed logs. The timeline WILL show upcoming items in this case, but the empty state message says "Complete or schedule maintenance to build your timeline" which is misleading since they already have scheduled services.
- **Recommendation:** Differentiate the empty state: if there are upcoming services but no logs, say "No service history yet. Your upcoming services are shown above."

**m10. AddServiceView cost field lacks $ prefix indicator**

- **File:** `AddServiceView.swift:198-203` -- Placeholder is "0.00" but there's no currency symbol shown.
- Compare to MarkServiceDoneSheet line 80 where placeholder is "$0.00".
- **Recommendation:** Standardize to include currency indicator in both places.

**m11. ServicesTab bottom padding includes magic number**

- **File:** `ServicesTab.swift:258` -- `.padding(.bottom, Spacing.xxl + 56)` -- the `56` appears to be accounting for a floating action button or tab bar but is a magic number.
- **Recommendation:** Extract to a named constant (e.g., `Spacing.tabBarSafeArea` or `Spacing.floatingButtonHeight`).

**m12. ServicePresetPickerSheet `formatInterval` function is duplicated**

- **File:** `ServiceTypePicker.swift:98-108` and `ServiceTypePicker.swift:187-197` -- Same `formatInterval` function exists in both `ServiceTypePicker` and `ServicePresetPickerSheet`.
- **Recommendation:** Extract to a shared helper or extension on `PresetData`.

---

## Detailed Findings

### Service Creation Flow (Record vs Remind)

The dual-mode design is conceptually sound but has execution gaps:

**Record mode** is optimized for "I just did this" -- date, cost, mileage, notes, attachments. The "Remind Me Next Time" toggle at the bottom is the critical path to ongoing tracking, but its position below Notes and Attachments means many users will never see it. The form is long enough to require scrolling on smaller devices, and the toggle is below the fold.

**Remind mode** is optimized for "remind me when this is due" -- interval, due date/mileage, notes. The conditional "When Is It Due?" section adapts based on whether intervals are set, which is smart but potentially confusing. When a user enters an interval, the section auto-calculates a date. When they clear the interval, the section switches to a manual toggle -- this transition is not explained.

**The critical gap:** There is no guidance about WHEN to use Record vs Remind. A new user who just got an oil change might use Remind mode (wrong -- they should Record and enable "Remind Me Next Time"). A user who wants to set up all their services upfront might use Record (wrong -- they should use Remind). The segmented control labels alone don't convey this distinction clearly.

### Mark-Done Flow

**Single service (MarkServiceDoneSheet):** 2 taps from ServiceDetailView (tap "Mark as Done" -> fill form -> tap "Save"). The form pre-fills mileage and shows planned notes. This is well-designed.

**Cluster (MarkClusterDoneSheet):** 2-3 taps from HomeTab cluster card (tap cluster -> tap "Mark All Done" -> fill form -> tap "Save"). Simpler form but missing cost, attachments, category, and feedback mechanisms. The gap between single and cluster completion is jarring.

**From ServicesTab list:** The list view does not surface a "Mark Done" action directly. Users must tap a service -> view detail -> tap "Mark as Done" (3 taps). A swipe action on ServiceRow could reduce this to 2 taps.

### Service Detail Information Architecture

ServiceDetailView is well-organized with clear sections: Status Card -> Schedule -> Actions -> History -> Insights -> Attachments. The vertical flow matches priority -- most urgent info first.

However, the action buttons section (line 216-243) has a UX quirk: for `neutral` status services (no due tracking), the primary button changes to "Set Up Reminder" which opens EditServiceView. This is reasonable but there's no secondary action to log a past service for neutral services. A user who has a one-off service with no schedule can only see "Set Up Reminder" -- no "Record Service" option.

### Timeline vs List Toggle

The toggle between List and Timeline views is implemented as an `InstrumentSegmentedControl` at the top of ServicesTab. It is **sufficiently discoverable** -- positioned right below the search field.

**Timeline value assessment:** The timeline adds genuine value by providing temporal context that the flat list lacks. Seeing services spread across months, with completed and upcoming items interleaved, gives a sense of maintenance cadence. However, the timeline does NOT use the search or status filters, which limits its utility when looking for specific services.

### Service Editing Limitations

EditServiceView allows changing: name, due date, due mileage, intervals, and notes. It does NOT allow:
- Changing the vehicle assignment
- Viewing or editing the service's log history
- Re-deriving due dates from changed intervals (Critical issue C3)
- Changing the service type to a different preset

The delete action is prominently placed at the bottom with a destructive style and confirmation dialog, which is correct.

---

## Code Quality Issues

1. **Duplicated `formatInterval` function** in `ServiceTypePicker.swift` (lines 98-108 and 187-197). Extract to a shared helper.

2. **Inline DateFormatter creation** in multiple files (`AddServiceView.swift:332-336`, `ServiceDetailView.swift:385-388`, `MaintenanceTimeline.swift:252-255`). The app has a `Formatters` enum -- use it.

3. **Hardcoded "mi" suffix** in `MarkServiceDoneSheet.swift:69` while `EditServiceView.swift:90` and `MarkClusterDoneSheet.swift:126` correctly use `DistanceSettings.shared.unit.abbreviation`. Inconsistent unit handling.

4. **ServiceRow double-tap handler** (`ServicesTab.swift:174-185` wraps ServiceRow in a Button, but ServiceRow itself has `.tappableCard(action: onTap)` at line 103). Both trigger navigation to the same destination.

5. **MarkClusterDoneSheet is missing multiple standard save-flow behaviors** compared to MarkServiceDoneSheet: no haptic, no toast, no analytics, no `appState.recordCompletedAction()`. This looks like an incomplete implementation that was shipped.

6. **Magic number `56`** in `ServicesTab.swift:258` for bottom padding. Should be a named constant tied to the floating action button height or tab bar offset.

7. **`effectiveDueDate` computed property in AddServiceView** (lines 59-67) recalculates on every view render. While lightweight, this pattern of deriving model-level values inline in the view contradicts the architecture guideline that "derivation and computation logic belongs in `@Model` classes, not in views."

8. **CategoryChip uses Capsule() clip shape** in `ServiceTypePicker.swift:219`, violating the zero-corner-radius design mandate.

---

## Recommendations

### High Priority (address before v1.0 ship)

1. **Auto-enable "Remind Me Next Time" when a preset with intervals is selected** in Record mode. This is the highest-impact single change -- it converts one-off logs into tracked recurring services by default.

2. **Add missing parity features to MarkClusterDoneSheet**: cost entry, haptic feedback, toast confirmation, analytics, and `appState.recordCompletedAction()`.

3. **Fix EditServiceView to re-derive due dates when intervals change.** Call `deriveDueFromIntervals` using the last-performed anchor when saving changed intervals.

4. **Add cost category selector to MarkServiceDoneSheet** so cost analytics data is complete from day one.

5. **Fix hardcoded "mi" unit** in MarkServiceDoneSheet to use `DistanceSettings.shared.unit.abbreviation`.

### Medium Priority (quality-of-life improvements)

6. **Replace Capsule() with Rectangle()** in CategoryChip for design system consistency.

7. **Restyle ServicePresetPickerSheet** to use brutalist components instead of native List.

8. **Use `service.predictedDueDate`** in MaintenanceTimeline instead of hardcoded 30-day fallback for mileage-only services.

9. **Remove double-tap handling** on ServiceRow (either the outer Button or the inner tappableCard).

10. **Add swipe-to-mark-done action** on ServiceRow in the Upcoming list to reduce tap count for the most common action.

11. **Add delete capability for existing attachments** in EditServiceLogView.

12. **Stay on ServiceDetailView after mark-done** instead of auto-dismissing, so users see updated status immediately.

### Low Priority (polish)

13. Standardize navigation title casing across all service sheets.
14. Extract duplicated `formatInterval` to a shared helper.
15. Replace inline DateFormatter creation with `Formatters` enum usage.
16. Replace magic number `56` with a named spacing constant.
17. Add localized strings for hardcoded section titles ("Upcoming", "Service History").
18. Standardize cost placeholder ("0.00" vs "$0.00") across forms.
19. Improve empty state messaging for timeline when services exist but no logs do.
20. Add helper text to Remind mode explaining the interval-to-due-date derivation.
