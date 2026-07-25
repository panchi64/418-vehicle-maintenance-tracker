# Vehicle Management -- UX Audit

## Executive Summary

The vehicle management flows in Checkpoint are broadly well-designed, with a clear two-step wizard, VIN OCR/decode integration, and multiple paths for mileage updates. However, the audit reveals several issues that undermine the experience: a completely dead legacy view (`AddVehicleView.swift`) that duplicates 400+ lines of logic; design system violations (rounded corners in picker, inconsistent fonts); missing haptic/toast feedback in the wizard save path; a VIN validation function duplicated four times across the codebase; and a `VehicleSelector` component that is defined but never used in production. These issues range from user-facing friction (no save confirmation in the wizard, delete button discoverable only via context menu in picker) to maintainability debt (quadruple VIN validation, two competing VIN character-count subviews).

---

## Strengths

1. **Two-step wizard is well-structured.** The `AddVehicleFlowView` splits vehicle creation into Basics (required fields + VIN) and Details (optional fields). The step indicator, animated transitions, and disabled "Next" button until basics are valid all provide clear guidance.

2. **VIN value-prop banner is excellent.** When VIN is empty, the `VINValuePropBanner` educates users on *why* they should enter it ("Enter your VIN to auto-fill vehicle details"). This disappears once a VIN is entered -- good progressive disclosure.

3. **Auto-fill feedback loop is complete.** After VIN lookup succeeds, an amber border highlights auto-filled fields, a green "details filled" banner appears, and both auto-clear after 3 seconds. This creates a satisfying moment of delight.

4. **VIN character count is progressive.** Shows "17-CHARACTER VEHICLE IDENTIFICATION NUMBER" when empty, live "X / 17 CHARACTERS" during input, and a green checkmark + "VALID -- LOOK UP" at 17 characters. This guides the user without blocking them.

5. **Undo on delete from picker.** `VehiclePickerSheet` captures a `VehicleSnapshot` and offers an "UNDO" toast action after deletion. This is a safety net that respects user data.

6. **Delete confirmation is context-aware.** The delete alert in `VehiclePickerSheet` shows a different message if it's the user's only vehicle vs. one of many. The `EditVehicleView` also uses a `confirmationDialog` with a clear warning about data loss.

7. **Mileage update has multiple entry points.** Users can update via: (a) the `QuickMileageUpdateCard` on the home tab, (b) tapping the mileage in `VehicleHeader`, or (c) via Siri. Each converges on the same `MileageUpdateSheet`, ensuring consistency.

8. **OCR flows are well-integrated.** Both VIN and odometer OCR use full-screen camera sheets, show processing indicators, handle errors with dismissible messages, and (for odometer) present a confirmation view before accepting the value.

9. **Marbete picker has good status feedback.** Shows VALID/EXPIRES SOON/EXPIRED with color-coded indicators and the formatted date. Accessible to Puerto Rico users while ignorable (all "Not Set") for others.

10. **Accessibility labels and hints are present throughout.** Vehicle header, picker rows, mileage card, and selector all have `accessibilityLabel` and `accessibilityHint` annotations.

---

## Issues Found

### Critical

**C1. Legacy `AddVehicleView.swift` is dead code (400+ lines).**
- **File:** `checkpoint-app/checkpoint/Views/Vehicle/AddVehicleView.swift`
- **Evidence:** `ContentView.swift:269` presents `AddVehicleFlowView()`, not `AddVehicleView`. Grepping shows `AddVehicleView` is only referenced in its own file and its test file (`AddVehicleViewTests.swift`).
- **Impact:** 400+ lines of duplicated logic with subtle divergences from the wizard (no marbete support, no analytics tracking for OCR/vehicle-added events, hardcoded strings instead of L10n, no `AppState.selectedVehicle` assignment on save). If a developer accidentally references this view, users get a degraded experience.
- **Recommendation:** Delete `AddVehicleView.swift` and `AddVehicleViewTests.swift`. Ensure all tests cover `VehicleFormState` and the wizard flow instead.

