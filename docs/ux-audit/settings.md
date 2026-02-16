# Settings & Configuration — UX Audit

## Executive Summary

The Settings screen is well-organized with a clear visual hierarchy following the brutalist design system. Sections are logically grouped by frequency of use (Display first, Privacy last). The CSV import wizard is impressively thorough with auto-detection and multi-step validation. However, several issues affect discoverability, user comprehension, and polish — particularly around the relationship between related settings (climate zone and seasonal alerts), the gacha tip mechanic's transparency, and inconsistent localization. The most impactful improvements involve better contextual explanations, clearer setting interdependencies, and tighter polish on edge cases in the CSV import and sync flows.

---

## Strengths

1. **Logical section ordering.** Display (most commonly adjusted) is first; Privacy (rarely changed) is last. This matches how users actually interact with settings screens.

2. **Consistent visual language.** Every section follows the same pattern: section label in `brutalistLabel` with tracking, instrument-surface card with grid-line borders. Pickers, toggles, and navigation rows all use the same `settingRow` pattern.

3. **Haptic feedback on selections.** Most pickers and toggles trigger `HapticService.shared.selectionChanged()`, giving satisfying tactile confirmation. (Exception noted in Issues.)

4. **Threshold pickers show defaults.** Both due-soon pickers mark the default value with "(Default)" text, reducing anxiety about which value to choose.

5. **CSV import wizard is comprehensive.** Four clean steps: pick file, configure columns, preview data, success confirmation. Auto-detects source format (Fuelly, Drivvo, Simply Auto). Column mapping uses dropdown pickers. Preview shows parsed stats before committing. Warnings surface parsing issues without blocking the import.

6. **Sync section is detailed.** Shows real-time sync state with appropriate icons, last-sync time in relative format, actionable error buttons (e.g., "Sign in to iCloud"), and a restart-required alert when toggling.

7. **Theme picker communicates ownership clearly.** Active theme gets a checkmark and accent border; locked themes show a lock icon; tier labels (FREE/PRO/RARE) use color-coded badges.

8. **Non-intrusive tip modal.** The post-service-log tip prompt uses `presentationDetents([.height(350)])`, keeping it compact. The "Not now" button is visible and uses a soft tertiary color, making dismissal easy and guilt-free.

---

## Issues Found

### Critical

**C1. Tapping a locked rare theme does nothing — no feedback at all.**
- File: `ThemePickerView.swift:56`
- When a user taps a locked rare theme, the `handleThemeTap` function silently falls through to the comment `// Rare locked themes: no action`. The hint text at the bottom of the list ("Tip to unlock exclusive rare themes") is easy to miss.
- **Impact:** Users will tap locked themes, see nothing happen, and assume the app is broken. This is the worst kind of UX — invisible failure.
- **Fix:** Show a brief inline message or toast ("Tip to unlock rare themes"), or navigate to the Tip Jar view directly.

**C2. SyncSettingsSection is orphaned from its parent section group.**
- File: `SettingsView.swift:40`
- `SyncSettingsSection()` sits as a standalone call between `supportSection` and `privacySection`, outside any labeled section group. It renders its own "ICLOUD SYNC" header, but visually it appears as a sibling to Support and Privacy rather than under a "Data & Sync" umbrella.
- **Impact:** The settings screen has 7 visual sections but conceptually only 5-6 categories. Users scanning the screen see "DATA", then "SUPPORT", then "ICLOUD SYNC", then "PRIVACY" — the sync section feels out of place and breaks the narrative flow.
- **Fix:** Either merge SyncSettingsSection into the Data section (renaming it "DATA & SYNC"), or move it to appear immediately after the Data section with consistent grouping.

### Major

**M1. Climate Zone and Seasonal Alerts are decoupled — no visible dependency.**
- Files: `SettingsView.swift:166-180`, `SeasonalRemindersToggle.swift`, `ClimateZonePickerView.swift`
- Climate Zone picker is always visible and tappable even when Seasonal Alerts is toggled off. There is no explanation that Climate Zone only matters when Seasonal Alerts is enabled.
- **Impact:** Users may set a climate zone thinking it affects something, then wonder why nothing changes. Or they may enable seasonal alerts without setting a zone and get unexpected behavior.
- **Fix:** Either (a) visually disable/dim the Climate Zone row when Seasonal Alerts is off, with a subtitle like "Enable Seasonal Alerts to configure", or (b) add a dependency description to the climate zone picker.

