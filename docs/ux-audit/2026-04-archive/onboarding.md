# Onboarding & First-Time Experience -- UX Audit

## Executive Summary

The onboarding flow is architecturally sound with a clean three-phase structure (Intro -> Tour -> Get Started), a well-designed state machine, and thoughtful analytics tracking at each step. The brutalist aesthetic is applied consistently throughout. However, several significant issues undermine the user experience: the VIN lookup result is silently discarded when transitioning to AddVehicleFlowView, the feature hint system (`FeatureHintView`) is fully built but never integrated into any production views, and the Marbete section uses region-specific jargon without adequate context for non-Puerto Rico users. The flow has strong bones but needs targeted fixes to deliver on its promise.

---

## Strengths

1. **Well-structured state machine.** `OnboardingState` uses a clean enum-based phase model (`intro -> tour -> tourTransition -> getStarted -> completed`) with explicit transition methods. This makes the flow predictable and easy to reason about.

2. **Skip is always available.** Every phase offers a skip button: intro pages, tour overlay, tour transition cards, and the Get Started view. Users are never trapped.

3. **Sample data during tour.** The tour seeds realistic sample data (two vehicles with services and logs) so spotlighted areas show real content rather than empty states. Sample data is cleaned up automatically when the tour ends or is skipped.

4. **iCloud awareness.** The Get Started view detects existing iCloud data and offers a "Use Your iCloud Vehicles" option, handling the reinstall/new device scenario gracefully.

5. **Tour transition cards.** When the tour crosses tab boundaries, a full-screen transition card names the new section (e.g., "03 // SERVICES") before the spotlight resumes. This orients the user during tab changes.

6. **Comprehensive analytics.** Every onboarding path is tracked: tour started, tour skipped (with step number), VIN lookup used, manual entry, iCloud sync, intro skipped, Get Started skipped, and overall completion.

7. **Notification permission deferred.** Permission is requested after onboarding completes rather than during, which avoids the common anti-pattern of asking for permissions before the user understands the app's value.

8. **Preferences are changeable.** Both the distance unit and climate zone pickers explicitly state "You can change this later in Settings," reducing decision anxiety.

9. **Consistent visual identity.** All onboarding screens use `AtmosphericBackground()`, `.preferredColorScheme(.dark)`, and the brutalist design tokens consistently.

10. **VIN validation is correct.** The 17-character check with I/O/Q exclusion matches the actual VIN standard.

---

## Issues Found

### Critical

#### C1: VIN Lookup Result Is Discarded on Transition
**Location:** `ContentView.swift:398`
**Impact:** User wastes effort; has to re-enter vehicle details manually

The `onVINLookupComplete` callback in ContentView receives the `VINDecodeResult` and VIN string but ignores both parameters: `{ _, _ in }`. After the user types or scans their VIN, waits for the API lookup, sees their vehicle's make/model/year confirmed, and taps "Add Vehicle," the onboarding completes and the AddVehicleFlowView opens with no prefilled data. The entire VIN lookup was wasted effort.

The `OnboardingGetStartedView` correctly passes the result to `onVINLookupComplete(vinResult!, vin)`, but the parent discards it. This is the single most damaging UX bug in the onboarding flow -- it punishes users for engaging with the app's most impressive onboarding feature.

**Fix:** Store the VIN result on AppState (e.g., `onboardingVINResult` / `onboardingVIN`), pass it to AddVehicleFlowView as prefill data, and clear it on dismiss.

---

#### C2: Feature Hints Are Built but Never Integrated
**Location:** `FeatureHintView.swift`, `FeatureDiscovery.swift`, all production views
**Impact:** Progressive disclosure system exists only in previews; new users get no contextual guidance

The `FeatureHintView` component and `FeatureDiscovery` singleton are fully implemented with persistence, dismissal tracking, and four feature hints (VIN lookup, odometer OCR, swipe navigation, service bundling). An `INTEGRATION_GUIDE.md` exists with exact placement instructions. However, `FeatureHintView` appears in zero production views -- only in its own preview code. A search across all `Views/Tabs/`, `Views/Vehicle/`, and `Views/Service/` directories returns no matches.

This means the entire post-onboarding progressive disclosure layer is inert. Users who skip the tour or forget what they saw have no contextual help.

**Fix:** Integrate the four hints as described in the integration guide: VIN hint in vehicle details, OCR hint in mileage update, swipe hint on the home tab, bundling hint near service clusters.

---

### Major

#### M1: Marbete Section Uses Unexplained Regional Jargon
**Location:** `OnboardingGetStartedView.swift:170-198`
**Impact:** Confusing for users outside Puerto Rico; potentially alienating