**C2. No save confirmation feedback in `AddVehicleFlowView.saveVehicle()`.**
- **File:** `checkpoint-app/checkpoint/Views/Vehicle/AddVehicleFlow/AddVehicleFlowView.swift:203-242`
- **Evidence:** The `saveVehicle()` method calls `modelContext.insert(vehicle)` and `dismiss()` but does NOT call `HapticService.shared.success()` or `ToastService.shared.show()`. Compare with `EditVehicleView.saveChanges()` (line 334) which calls both, and legacy `AddVehicleView.saveVehicle()` (line 395) which calls both.
- **Impact:** After completing a 2-step wizard, the user gets zero confirmation that their vehicle was saved. The sheet simply dismisses. This feels like it might have failed.
- **Recommendation:** Add `HapticService.shared.success()` and `ToastService.shared.show(L10n.toastVehicleSaved, icon: "checkmark", style: .success)` to `AddVehicleFlowView.saveVehicle()`, matching the pattern in `EditVehicleView`.

### Major

**M1. VIN validation logic is duplicated four times.**
- **Locations:**
  - `VehicleFormState.isVINValid` (line 64-71)
  - `AddVehicleView.isVINValid` (line 49-54)
  - `EditVehicleVINSection.isVINValid` (line 27-32)
  - Implicit in `EditVehicleView` via `EditVehicleVINSection`
- **Impact:** Any change to VIN validation rules (e.g., supporting older 11-character VINs) must be updated in four places. The implementations are identical but this is a maintenance trap.
- **Recommendation:** Consolidate into a single `static func isValidVIN(_ vin: String) -> Bool` on `Vehicle` or a utility, and reference it everywhere.

**M2. VehiclePickerSheet uses `RoundedRectangle(cornerRadius: 16)` -- violates brutalist zero-corner-radius design system.**
- **File:** `checkpoint-app/checkpoint/Views/Vehicle/VehiclePickerSheet.swift:130-134, 154-157`
- **Evidence:** The vehicle list container and "Add Vehicle" button both use `cornerRadius: 16`. The design system mandates `Theme.buttonCornerRadius = 0` (zero corner radius, brutalist aesthetic).
- **Impact:** Visual inconsistency with the rest of the app. The picker looks "rounded iOS default" while everything else is sharp.
- **Recommendation:** Replace `RoundedRectangle(cornerRadius: 16, style: .continuous)` with `Rectangle()` to match the brutalist design system.

**M3. EditVehicleView delete button uses `RoundedRectangle(cornerRadius: Theme.buttonCornerRadius)` -- correct value (0) but wrong shape type.**
- **File:** `checkpoint-app/checkpoint/Views/Vehicle/EditVehicleView.swift:203-207`
- **Evidence:** Uses `RoundedRectangle(cornerRadius: Theme.buttonCornerRadius, style: .continuous)` where `Theme.buttonCornerRadius = 0`. While this renders as a rectangle, it's semantically confusing. All other views in the app use `Rectangle()` for zero-corner shapes.
- **Recommendation:** Replace with `Rectangle()` for clarity and consistency.

**M4. EditVehicleVINSection VIN help text uses `.caption` font instead of design system fonts.**
- **File:** `checkpoint-app/checkpoint/Views/Vehicle/EditVehicleVINSection.swift:84-96`
- **Evidence:** Line 85 uses `.caption` (system font) while the wizard (`VehicleBasicsStep`) uses `.brutalistLabel` with `.tracking(1.5)` for the same purpose. The edit form also has a different layout (shows count as `X/17` on the right side) vs the wizard (shows `X / 17 CHARACTERS` inline).
- **Impact:** Visual inconsistency between add and edit flows for the same field.
- **Recommendation:** Use the same `VINCharacterCountLabel` component (from `VehicleBasicsStep`) in `EditVehicleVINSection`, or extract it as a shared component.

**M5. EditVehicleView marbete description uses `.caption` instead of `.brutalistSecondary`.**
- **File:** `checkpoint-app/checkpoint/Views/Vehicle/EditVehicleView.swift:173-176`
- **Evidence:** `Text("Puerto Rico vehicle registration tag expiration (optional)").font(.caption)` vs the wizard's `Text("Yearly vehicle registration tag expiration").font(.brutalistSecondary)`.
- **Impact:** Inconsistent typography between add and edit forms. The description text also differs ("Puerto Rico..." vs "Yearly...").
- **Recommendation:** Use `.brutalistSecondary` and harmonize the description text.

