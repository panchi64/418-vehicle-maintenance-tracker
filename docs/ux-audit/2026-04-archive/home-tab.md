# Home Tab & Dashboard -- UX Audit

## Executive Summary

The Home Tab delivers a strong "instrument cluster" metaphor with clear visual hierarchy and thoughtful progressive disclosure. The information architecture is mostly sound -- safety-critical recalls sit at the top, the hero "Next Up" card dominates mid-screen, and supporting data fans out below. However, several card ordering decisions, empty state gaps, interaction affordance inconsistencies, and a dead-code component reduce the experience from great to merely good. The audit identifies 3 critical issues, 6 major issues, and 9 minor polish items.

## Strengths

1. **Recall Alert placement** -- Correctly positioned above everything else (HomeTab.swift:67-70). Safety-critical content is not buried.
2. **Next Up hero card** -- Large, data-rich card with mileage-first hierarchy, progress bar, pace prediction, and status-colored urgency. This is the most polished component on the dashboard.
3. **Dual-axis awareness** -- NextUpCard respects both mileage and date axes, with smart fallback from miles to days (NextUpCard.swift:82-135).
4. **Estimated mileage transparency** -- The "(EST)" badge on NextUpCard (line 158-163) and the tilde prefix on QuickMileageUpdateCard (line 41) clearly communicate when values are projected rather than reported.
5. **Pace prediction** -- The "~N DAYS AT YOUR PACE" line (NextUpCard.swift:102) bridges the gap between raw mileage numbers and user-meaningful time estimates.
6. **Brutalist consistency** -- Zero corner radius, monospace labels, grid-line dividers, and status-glow animations are applied consistently across all cards.
7. **Progressive disclosure** -- QuickSpecsCard collapses by default with a preview summary; RecallAlertCard collapses with a count badge. Both prevent the dashboard from feeling overwhelmed on load.
8. **Seasonal reminder dismissal model** -- Per-year dismissal with a permanent suppression escape hatch via context menu (SeasonalReminderCard.swift:76-81) is a well-considered two-tier dismissal model.
9. **Accessibility** -- Most cards include `accessibilityElement(children: .combine)` with descriptive labels and hints.
10. **Staggered reveal animations** -- Cards use sequential `.revealAnimation(delay:)` creating a satisfying cascade on load.

## Issues Found

### Critical (blocks intuitive use)

**C1. `nextUpService` is computed but never used**
`HomeTab.swift:43-45` defines `nextUpService` which fetches the first service from `vehicleServices`, but the actual Next Up display at line 39-41 uses `nextUpItem` (from the `UpcomingItem` protocol). This is dead code, but more importantly, `vehicleServices` is sorted by urgency while `nextUpItem` uses `allUpcomingItems` which includes marbete. If a developer references `nextUpService` thinking it matches what is displayed, they will get wrong results. The dead property should be removed to prevent confusion.

**C2. `remainingServices` logic silently drops the first service even when it is NOT the displayed Next Up**
`HomeTab.swift:47-54` -- `remainingServices` drops the first element from `vehicleServices` (sorted by urgency) under the assumption that it matches the displayed Next Up item. But `nextUpItem` comes from `vehicle.nextUpItem` which sorts *all upcoming items* including marbete via a different urgency score path. If the urgency ordering between `vehicleServices.forVehicle()` and `vehicle.allUpcomingItems` ever diverges (e.g., due to marbete insertion, or a mileage vs. date tie-break difference), the first service in `vehicleServices` might not be the one displayed as Next Up, causing:
- The actual Next Up service to also appear in the Upcoming list (duplicate).
- A different service to be silently dropped from Upcoming.

The marbete guard at line 50-51 partially addresses this, but only for the marbete case. If both paths use different tie-breaking for services, the bug exists for service-vs-service as well.

**C3. Empty state for "no services" uses misleading copy and no CTA**
`HomeTab+EmptyStates.swift:53-59` -- When a vehicle exists but has no services, the empty state shows "All Clear" with a checkmark icon and "No maintenance services scheduled for this vehicle." This is misleading:
- "All Clear" implies everything is in good shape, but for a new vehicle with zero services, it should be prompting the user to set up their maintenance schedule.
- There is no action button to add a service, unlike the no-vehicle empty state which has "Add Vehicle."
- A first-time user who just added a vehicle will see "All Clear" and think they are done, missing the core value of the app entirely.