**M2. Clustering window pickers are accessible when Service Bundling is toggled off.**
- File: `SettingsView.swift:200-233`
- The "Mileage Window" and "Days Window" pickers are always tappable, even when the Service Bundling toggle above them is off. Users can configure windows for a feature that is disabled.
- **Impact:** Wasted effort and confusion. Users may think they enabled bundling by setting a window.
- **Fix:** Disable or hide the window pickers when the Service Bundling toggle is off, or at minimum add a subtitle noting the feature is disabled.

**M3. No confirmation or undo for CSV import.**
- File: `CSVImportView.swift:190-212`
- `performImport` commits data to the ModelContext with no confirmation dialog and no undo mechanism. If the user accidentally imports to the wrong vehicle or realizes the mapping was wrong, there is no way to reverse it.
- **Impact:** Data integrity risk. The import could create dozens or hundreds of services and logs that would need manual deletion.
- **Fix:** Add a confirmation alert ("Import X services with Y logs to [Vehicle Name]?") before committing, and consider tracking imported records for bulk undo.

**M4. Gacha mechanic has no transparency about odds or duplicate handling.**
- Files: `TipJarView.swift:119-123`, `TipModalView.swift:135-139`
- When a user tips, `ThemeManager.shared.unlockRandomRareTheme()` is called. There is no indication of: how many rare themes exist, how many the user already owns, or what happens if they already own all themes (the "all collected" message in TipJarView only shows statically, not during the purchase flow).
- **Impact:** Users tipping from the TipModalView (post-service-log) have zero visibility into the gacha system. They may tip expecting a new theme and get nothing if all are already owned. This creates a feeling of being cheated.
- **Fix:** Show the user's collection progress (e.g., "3/7 rare themes collected"). If all themes are owned, change the tip messaging to "Thanks for your support!" without implying a theme reward.

**M5. "Support Checkpoint" row shows empty value string.**
- File: `SettingsView.swift:297-302`
- `settingRow(title: "Support Checkpoint", value: "")` passes an empty string for value. The `settingRow` helper renders an empty `Text("")` element, which still takes up layout space and creates a visual gap between the title and the chevron.
- **Impact:** Minor visual misalignment, but inconsistent with other rows that show meaningful values (e.g., current theme name, current unit).
- **Fix:** Either remove the value text when empty, or show something meaningful like the total tip count or "Tip Jar".

**M6. Paywall hardcodes strikethrough price and trigger context.**
- File: `ProPaywallSheet.swift:33-34`, `ProPaywallSheet.swift:119`
- The strikethrough "$14.99" is hardcoded, not derived from StoreKit metadata. The analytics trigger is hardcoded to "vehicle_limit" even though the paywall may be triggered from the theme picker.
- **Impact:** The hardcoded price could become stale or misleading if the actual price changes. The analytics data will misattribute all paywall views to the vehicle limit trigger.
- **Fix:** Remove the hardcoded strikethrough or derive it from product metadata. Pass the trigger context as a parameter to the paywall sheet.

### Minor

**m1. Inconsistent localization coverage.**
- Multiple files use raw strings instead of L10n keys:
  - `SettingsView.swift:248` — `"DATA"` (hardcoded)
  - `SettingsView.swift:289` — `"SUPPORT"` (hardcoded)
  - `SettingsView.swift:84` — `"Theme"` (hardcoded)
  - `SettingsView.swift:178` — `"Climate Zone"` (hardcoded)
  - `SettingsView.swift:299` — `"Support Checkpoint"` (hardcoded)
  - `SeasonalRemindersToggle.swift:17` — `"Seasonal Alerts"` (hardcoded)
  - `SyncSettingsSection.swift:19` — `"ICLOUD SYNC"` (hardcoded)
  - `AnalyticsSettingsSection.swift:24` — `"Usage Analytics"` (hardcoded)
  - All CSV import views use hardcoded English strings throughout