**M6. `VehicleSelector` component is unused in production code.**
- **File:** `checkpoint-app/checkpoint/Views/Components/Navigation/VehicleSelector.swift`
- **Evidence:** Grep shows it only appears in its own file definition and preview. `VehicleHeader` handles the vehicle-selection UI directly with its own button layout.
- **Impact:** Dead code. Confusing for developers who might try to use it.
- **Recommendation:** Delete `VehicleSelector.swift` or integrate it into `VehicleHeader` if the original intent was to share the component.

**M7. VIN lookup in edit flow only fills empty fields -- no user notification of skip.**
- **File:** `checkpoint-app/checkpoint/Views/Vehicle/EditVehicleVINSection.swift:155-161`
- **Evidence:** `lookUpVIN()` silently skips fields that already have values (`if make.isEmpty { make = result.make }`). But there's no feedback to tell the user "Make, Model, and Year were already filled so no changes were made."
- **Impact:** User taps "Look Up VIN", sees the loading spinner, and then... nothing changes. They might think it failed.
- **Recommendation:** Show a brief toast or inline message when VIN lookup succeeds but all fields were already populated: "Fields already filled -- no changes needed."

**M8. Edit flow VIN lookup lacks the auto-fill highlight and success banner present in the wizard.**
- **File:** `checkpoint-app/checkpoint/Views/Vehicle/EditVehicleVINSection.swift` (entire file -- no `autoFilledFields` or success banner)
- **Evidence:** The wizard (`VehicleBasicsStep`) highlights auto-filled fields with amber borders and shows a "Vehicle details auto-filled from VIN" banner. `EditVehicleVINSection` does neither.
- **Impact:** The edit experience feels less polished than the add experience. Users don't get confirmation that VIN lookup worked.
- **Recommendation:** Port the auto-fill feedback from the wizard to the edit VIN section.

### Minor

**m1. VIN input in wizard shows VIN on Step 1 but odometer on Step 2 -- could confuse users about what's "basic" vs "detail".**
- **File:** `VehicleBasicsStep.swift` (includes VIN section), `VehicleDetailsStep.swift` (includes odometer)
- **Observation:** VIN is arguably more of a "detail" than "basic info", while current mileage could be considered more fundamental. However, the current arrangement makes sense for the VIN-lookup auto-fill flow (enter VIN first to populate Make/Model/Year).
- **Impact:** Low. The current arrangement enables the VIN auto-fill workflow. No change needed, but consider whether the section header "Vehicle Identification" on step 1 makes this clear enough.

**m2. Year picker allows any integer -- no validation for reasonable range.**
- **File:** `VehicleFormState.isBasicsValid` (line 57-61) checks only `year != nil`
- **Evidence:** A user could enter 0, 9999, or negative numbers. The `InstrumentNumberField` likely accepts any integer.
- **Impact:** Low probability but could produce nonsensical data like "Year: 0" or "Year: 9999".
- **Recommendation:** Add range validation (e.g., 1900...currentYear+2) to `VehicleFormState.isBasicsValid` and show inline feedback.

**m3. License Plate field uses hardcoded string "License Plate" and "ABC-1234 (Optional)" instead of L10n.**
- **File:** `VehicleBasicsStep.swift:79`, `EditVehicleVINSection.swift:138`, `AddVehicleView.swift:222`
- **Impact:** Not localized. All other fields use `L10n.*` references.
- **Recommendation:** Add L10n keys for license plate label and placeholder.

**m4. Marbete section header is hardcoded "Marbete" in both wizard and edit form.**
- **Files:** `VehicleDetailsStep.swift:70`, `EditVehicleView.swift:165`
- **Impact:** Not localized, though "Marbete" is a Spanish term specific to Puerto Rico. May still benefit from an L10n entry for consistency.

**m5. `MileageInputField` has a `stringValue` convenience initializer that appears unused.**
- **File:** `checkpoint-app/checkpoint/Views/Components/Inputs/MileageInputField.swift:89-101`
- **Evidence:** Comment says "backwards compatibility". No callers found in grep.
- **Impact:** Dead code.
- **Recommendation:** Remove the `stringValue` initializer.

**m6. VehiclePickerSheet `.presentationDetents([.medium])` may be too small for 3+ vehicles.**
- **File:** `checkpoint-app/checkpoint/Views/Vehicle/VehiclePickerSheet.swift:181`
- **Impact:** With 3+ vehicles, the list may require scrolling within a half-screen sheet. Users might not realize they need to scroll or could accidentally dismiss.
- **Recommendation:** Use `.presentationDetents([.medium, .large])` to let users expand the sheet if needed.