### Major (degrades experience noticeably)

**M1. Mileage update card appears ABOVE Next Up, breaking information hierarchy**
`HomeTab.swift:61-94` places the instrument cluster (Recall, Specs, Mileage Update) above the "Next Up" section. While Recall and Specs are appropriately positioned, the Mileage Update card is a prompt/action rather than status information. When it appears, it pushes the hero Next Up card below the fold on smaller devices. The most important dashboard question -- "what maintenance is next?" -- should not be displaced by a "please update your odometer" prompt.

**M2. QuickStatsBar is positioned last, below Recent Activity -- very low visibility**
`HomeTab.swift:248-252` -- The YTD spend and services count bar is at the very bottom of the scroll. Most users will never scroll that far on a healthy dashboard. This data is lightweight, glanceable, and would be more valuable higher up -- either immediately after Next Up or as a persistent bar.

**M3. `RecentActivityFeed.swift` component exists but is unused**
The standalone `RecentActivityFeed` component (RecentActivityFeed.swift:10-88) is never imported or used by HomeTab. Instead, HomeTab reimplements the Recent Activity section inline (HomeTab.swift:203-246) with its own `activityRow(log:)` helper (HomeTab+Helpers.swift:100-132). This creates:
- Duplicate code for activity row rendering (two implementations exist).
- The standalone component has accessibility per-row (`accessibilityElement(children: .combine)` at RecentActivityFeed.swift:78), while the inline version lacks per-row accessibility grouping.
- The standalone component uses a `DateFormatter` allocated per call (RecentActivityFeed.swift:83-87), and the inline version uses `Formatters.shortDate` -- a discrepancy in date formatting.
- Maintenance burden: fixing a bug in one does not fix the other.

**M4. "View All" links for both Upcoming and Recent Activity go to the same destination**
`HomeTab.swift:169` and `HomeTab.swift:211` both call `appState.navigateToServices()`. A user tapping "View All" on Recent Activity likely expects to see their service *history/logs*, not the active services list. This misdirects users.

**M5. SeasonalReminderCard "Schedule Service" and "Not This Year" buttons have inconsistent casing**
`SeasonalReminderCard.swift:62` uses Title Case "Schedule Service" while `line 68` uses Title Case "Not This Year." This is fine in isolation, but every other text element in the brutalist design system uses ALL CAPS with tracking. These buttons break the typographic pattern because they use `.buttonStyle(.primary)` / `.buttonStyle(.secondary)` which may or may not enforce uppercase. If the button styles do not force uppercase, these strings violate the design system.

**M6. Recall card has no external link to NHTSA or dealer lookup**
`RecallAlertCard.swift` displays recall information including campaign numbers and remedies, but provides no way to:
- Open the NHTSA recall page in a browser.
- Find a dealer.
- Mark a recall as resolved/addressed.
Users see alarming safety information but cannot act on it within the app beyond reading it.

### Minor (polish opportunities)

**m1. Stale animation delays create visual gaps when cards are conditionally hidden**
Cards use hardcoded `.revealAnimation(delay:)` values (0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4). When intermediate cards are hidden (e.g., no recalls, no mileage prompt), the visible cards still use their original delays, creating uneven timing. For example, if Recall and Mileage are both hidden, QuickSpecs animates at 0.1 and Next Up at 0.2 -- the 0.1s gap is fine. But the Cluster card at 0.25 will feel delayed relative to Next Up at 0.2.

**m2. QuickSpecsCard notes separator uses hardcoded color**
`QuickSpecsCard.swift:160` uses `Color.white.opacity(0.2)` instead of `Theme.gridLine` or another design token. This will look wrong if the theme ever changes and breaks the design system convention.

**m3. QuickSpecsCard expanded content lacks animation on individual spec rows**
The expanded content uses `.transition(.opacity)` at line 233, which is correct per the codebase convention (fade-only for accordions). However, the entire block appears at once. Individual rows could benefit from staggered fade-in for a more polished feel, though this is a minor enhancement.

**m4. ServiceClusterCard dismiss button (24x24pt) is below the 44pt minimum tap target**
`ServiceClusterCard.swift:53` -- The dismiss X button has a 24x24pt frame. Apple HIG recommends minimum 44x44pt touch targets. While `.contentShape(Rectangle())` is set, the actual hittable area is still 24x24pt because it is nested inside the card's tap gesture.