The collapsible section is labeled "MARBETE / REGISTRATION TAG" with a hard-coded English description: "Track your yearly vehicle registration expiration and get reminders before it lapses." The term "Marbete" is specific to Puerto Rico and is not localized (it appears as a raw string, not an L10n key). While the "/ REGISTRATION TAG" clarification helps, leading with unfamiliar jargon in a first-time experience is jarring for most users.

Additionally, the description text is hard-coded rather than going through L10n, creating a localization gap.

**Fix:** Consider leading with "REGISTRATION TAG" and optionally including "MARBETE" as a parenthetical for PR users. Move all strings to L10n. Consider whether this section should appear during onboarding at all versus later in vehicle settings.

---

#### M2: Tour Spotlight Positions Are Hard-Coded Magic Numbers
**Location:** `OnboardingTourOverlay.swift:173-213`
**Impact:** Spotlight may not align with actual UI elements on different device sizes

The spotlight rectangles use hard-coded offsets: `headerBottom = Spacing.sm + 72`, `tabBarHeight = 72`, and percentages of content area (`0.45`, `0.55`). These values assume specific layout geometry. On larger devices (iPad, iPhone 17 Pro Max) or with Dynamic Type, the spotlights may not frame the intended elements.

**Fix:** Use `GeometryReader` with named coordinate spaces or anchor preferences to measure actual element positions. At minimum, test spotlight alignment on SE, standard, and Max device sizes.

---

#### M3: Tour Auto-Advance Timer Creates Race Condition Risk
**Location:** `OnboardingTourTransitionCard.swift:74`
**Impact:** User may see a flash of transition card or miss it entirely

The transition card auto-advances after 1.5 seconds via `DispatchQueue.main.asyncAfter`. If the user taps to advance before the timer fires, `onContinue()` is called twice (once by tap, once by timer). While the state machine likely handles this gracefully (the guard in `resolveTransition` prevents double-advancement), it is still calling `onContinue()` redundantly after the view has already been dismissed.

**Fix:** Use a cancellable `Task` instead of `DispatchQueue.main.asyncAfter` and cancel it when `onContinue` is called or the view disappears.

---

#### M4: No Error Recovery Guidance for VIN Scan Failure
**Location:** `OnboardingGetStartedView.swift:343-356`
**Impact:** User hits dead end if camera OCR fails

When VIN OCR fails, the error message is set to `error.localizedDescription`, which may produce unhelpful system-level error text (e.g., "The operation couldn't be completed"). There is no guidance to try again, adjust lighting, or fall back to manual entry. The error appears as a single red line of text that is easy to miss.

**Fix:** Show a user-friendly error message that suggests: (1) trying again with better lighting, (2) entering the VIN manually, or (3) where to find the VIN on their vehicle.

---

#### M5: "No Services" Empty State Offers No Action
**Location:** `HomeTab+EmptyStates.swift:53-59`
**Impact:** Dead end for user after adding vehicle but before adding services

The `noServicesState` says "All Clear / No maintenance services scheduled for this vehicle" with a checkmark icon but provides no action button. For a first-time user who just added a vehicle, this is a dead end. They need to discover the FAB (floating action button) on their own to add their first service. This contradicts the empty state pattern used elsewhere (e.g., `emptyVehicleState` has an "Add Vehicle" button).

**Fix:** Add an action button like "Schedule Service" or "Log Service" that triggers the add service flow.

---

#### M6: Distance Unit and Climate Zone Have No Visual Default Indicator
**Location:** `OnboardingIntroView.swift:136-186`
**Impact:** User may not realize a default is already selected

The distance unit segmented control reads from `DistanceSettings.shared.unit` (which defaults to miles based on locale), and the climate zone reads from `SeasonalSettings.shared.climateZone`. If the default happens to match what the user wants, there is no visual cue that a selection is already active for climate zone until they look for the checkmark. The preferences page appears as a configuration step that must be completed, but it may already be correct.

**Fix:** Add a subtle note like "Based on your device settings" near the default selection, or pre-select with visual emphasis.

---

### Minor

#### m1: Intro Page Count Mismatch in Comment
**Location:** `OnboardingIntroView.swift:5`
**Impact:** Developer confusion only

The file comment says "Phase 1: Full-screen intro pages -- Welcome and Preferences (Distance Unit + Climate Zone)" and the code has 2 pages (welcome + preferences), but the review instructions reference "3 pages." The `StepIndicator` correctly shows 2 steps. No user impact, but the discrepancy may cause confusion during maintenance.

---

#### m2: "Swipe to continue" Affordance Is Subtle
**Location:** `OnboardingIntroView.swift:50-58`
**Impact:** Some users may not realize the welcome page is swipeable

The swipe hint at the bottom of page 1 uses `Theme.textTertiary` (the lightest text color) with a small chevron. On a dark background with an atmospheric effect, this may be too subtle for some users. There is no animated cue (like a bouncing arrow or parallax hint) to suggest swipeability.