**m7. The wizard `StepIndicator` uses small 8x8 squares that may be hard to see.**
- **File:** `VehicleBasicsStep.swift:94-114`
- **Impact:** The step indicator is purely visual and non-interactive. At 8x8 pixels, it's easy to miss, especially on larger devices.
- **Recommendation:** Consider making the indicator slightly larger (12x12) or adding step labels ("BASICS" / "DETAILS").

**m8. Marbete "Not Set" option in pickers requires scroll past "Not Set" to find months -- could be clearer.**
- **File:** `checkpoint-app/checkpoint/Views/Components/Inputs/MarbetePicker.swift:40-50`
- **Impact:** "Not Set" appears as the first menu item for both month and year. This is correct but could be more discoverable for clearing a previously-set value. A separate "Clear" button might be more intuitive.
- **Recommendation:** Minor -- current pattern is acceptable but consider a dedicated "Clear Marbete" button when both values are set.

**m9. `MileageUpdateSheet` input field has no placeholder text.**
- **File:** `checkpoint-app/checkpoint/Views/Components/Cards/MileageUpdateSheet.swift:268`
- **Evidence:** `TextField("", text: mileageBinding)` -- empty string placeholder.
- **Impact:** When the field is empty, there's no hint about what to type. The label "ENTER MILEAGE" above helps, but a placeholder like "45,000" would reinforce expectations.
- **Recommendation:** Add a placeholder showing a sample mileage value.

---

## Detailed Findings

### Add Vehicle Wizard Flow

The `AddVehicleFlowView` is the primary vehicle creation path. It presents as a sheet with two steps:

**Step 1 -- Basics:** Nickname (optional), Make (required), Model (required), Year (required), VIN (optional with scan + lookup), License Plate (optional). The "Next" button is disabled until `isBasicsValid` returns true. Step transitions use `.asymmetric` move animations.

**Step 2 -- Details:** Current Mileage (with camera OCR), Tire Size, Oil Type, Marbete expiration, Notes. The "Save" button is always enabled on this step since all fields are optional.

**Key observations:**
- The wizard correctly reads `appState.onboardingMarbeteMonth/Year` on appear to prefill marbete from onboarding.
- The `VehicleFormState` class uses `@Observable` without `@MainActor`, which is correct since it's a simple form state.
- The save method assigns `appState.selectedVehicle = vehicle` after insert, which correctly makes the new vehicle active.
- OCR flows use `.fullScreenCover` for camera and `.sheet` for confirmation -- appropriate modality levels.

### VIN Scanning & NHTSA Decode

The VIN flow is the most sophisticated interaction in vehicle management:

1. User types VIN or scans with camera
2. At 17 valid characters, "Look Up VIN" button appears
3. Tapping triggers NHTSA decode with spinner
4. On success, empty Make/Model/Year fields are auto-filled with amber highlight
5. Success banner appears and auto-clears after 3 seconds

**Issues:** The auto-fill only populates empty fields, which is smart for the wizard (prevents overwriting user input) but confusing in edit mode where fields are always pre-populated. In edit mode, VIN lookup will never auto-fill anything unless the user manually clears fields first. There's no feedback explaining this behavior.

### Mileage Update Flow

Three entry points converge on `MileageUpdateSheet`:

1. **QuickMileageUpdateCard** (home tab, shown when `shouldPromptMileageUpdate`) -- tapping "UPDATE" opens the sheet
2. **VehicleHeader mileage tap** -- tapping the amber mileage number in the header opens the sheet via `ContentView`
3. **Siri intent** -- sets `PendingMileageUpdate` which `ContentView` picks up on `scenePhase == .active`

The sheet provides context (current estimate, last confirmed reading) and a number input with camera OCR. Save validation requires `mileage > 0`.

**Issue:** The sheet doesn't validate that the new mileage is greater than the current mileage. A user could accidentally enter a lower number (e.g., typo), which would corrupt pace calculations. Consider adding a warning (not a block) when the entered mileage is lower than the current reading.

### Vehicle Switching