**m5. Activity row chevron suggests navigation but the card uses `.buttonStyle(.plain)`**
`HomeTab+Helpers.swift:126-128` shows a chevron.right implying navigation, and the row is wrapped in a Button (HomeTab.swift:227-231). The button style is `.plain` which provides no visual feedback on press. Users may tap and see nothing happen, questioning whether the tap registered.

**m6. QuickMileageUpdateCard shows "KEEPS N SERVICE REMINDERS ACCURATE" in a way that feels like a nag**
`QuickMileageUpdateCard.swift:84-89` -- This label is shown whenever `mileageTrackedServiceCount > 0`, which is basically always for active users. The motivational nudge is good for first-time prompts but becomes redundant after several updates. Consider showing it only when the mileage is stale (14+ days).

**m7. `Spacing.screenHorizontal` used inconsistently as vertical padding**
`NextUpCard.swift:114` and `NextUpCard.swift:134` use `Spacing.screenHorizontal` for vertical padding in the hero data section. This is semantically incorrect -- `screenHorizontal` (20pt) is designed for horizontal edge insets. The vertical spacing should use an explicit vertical token like `Spacing.lg` (24pt) or `Spacing.md` (16pt).

**m8. Recent Activity and Upcoming sections both cap at 3 items with no configurability**
`HomeTab.swift:180` and `HomeTab.swift:224` both hardcode `prefix(3)`. On larger devices (iPhone Pro Max, iPad), there is room for more items. This is a minor missed opportunity for screen utilization.

**m9. QuickStatsBar shows "$0" and "0" for new users, which is technically correct but unhelpful**
When a user has a vehicle but zero service logs, the QuickStatsBar shows "YTD $0" and "SERVICES 0." This is accurate but adds no value and clutters the bottom of the dashboard. The component could be hidden when there are zero logs (matching how Recent Activity already hides itself at HomeTab.swift:204).

## Detailed Findings

### HomeTab.swift -- Layout & Orchestration

**Card ordering (top to bottom):**
1. Recall Alert (safety) -- correct
2. Quick Specs (info) -- acceptable, collapsed by default
3. Quick Mileage Update (action) -- questionable position (see M1)
4. Next Up (hero) -- should be higher
5. Service Cluster (suggestion) -- correct, after Next Up
6. Seasonal Reminders (advisory) -- correct
7. Upcoming services (list, max 3) -- correct
8. Recent Activity (history, max 3) -- correct
9. Quick Stats Bar (summary) -- too low (see M2)
10. Empty states -- correct at bottom

**Recommended ordering:**
1. Recall Alert
2. Quick Specs (collapsed)
3. Next Up (hero) -- promoted above mileage prompt
4. Quick Mileage Update -- moved below Next Up
5. Service Cluster
6. Quick Stats Bar -- promoted significantly
7. Seasonal Reminders
8. Upcoming services
9. Recent Activity

**Data flow:**
- `vehicleServices` uses `services.forVehicle(vehicle)` which sorts by urgency score.
- `nextUpItem` uses `vehicle.nextUpItem` which sorts `allUpcomingItems` by urgency score.
- These two sorting paths should produce consistent results for services, but the inclusion of marbete in the second path creates the `remainingServices` edge case (C2).

**Lines 267-270:** Bottom padding calculation `Spacing.xxl + 56` is a magic number. The 56 presumably accounts for tab bar + FAB height but is not documented or tokenized.

### NextUpCard.swift -- Hero Card

**Strengths:** The mileage-first display with pace prediction is excellent. The progress bar is simple and effective. Status coloring is applied consistently.

**Line 60:** `status.label.isEmpty` fallback to "SCHEDULED" -- This handles the `.neutral` status gracefully. Good defensive coding.

**Lines 82-135:** The mileage vs. days branching is clean. The mileage path includes pace prediction; the days path does not (correctly, since date-only services have no mileage dimension).

**Line 168:** "DUE_AT" -- This appears to be an unlocalized string key being displayed literally. If localization is not set up, the user sees "DUE_AT" as a label. Same for "CURRENT" (line 147) and "LAST_SERVICE" (line 183). If these are intentional brutalist labels, they read oddly -- "DUE_AT" with the underscore looks like a code artifact rather than a design choice.