- Meanwhile, other settings properly use L10n keys (`L10n.settingsDisplay`, `L10n.settingsReminders`, etc.)
- **Impact:** Localization-breaking inconsistency. If the app is ever localized, roughly half the settings screen would remain in English.

**m2. ServiceBundlingToggle is missing haptic feedback.**
- File: `ServiceBundlingToggle.swift:32-34`
- The `onChange` handler does not call `HapticService.shared.selectionChanged()`, unlike every other toggle (MileageEstimatesToggle, SeasonalRemindersToggle, AppIconToggle, AnalyticsSettingsSection).
- **Impact:** Inconsistent tactile experience.

**m3. ClusteringDaysWindowPicker and ClusteringMileageWindowPicker are missing haptic feedback.**
- Files: `ClusteringDaysWindowPicker.swift:61`, `ClusteringMileageWindowPicker.swift:61`
- Neither picker calls `HapticService.shared.selectionChanged()` in the button action, unlike DueSoonDaysThresholdPicker and DueSoonMileageThresholdPicker which do.
- **Impact:** Inconsistent tactile feedback across pickers that look and behave identically.

**m4. DueSoonDaysThresholdPicker and DueSoonMileageThresholdPicker have unused `dismiss` environment variable.**
- Files: `DueSoonDaysThresholdPicker.swift:12`, `DueSoonMileageThresholdPicker.swift:12`
- Both declare `@Environment(\.dismiss) private var dismiss` but never call it.
- **Impact:** Dead code; no functional issue.

**m5. CSVImportSuccessStep uses `guard let` with `AnyView` type-erasure anti-pattern.**
- File: `CSVImportSuccessStep.swift:14-49`
- The body uses `guard let result = result else { return AnyView(EmptyView()) }` followed by `return AnyView(VStack { ... })`. This is a non-standard pattern that defeats SwiftUI's type system and likely emits a compiler warning.
- **Impact:** Code quality; not user-facing but a maintenance hazard.

**m6. Mileage threshold default marker is hardcoded to 750.**
- File: `DueSoonMileageThresholdPicker.swift:67`
- `if option == 750` hardcodes the default rather than reading from `DueSoonSettings.defaultMileageThreshold` or similar.
- **Impact:** If the default ever changes, this marker would be wrong.

**m7. DueSoonDaysThresholdPicker default marker is hardcoded to 30.**
- File: `DueSoonDaysThresholdPicker.swift:67`
- Same issue as m6 but for days.

**m8. Distance unit picker does not explain what changes.**
- File: `DistanceUnitPickerView.swift`
- No description text explaining what switching units affects (all mileage displays, thresholds, chart labels, etc.). The picker just shows "Miles" and "Kilometers" with abbreviation subtitles.
- **Impact:** Users may wonder if changing the unit converts their existing data or just changes the display label.

**m9. ThemeRevealView animation is minimal — just a fade.**
- File: `ThemeRevealView.swift:91-94`
- The reveal animation is a single `.easeOut(duration: 0.5)` opacity fade. For a "gacha reveal" moment meant to create delight, this is underwhelming.
- **Impact:** Missed opportunity for a rewarding moment. Gacha systems thrive on dramatic reveals (e.g., a shimmer, scale-up, particle burst).

**m10. TipModalView does not show purchase errors.**
- File: `TipModalView.swift:143`
- If a purchase fails, the error is captured by analytics but never displayed to the user. The modal stays open with no feedback.
- **Impact:** User taps a tip amount, nothing visible happens, they don't know if they were charged or if there was an error.

**m11. ProPaywallSheet "Future" features feel like empty promises.**
- File: `ProPaywallSheet.swift:51-52`
- Two features list "Future AI features" and "Future advanced insights". These read as things the user is paying for that do not exist yet.
- **Impact:** Paying for future promises can feel deceptive. Users may feel misled if these never ship.

---

## Detailed Findings

### 1. Settings Organization

The settings screen uses 7 rendered sections:

| Order | Section | Contents |
|-------|---------|----------|
| 1 | DISPLAY | Theme, Distance Unit, Mileage Estimation, App Icon Auto-change |
| 2 | REMINDERS | Due Soon Mileage, Due Soon Days, Seasonal Alerts, Climate Zone |
| 3 | SMART FEATURES | Service Bundling toggle, Mileage Window, Days Window |
| 4 | DATA | Import Service History |
| 5 | SUPPORT | Support Checkpoint (Tip Jar), Restore Purchases |
| 6 | ICLOUD SYNC | Sync toggle, Sync status |
| 7 | PRIVACY | Usage Analytics toggle |

**Assessment:** The ordering is good — display preferences first, rarely-changed settings last. The DATA section feels thin with only one item. ICLOUD SYNC being separate from DATA creates fragmentation (see C2).

### 2. Section Naming

- "DISPLAY" is clear and appropriate.
- "REMINDERS" works well, though it contains Climate Zone which is not obviously a "reminder" setting.
- "SMART FEATURES" is reasonable but somewhat vague — only contains service bundling. If no other "smart features" are planned, consider renaming to "SERVICE BUNDLING" for directness.
- "DATA" is too generic and contains only one item.
- "SUPPORT" clearly communicates purpose.
- "PRIVACY" with a single analytics toggle is clear and appropriate.

### 3. Threshold Pickers (Due Soon Days/Miles)

Both pickers include:
- Description text at the top explaining the threshold's purpose
- List of predefined options (not free-text, which prevents invalid input)
- Default value marked with "(Default)" label
- Haptic feedback on selection
- Immediate persistence via `onChange`

**Assessment:** Well-executed. The description text (`L10n.dueSoonDaysDesc` / `L10n.dueSoonMileageDesc`) provides context. Would benefit from a concrete example: "Services due within 30 days will show an amber warning."

### 4. Clustering Window Pickers

Both pickers include:
- Section header label
- Predefined options with default marker
- Explanation text at bottom

**Assessment:** The bottom explanation text is good ("Services due within this many days of each other will be suggested for bundling"). However, the concept of "service bundling" itself is not explained anywhere in the clustering pickers — a user arriving here from the Smart Features section might not understand why they're setting a window. The explanation should connect to the feature's value proposition.

### 5. CSV Import Wizard

**Flow:** Pick File -> Configure (source + column mapping) -> Preview (stats + vehicle assignment) -> Success

**Strengths:**
- Step indicator at top shows progress with numbered steps and connecting lines
- Auto-detection of source format (Fuelly, Drivvo, Simply Auto)
- Column mapping with dropdown pickers from actual CSV headers
- Data preview table with horizontal scrolling
- Preview step shows service count, log count, and total cost
- Warning display for parsing issues (capped at 10 with "AND X MORE..." overflow)
- Vehicle assignment supports both existing vehicles and creating new ones

**Issues:**
- No way to go back from Configure to Pick File (new file selection)
- No confirmation before final import (see M3)
- The "Create New Vehicle" flow creates a vehicle with empty make/model/year=0 (line 194)
- File picker only accepts `.commaSeparatedText` — no TSV or other delimited formats
- No loading state during file parsing or import execution
- Step indicator does not support tapping to navigate between completed steps

### 6. Theme Picker

- Clean list of all themes with color swatches, name, and tier badge
- Active theme: checkmark + accent border
- Owned but inactive: no indicator (just tappable)
- Locked Pro: lock icon, tapping opens paywall
- Locked Rare: lock icon, tapping does nothing (see C1)
- Hint text at bottom: "Tip to unlock exclusive rare themes"

**Assessment:** Good visual clarity for owned/active themes. The rare theme dead-end is the main issue. The hint text at the bottom is too subtle for such an important monetization path.

### 7. Tip Jar

- Header explains the value exchange ("Every tip unlocks an exclusive rare theme")
- Three tip tiers with price buttons
- Loading state during purchase
- "All collected" state shown when user has all rare themes

**Assessment:** Clean, non-pushy layout. The gacha mechanic is concerning from a transparency standpoint (see M4). The tip cards could benefit from showing which tier of rarity/theme the tip is associated with, or at least showing collection progress.

### 8. Paywall (ProPaywallSheet)

- Half-sheet presentation (`.medium` detent)
- Displays launch price with strikethrough "original" price
- Four feature bullets with icons
- Purchase button with loading state
- Error display for failed purchases
- Restore Purchases link
- Cancel button in toolbar