**Fix:** Consider adding a brief horizontal bounce animation on first appearance, or increase the text to `Theme.textSecondary`.

---

#### m3: Hardcoded "MAKE/MODEL/YEAR" Labels in VIN Result
**Location:** `OnboardingGetStartedView.swift:141-145`
**Impact:** Minor localization gap

The VIN result rows use hardcoded strings: `"MAKE"`, `"MODEL"`, `"YEAR"`. These should be L10n keys for localization.

---

#### m4: Tour Card Positioning Uses Hardcoded 90pt Bottom Padding
**Location:** `OnboardingTourOverlay.swift:128`
**Impact:** Tour card may overlap or float too high on some devices

The `.padding(.bottom, 90)` positions the tour card above the tab bar. This assumes a specific tab bar height + safe area combination. On devices with different safe area insets, the card may misalign.

---

#### m5: `isVisible` State in `FeatureHintView` Starts True but Feature May Be Seen
**Location:** `FeatureHintView.swift:21`
**Impact:** Potential flash of hint before dismissal check

`@State private var isVisible: Bool = true` does not check `FeatureDiscovery.shared.shouldShowHint(for:)`. The calling code is expected to wrap the view in a `shouldShowHint` check (as the integration guide shows). If a developer forgets this wrapper, the hint will always appear regardless of dismissal state.

**Fix:** Initialize `isVisible` from `FeatureDiscovery.shared.shouldShowHint(for: feature)` in the initializer or `onAppear`.

---

#### m6: Preview Redundancy in EmptyStateView
**Location:** `EmptyStateView.swift:83-156`
**Impact:** None (code cleanliness only)

The preview section includes 5 separate previews with hardcoded strings that duplicate content from production usage. Not a UX issue, but worth noting for maintenance.

---

## Detailed Findings

### Flow Length and Pacing

The onboarding flow has 3 phases with approximately 8 total screens/interactions:

1. **Intro Page 1** (Welcome + 3 feature bullets)
2. **Intro Page 2** (Distance unit + Climate zone)
3. **Tour Step 0** (Dashboard spotlight)
4. **Tour Step 1** (Vehicle header spotlight)
5. **Tour Transition** (Services section card)
6. **Tour Step 2** (Services spotlight)
7. **Tour Transition** (Costs section card)
8. **Tour Step 3** (Costs spotlight)
9. **Get Started** (VIN entry)

This is a reasonable length for a vehicle maintenance app. However, the tour portion (steps 0-3 plus transitions) adds 6 screens that are informational-only with no user interaction beyond tapping "Next." Users who are eager to start may find this portion slow. The 1.5-second auto-advance on transition cards helps somewhat.

The skip options at every phase are well-placed and mitigate flow-length concerns.

### First-Launch to First-Value Time

**Fastest path (skip everything):** Tap "Skip" on intro -> lands on empty home screen. Time: ~2 seconds. But the user gets zero value and faces an empty state with no services.

**Fastest meaningful path:** Tap "Skip" on intro -> empty home screen -> tap "Add Vehicle" in empty state -> fill basics (2 steps) -> add first service. Estimated: 2-4 minutes.

**Intended path with VIN:** Complete intro (2 pages) -> Take tour (6 screens) -> Enter VIN on Get Started -> VIN lookup fills details -> tap "Add Vehicle" -> BUT VIN data is discarded (C1), so they re-enter everything. Estimated: 5-8 minutes, with frustration at the VIN step.

**If C1 is fixed:** The VIN path becomes the fastest to meaningful value -- enter VIN, auto-fill vehicle, done. Estimated: 3-5 minutes.

### Dual-Axis Tracking Understanding

The onboarding does not explicitly explain the dual-axis (date + mileage) tracking concept. The welcome page mentions "Mileage and date-based reminders" in feature bullet 01, and the tour body for the Vehicle Header says "Tap the amber mileage when the odometer changes." However, nowhere is it explained that services track both axes simultaneously, or that either axis can trigger a due status.

For most users this is fine -- the concept is intuitive enough once they see it in action. But power users or users coming from simpler apps may not immediately grasp that updating mileage directly affects service due status.

### Return-to-App After Onboarding

When onboarding completes, the flow:
1. Clears sample data
2. Sets `hasCompletedOnboarding = true`
3. Enables CloudKit sync
4. Requests notification permission
5. User lands on the home tab

If the user completed VIN entry or manual entry, `showAddVehicle` is set after a 0.4-second delay, presenting the AddVehicleFlowView. If the user skipped, they land on an empty home screen with the "No Vehicles" empty state and its "Add Vehicle" button. This is a reasonable fallback.

However, the 0.4-second delay for presenting the add vehicle sheet (needed to avoid fullScreenCover dismissal conflicts) creates a brief flash of the empty home screen before the sheet appears. This is slightly jarring.

### iCloud Existing Data Detection