**Line 206-207:** Accessibility label combines service name and status label but does not include the numeric mileage/days value. A VoiceOver user hearing "Oil Change, Overdue" misses the "2,340 MI OVERDUE" information that sighted users see prominently.

### QuickSpecsCard.swift -- Collapsible Specs

**Well-designed progressive disclosure.** Collapsed shows plate + tire size inline; expanded shows full grid. The notes truncation with "TAP TO READ MORE" and sheet presentation for full notes is thoughtful.

**Line 19:** `hasAnySpecs` includes `hasMarbeteExpiration` -- good, ensures the card is shown when marbete data exists even without traditional specs.

**Line 160:** Hardcoded `Color.white.opacity(0.2)` instead of `Theme.gridLine` (see m2).

**Lines 200-204:** Empty state text "No specifications added" inside the expanded card is correctly placed but uses `.brutalistSecondary` instead of `.brutalistBody` -- inconsistent with the "No maintenance services scheduled" empty state which uses `.brutalistSecondary`. Actually these match, so this is consistent.

### QuickMileageUpdateCard.swift -- Odometer Prompt

**Line 85:** The "KEEPS N SERVICE REMINDERS ACCURATE" motivational text is good UX for explaining *why* the user should update, but it is always-on (see m6).

**Line 127:** Presentation detent `.height(450)` is hardcoded. On smaller devices this may not be optimal. Consider `.medium` or adaptive sizing.

**The card itself combines display + action well.** The large odometer reading with UPDATE button is immediately scannable.

### RecallAlertCard.swift -- Safety Alerts

**Strong implementation.** The "PARK IT" badge for severe recalls (line 65-73) provides appropriate urgency escalation. The inline limit of 3 with "VIEW ALL" overflow is sensible.

**Line 55:** `HapticService.shared.tabChanged()` on expand/collapse -- this haptic feedback is a nice touch for a safety-critical interaction, though the method name `tabChanged` is semantically wrong (it is not a tab change).

**Lines 136-161:** The explicit "COLLAPSE" button at the bottom of the expanded section is unusual. Most accordion implementations allow tapping the header to collapse. This card supports BOTH (header tap toggles, plus explicit collapse button), which is redundant but not harmful. The collapse button could be removed for cleaner design.

**Missing: no way to act on recalls** (see M6).

### SeasonalReminderCard.swift -- Seasonal Advisories

**Clean implementation.** The two-button layout (Schedule Service / Not This Year) provides clear primary vs. secondary actions.

**Line 77:** `SeasonalSettings.shared.suppressPermanently(reminder.id)` in a context menu is a good power-user escape hatch. However, it uses `role: .destructive` which colors the text red -- appropriate for permanent suppression.

**Missing:** No visual indicator of which season the reminder applies to. The icon helps, but a subtle "WINTER" or "SUMMER" badge would add clarity.

### ServiceClusterCard.swift -- Bundle Suggestion

**Line 38:** "\(cluster.serviceCount) SERVICES DUE SOON" -- Good clear value proposition.

**Lines 67-87:** The service list with status-colored dots is scannable. The +N more overflow is handled well.

**Lines 96-123:** Technical data rows (WINDOW and TARGET) are well-formatted. The "@" prefix for target mileage is a nice brutalist touch.

**The dismiss button tap target issue (m4)** is the main concern. The card uses `.tappableCard(action: onTap)` which captures the entire card surface, making the small dismiss button harder to hit precisely.

### QuickStatsBar.swift -- Summary Stats

**Lines 31-57:** The two-stat horizontal layout is clean and scannable.

**No empty state handling.** When both values are 0, the bar still renders (see m9). Adding a conditional hide when `ytdLogs.isEmpty` would be cleaner.

### RecentActivityFeed.swift -- Standalone Component (UNUSED)

This entire component is unused by HomeTab. See M3 for the full analysis. If the component exists for potential reuse elsewhere, it should be documented as such. If not, it should be either integrated into HomeTab (replacing the inline implementation) or removed.

### EmptyStateView.swift -- Reusable Empty State

**Well-built reusable component.** The optional action button pattern is flexible. Accessibility is properly combined.

**Line 71:** `frame(width: 160)` on the action button is hardcoded. Long button labels may truncate. Consider using natural sizing with min/max constraints.

### AppState.swift -- Navigation State

**Clean separation of concerns.** Tab navigation, sheet management, and recall state are well-organized.