**Assessment:** Generally well-structured. The hardcoded price and vague "future" features are the main concerns (see M6, m11). The `.medium` detent is appropriate — not overly aggressive. Would benefit from showing what the user is currently limited to (e.g., "You have 1 vehicle — Pro unlocks unlimited").

### 9. Tip Modal (Post-Service-Log)

- Compact presentation (`.height(350)` detent)
- Centered layout with headline, subtitle, and horizontal tip buttons
- "Not now" dismissal link
- Cancel button in toolbar

**Assessment:** Good restraint in size and messaging. The dual dismissal options (Cancel button + "Not now" link) are slightly redundant but not harmful — they ensure users can always escape. Missing purchase error display (see m10). The timing of when this appears is controlled elsewhere (not in this view), so the annoyance factor depends on the trigger frequency.

### 10. Theme Reveal Animation

- Half-sheet presentation
- Content fades in over 0.5s on appear
- Shows theme name, color swatches, description
- "APPLY NOW" primary button + "Later" dismissal
- Close button in toolbar

**Assessment:** The mechanic works but the animation is underwhelming for a gacha reveal (see m9). The triple-dismissal (Close toolbar button, "Later" link, swipe-to-dismiss on sheet) is fine for a reward screen. Color swatches with grid-line borders maintain the brutalist aesthetic.

### 11. Sync Settings

- Toggle with contextual subtitle (shows "Sign in to iCloud in Settings" error, or "Free - No account required")
- Status row with animated icons for each sync state
- Last sync time in relative format
- Action buttons for recoverable errors (sign in, manage storage)
- Restart-required alert when toggling
- Footer explanation text

**Assessment:** This is one of the most polished sections. The contextual error messages and actionable buttons are excellent. The "Restart Required" alert is the right approach for a persistent-store change that requires app restart. The only concern is the section placement (see C2).

### 12. Analytics Settings

- Single toggle with clear description: "Helps us improve Checkpoint. No personal data is ever collected."
- Under "PRIVACY" section header

**Assessment:** Clean and appropriate. The privacy messaging is direct and reassuring. One toggle, no complexity — good.

### 13. Distance Unit

- Simple two-option picker (Miles / Kilometers)
- Abbreviation shown as subtitle
- No explanation of impact

**Assessment:** Functional but could be more helpful. See m8 — users need to know whether switching converts data or just changes display format.

### 14. Climate Zone

- Description text at top: "Choose the climate zone that best matches where you drive most often."
- List of zones with descriptions (presumably from `ClimateZone.description`)

**Assessment:** The description is helpful. However, there is no mention of what the climate zone actually affects (seasonal maintenance recommendations). The connection between this setting and Seasonal Alerts is invisible (see M1).

### 15. Toggle Descriptions

| Toggle | Has Description | Quality |
|--------|----------------|---------|
| Mileage Estimation | Yes (L10n) | Good |
| Seasonal Alerts | Yes (hardcoded) | Adequate — "Show seasonal maintenance tips on the dashboard" |
| Service Bundling | Yes (L10n) | Good |
| App Icon Auto-change | Yes (L10n) | Good |
| Usage Analytics | Yes (hardcoded) | Good — includes privacy reassurance |
| iCloud Sync | Yes (context-aware) | Excellent — changes based on state |

**Assessment:** All toggles have descriptions, which is good. Quality varies but all are at least adequate.

### 16. Navigation Patterns

Sub-pickers (DueSoonDays, DueSoonMileage, ClusteringDays, ClusteringMileage, DistanceUnit, ClimateZone) all follow the same pattern:
- Push navigation via NavigationLink
- Inline title display mode
- ZStack with background + ScrollView/VStack
- Immediate persistence on selection (no Save button)
- Checkmark indicator for selected option

The Theme picker and Tip Jar also use push navigation and follow the same visual pattern.

CSV Import and Paywall use sheet presentation (modal), which is appropriate for their task-completion flows.

**Assessment:** Consistent and well-matched to purpose.

### 17. Accessibility Concerns