The iCloud detection in `OnboardingGetStartedView` checks `SyncStatusService.shared.hasICloudAccount && SyncStatusService.shared.hasExistingCloudData`. This appears during the Get Started phase, which is appropriate. If data syncs during the intro pages, `seedSampleDataForTour()` correctly detects existing vehicles and uses them instead of creating samples.

However, if iCloud data arrives after the tour has already seeded sample data, there is no mechanism to detect or merge. This is a narrow timing window and unlikely to cause real issues.

---

## Code Quality Issues

### CQ1: Force-Unwrap in VIN Result Callback
**Location:** `OnboardingGetStartedView.swift:203`
```swift
onVINLookupComplete(vinResult!, vin)
```
The `vinResult` is force-unwrapped. While the `if vinResult != nil` guard on line 201 makes this safe in practice, a force-unwrap in user-facing code is fragile. If future refactoring moves this block, the crash risk increases.

**Fix:** Use `if let result = vinResult` instead.

### CQ2: DispatchQueue.main.asyncAfter for Timer Logic
**Location:** `OnboardingTourTransitionCard.swift:74`, `ContentView.swift:402,410`
```swift
DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
    onContinue()
}
```
Multiple places use `DispatchQueue.main.asyncAfter` for delayed actions. These are not cancellable and can fire after the view has been dismissed.

**Fix:** Use `Task { try? await Task.sleep(for: .seconds(1.5)); onContinue() }` with cancellation, or use `.task` modifier.

### CQ3: Binding Setter Ignores Value
**Location:** `ContentView.swift:340,395`
```swift
set: { if !$0 { /* dismiss handled by callbacks */ } }
```
The fullScreenCover bindings have no-op setters with comments. While functionally correct (dismiss is handled by the callback closures), this pattern is a SwiftUI anti-pattern that may confuse future maintainers. The comment acknowledges it but does not explain why a dismiss callback does not simply set a boolean.

### CQ4: Hardcoded Strings in Marbete Section
**Location:** `OnboardingGetStartedView.swift:170,186-187`
```swift
Text("MARBETE / REGISTRATION TAG")
Text("Track your yearly vehicle registration expiration...")
```
These strings bypass the L10n localization system, unlike every other user-facing string in the onboarding flow.

### CQ5: `selectedClimateZone` State Duplicates Shared Setting
**Location:** `OnboardingIntroView.swift:16`
```swift
@State private var selectedClimateZone: ClimateZone? = SeasonalSettings.shared.climateZone
```
This `@State` is initialized from the shared setting and writes back to it on selection, but it also serves as the source of truth for the checkmark UI. If `SeasonalSettings.shared.climateZone` is changed externally (unlikely during onboarding, but architecturally fragile), the UI and the setting will diverge.

---

## Recommendations

### Priority 1 (Fix Now)

1. **Pass VIN data through to AddVehicleFlowView (C1).** Add `onboardingVINResult: VINDecodeResult?` and `onboardingVIN: String?` to AppState. In the `onVINLookupComplete` callback, store both values. In AddVehicleFlowView, prefill make/model/year/VIN from these values. Clear on dismiss.

2. **Integrate FeatureHintView in production views (C2).** Follow the existing INTEGRATION_GUIDE.md. Place hints in: vehicle detail (VIN lookup), mileage update sheet (odometer OCR), home tab (swipe navigation), and services tab (service bundling).

### Priority 2 (Fix Soon)

3. **Localize Marbete section and improve labeling (M1).** Move strings to L10n. Consider renaming to "Registration Expiration" with "Marbete" as a subtitle/parenthetical. Alternatively, hide this section for non-PR locale users.

4. **Add action button to "No Services" empty state (M5).** Add "Schedule Service" or "Log Service" action to match the pattern used in the "No Vehicles" empty state.

5. **Fix VIN lookup error messaging (M4).** Replace raw `error.localizedDescription` with a user-friendly message suggesting retry, better lighting, or manual entry fallback.

6. **Cancel auto-advance timer in transition cards (M3).** Replace `DispatchQueue.main.asyncAfter` with a cancellable `Task` pattern.

### Priority 3 (Improve)

7. **Make swipe hint more visible (m2).** Increase text color to `Theme.textSecondary` or add a subtle horizontal bounce animation on first load.

8. **Add "Based on your device" label near default selections (M6).** Helps users recognize they may not need to change anything on the preferences page.

9. **Localize VIN result labels (m3).** Move "MAKE", "MODEL", "YEAR" to L10n keys.

10. **Initialize `FeatureHintView.isVisible` from FeatureDiscovery (m5).** Add a self-contained check so the view does not depend on external wrapping logic for correctness.

11. **Test spotlight alignment on multiple device sizes (M2).** Consider using anchor preferences for dynamic measurement if hard-coded values prove brittle across devices.