**Line 183:** `requestAddVehicle(vehicleCount:)` gates on vehicle count >= 3 for pro paywall. This is business logic in the state manager, which is acceptable for a simple check but could become unwieldy as monetization rules grow.

**Lines 194-199:** `recordCompletedAction()` has a 1.5-second delay before showing a tip modal. This is fine UX, but the timing is not documented. A comment explaining "delay to let the user see their completed action before interrupting" would clarify intent.

## Code Quality Issues

1. **Dead computed property** -- `nextUpService` in `HomeTab.swift:43-45` is never referenced. Should be removed.

2. **Duplicate activity row implementations** -- `RecentActivityFeed.swift` and `HomeTab+Helpers.swift:100-132` implement the same UI with subtle differences (date formatting, accessibility). One should be canonical.

3. **Semantic misuse of `Spacing.screenHorizontal` for vertical padding** -- `NextUpCard.swift:114, 134` use a horizontal spacing token for vertical padding.

4. **Hardcoded color** -- `QuickSpecsCard.swift:160` uses `Color.white.opacity(0.2)` instead of a design token.

5. **Hardcoded bottom padding magic number** -- `HomeTab.swift:270` uses `Spacing.xxl + 56` without explaining the 56.

6. **String "DUE_AT" with underscore** -- `NextUpCard.swift:168` displays "DUE_AT" as a visible label. If intentional, the underscore looks like a localization key leak. If the brutalist label should read "DUE AT" (with a space), it needs correction.

7. **Haptic method name mismatch** -- `RecallAlertCard.swift:55` calls `HapticService.shared.tabChanged()` for an accordion toggle, which is semantically incorrect.

## Recommendations

Prioritized by impact and effort:

### High Priority (Critical + Major fixes)

1. **Fix the "no services" empty state (C3)** -- Change icon from "checkmark" to "wrench.and.screwdriver", title from "All Clear" to "Set Up Maintenance", message to guide user, and add an "Add Service" action button. This is the #1 improvement for first-time user retention.

2. **Remove dead `nextUpService` property (C1)** -- Delete HomeTab.swift lines 43-45 to prevent developer confusion.

3. **Harden `remainingServices` logic (C2)** -- Instead of blindly dropping the first service, filter out the service that matches `nextUpItem` by ID. Example: `tracked.filter { $0.id != (nextUpItem as? Service)?.id }`.

4. **Promote Next Up above Mileage Update (M1)** -- Move the mileage update card below the Next Up section in the VStack. The hero card should never be pushed below the fold.

5. **Replace inline activity rows with RecentActivityFeed component (M3)** -- Or delete the standalone component if it is truly unused everywhere. One canonical implementation reduces maintenance burden.

6. **Differentiate "View All" destinations (M4)** -- Recent Activity's "View All" should navigate to a service history/log view, not the active services tab.

### Medium Priority (Major + Minor fixes)

7. **Promote QuickStatsBar higher (M2)** -- Move it to just after Next Up or Cluster, before the Upcoming list.

8. **Add recall action links (M6)** -- Add a "View on NHTSA" button that opens `https://www.nhtsa.gov/recalls` or a deep link with the campaign number.

9. **Fix "DUE_AT" underscore label (Code Quality #6)** -- Change to "DUE AT" with a space.

10. **Enlarge ServiceClusterCard dismiss tap target (m4)** -- Increase the frame to 44x44pt or add `.frame(minWidth: 44, minHeight: 44)`.

11. **Fix NextUpCard accessibility to include numeric values (Detailed Finding)** -- Add mileage/days to the accessibility label.

12. **Ensure SeasonalReminderCard button text is uppercased (M5)** -- Either add `.textCase(.uppercase)` to button labels or verify the button styles enforce it.

### Low Priority (Polish)

13. **Replace hardcoded `Color.white.opacity(0.2)` with `Theme.gridLine` (m2).**
14. **Replace `Spacing.screenHorizontal` with `Spacing.lg` for vertical padding (m7).**
15. **Hide QuickStatsBar when no service logs exist (m9).**
16. **Document the `+56` magic number in bottom padding (Code Quality #5).**
17. **Use semantic haptic method name for accordion toggle (Code Quality #7).**
18. **Consider dynamic animation delays based on visible card count (m1).**
19. **Show "KEEPS N SERVICE REMINDERS ACCURATE" only when mileage is stale (m6).**
20. **Add press feedback to activity row buttons (m5).**