- All toggle rows use `Toggle("", isOn:)` with `.labelsHidden()`. The empty string label means VoiceOver users hear no label for the toggle itself — they rely on the adjacent `Text` views being read first.
- `contentShape(Rectangle())` is properly applied to tappable rows, ensuring the full row is a tap target.
- No explicit `.accessibilityLabel()` modifiers found on any setting rows.

---

## Code Quality Issues

1. **`CSVImportSuccessStep.swift` uses `AnyView` type erasure** — the `guard let` + `AnyView` pattern is non-idiomatic SwiftUI. Should use `if let` with `@ViewBuilder` or `Group`.

2. **Unused `@Environment(\.dismiss)` in threshold pickers** — `DueSoonDaysThresholdPicker` and `DueSoonMileageThresholdPicker` both import dismiss but never use it.

3. **Hardcoded default values in picker views** — The `if option == 750` and `if option == 30` checks duplicate knowledge that should live in the settings model (e.g., `DueSoonSettings.defaultDaysThreshold`).

4. **`SettingsView` queries `vehicles` but never uses them** — Line 14: `@Query private var vehicles: [Vehicle]` is declared but not referenced anywhere in the view body.

5. **ProPaywallSheet hardcodes debug/release branching inline** — The `#if DEBUG` block in the purchase action (lines 61-75) duplicates logic that should be handled by the StoreManager abstraction.

6. **TipModalView and TipJarView duplicate purchase/gacha logic** — Both views have nearly identical `purchaseTip` / tip handling code with the `unlockRandomRareTheme` + analytics pattern. This should be extracted to a shared helper.

7. **Inconsistent `Task { @MainActor in }` usage** — Some `onChange` handlers wrap in `Task { @MainActor in }` (e.g., DueSoonDaysThresholdPicker line 50), while others just call directly. Since these views are already on the main actor (SwiftUI views), the Task wrapping is unnecessary but should at least be consistent.

---

## Recommendations

### High Priority

1. **Add feedback for locked rare theme taps** — Navigate to the Tip Jar or show an inline prompt when a user taps a locked rare theme. Never let a tap produce zero visible response.

2. **Group Sync under Data section** — Merge `SyncSettingsSection` into the Data section to create "DATA & SYNC", reducing section fragmentation and improving logical grouping.

3. **Show setting dependencies visually** — Dim/disable Climate Zone when Seasonal Alerts is off. Dim/disable clustering window pickers when Service Bundling is off. Add subtitle text explaining the dependency.

4. **Add CSV import confirmation** — Before `performImport` commits, show an alert: "Import [X] services with [Y] logs to [Vehicle Name]?" with Cancel/Import buttons.

5. **Show gacha collection progress** — In the Tip Jar and Tip Modal, display "X/Y rare themes collected" so users know what they're working toward and whether more tips will yield new themes.

### Medium Priority

6. **Add purchase error display to TipModalView** — Show error text below the tip buttons when a purchase fails, matching the pattern in ProPaywallSheet.

7. **Explain distance unit impact** — Add a description line to DistanceUnitPickerView: "Changes how mileage is displayed throughout the app. Your data is not converted."

8. **Standardize haptic feedback** — Add `HapticService.shared.selectionChanged()` to ServiceBundlingToggle and both Clustering pickers to match all other settings interactions.

9. **Fix CSVImportSuccessStep code pattern** — Replace `AnyView` type erasure with `if let` + `@ViewBuilder`.

10. **Remove unused code** — Drop `@Environment(\.dismiss)` from threshold pickers, drop `@Query private var vehicles` from SettingsView.

### Low Priority

11. **Localize remaining hardcoded strings** — Create L10n keys for all hardcoded English strings in settings views, especially the section headers, toggle labels, and CSV import text.

12. **Enhance theme reveal animation** — Consider adding scale, spring, or shimmer effects to the ThemeRevealView to make the gacha moment more rewarding.

13. **Revise paywall "future" features** — Either remove the "Future" prefix or replace with a more concrete value proposition that doesn't promise unbuilt features.

14. **Add accessibility labels** — Add `.accessibilityLabel()` to setting rows and toggle components for VoiceOver users.

15. **Extract duplicate tip purchase logic** — Create a shared helper for the tip purchase + gacha unlock + analytics flow used in both TipJarView and TipModalView.