The `VehicleHeader` is persistent at the top of all tabs and includes:
- Vehicle name (tappable to open picker)
- Mileage display (tappable to update mileage)
- Year/Make/Model info
- "[SELECT]" label indicating tappability
- Settings gear icon
- Sync error indicator (only on error)

The `VehiclePickerSheet` presents as a half-screen sheet with:
- List of vehicles with checkmark on selected
- Context menu (long press) for Edit/Delete
- Ellipsis menu button for Edit/Delete (same actions)
- "Add Vehicle" button at bottom

**Observation:** Having both context menu AND an ellipsis menu provides redundant access to Edit/Delete. This is actually good for discoverability -- context menus are hidden affordances, while the ellipsis is visible.

### Delete Vehicle Safety

Two delete paths exist:
1. **EditVehicleView:** Red "Delete Vehicle" button at the bottom of the form. Shows `confirmationDialog` with warning about data loss. On confirm, deletes vehicle, updates app icon, clears widget data, calls `dismiss()`.
2. **VehiclePickerSheet:** Via context menu or ellipsis menu. Shows `alert` with context-aware message. On confirm, captures snapshot for undo, cancels all notifications, clears widget data, deletes vehicle, shows toast with UNDO action.

**Discrepancy:** The picker delete path is more thorough (cancels notifications, offers undo). The edit view delete path does NOT cancel service notifications and does NOT offer undo. This is a consistency gap.

---

## Code Quality Issues

1. **Duplicate `VINCharacterCount` views.** `VINCharacterCountLabel` (in `VehicleBasicsStep.swift:238-266`) and `VINCharacterCountView` (in `AddVehicleView.swift:417-445`) are nearly identical but differ in name and minor structure. Both should be consolidated or the dead one removed.

2. **`EditVehicleView` has massive state surface.** The view declares 18+ `@State` properties (lines 21-52). The wizard solved this with `VehicleFormState` -- the edit view should use a similar form state object.

3. **`VehiclePickerSheet.VehicleSnapshot.restore()` does not restore services.** The snapshot captures vehicle properties and re-inserts with the same UUID, but cascade-deleted services, logs, and mileage snapshots are permanently lost. The undo only restores the vehicle shell.

4. **Inconsistent string usage.** The wizard uses `L10n.*` localization keys extensively. The edit view and picker use hardcoded strings ("Vehicle Details", "Odometer", "Identification", "Specifications", etc.). This makes the edit flow non-localizable.

5. **`EditVehicleOdometerSection` and `EditVehicleVINSection` pass 5-12 bindings each.** This is a code smell indicating these should use a shared form state object (like `VehicleFormState`) rather than passing individual bindings.

6. **No `@Query` filter on `EditVehicleView.services`.** Line 14 declares `@Query private var services: [Service]` which fetches ALL services across ALL vehicles, but only uses it for `updateAppIcon()`. This is inefficient for users with many services.

---

## Recommendations

### High Priority
1. **Delete `AddVehicleView.swift` and its test file** -- it's dead code that diverges from the wizard.
2. **Add haptic + toast feedback to `AddVehicleFlowView.saveVehicle()`** to match edit flow.
3. **Consolidate VIN validation** into a single utility method.
4. **Fix `VehiclePickerSheet` corner radius** to use `Rectangle()` per design system.
5. **Harmonize edit/add VIN section** -- use same component or at minimum same fonts and feedback patterns.

### Medium Priority
6. **Extract `VehicleFormState` pattern for edit flow** to reduce the 18-binding sprawl in `EditVehicleView`.
7. **Make edit view delete path match picker delete path** -- add notification cancellation and undo capability.
8. **Add VIN lookup feedback for pre-populated fields** -- tell user when lookup succeeded but no fields needed updating.
9. **Delete `VehicleSelector.swift`** -- unused component.
10. **Add mileage regression warning** to `MileageUpdateSheet` when entered value is lower than current reading.

### Low Priority
11. Add year range validation to `VehicleFormState.isBasicsValid`.
12. Localize remaining hardcoded strings in edit view and picker.
13. Add placeholder text to `MileageUpdateSheet` input field.
14. Remove `MileageInputField.stringValue` convenience initializer (dead code).
15. Consider `.presentationDetents([.medium, .large])` for `VehiclePickerSheet`.
16. Enlarge `StepIndicator` squares from 8x8 to 12x12 for better visibility.
