# Navigation, Inputs & Shared Components -- UX Audit

## Executive Summary

The Checkpoint app has a well-architected component system with a distinctive brutalist aesthetic that is consistently applied. The custom tab bar, instrument-styled inputs, and OCR camera flow are all thoughtfully designed. However, this audit identified **3 critical**, **8 major**, and **14 minor** issues that affect usability, discoverability, and polish. The most impactful problems are: (1) the FAB/[+] button lacks discoverability for the "schedule vs. log" distinction, (2) several touch targets are undersized, and (3) the toast dismiss button is too small and the swipe-down gesture direction is counterintuitive.

---

## Strengths

1. **Consistent brutalist design language.** Every component uses zero corner radius, 2px borders, monospace ALL CAPS labels, and the amber accent. The design system tokens (Theme, Spacing, Typography) are used almost everywhere rather than hardcoded values.

2. **Well-structured haptic feedback.** HapticService centralizes all haptic patterns with semantic methods (`tabChanged`, `selectionChanged`, `success`, `warning`). Tab changes use `.soft`, buttons use `.light`, and destructive actions use `.warning` -- appropriate escalation.

3. **Good accessibility baseline.** Most interactive elements have `accessibilityLabel` and `accessibilityHint`. The `EmptyStateView` combines children into a single accessibility element. StatusDot provides a text label. The `minimumTouchTarget()` modifier exists and is applied to small buttons like the error dismiss.

4. **Smart input field design.** `InstrumentTextField` and `InstrumentNumberField` have clear focus states (amber border + glow), uppercase labels with letter-spacing, and the number field properly filters non-numeric characters. The camera button accessory on `InstrumentNumberField` is a nice touch for OCR-assisted mileage entry.

5. **Robust OCR flow.** The odometer capture pipeline (camera -> crop to viewfinder -> OCR -> confirmation with editable value + unit toggle) is thorough. Low-confidence warnings are clear. The `OdometerCaptureView` has a proper viewfinder guide with crop-to-region.

6. **Attachment handling is complete.** Photo, PDF, and receipt scanning are all supported with appropriate thumbnails, OCR text extraction, and QuickLook preview. The receipt text view has clipboard copy with visual feedback.

7. **Centralized sheet management.** All sheets are declared in ContentView with `appState` bindings, preventing duplicate presentation and ensuring consistent dismiss behavior.

8. **Swipe navigation between tabs.** The `simultaneousGesture(DragGesture)` on the tab content area provides horizontal swipe navigation, with a FeatureHintView to educate users about it.

---

## Issues Found

### Critical

#### C1: [+] Button "Log" vs "Schedule" Distinction is Non-Obvious
**File:** `BrutalistTabBar.swift:45-78`
**Problem:** When the [+] button expands, it shows `[SCHEDULE]` and `[LOG]` in that order. New users may not understand the difference -- "log" means recording a past service, "schedule" means setting a future reminder. There is no subtitle, icon, or description. The labels are terse ALL CAPS single words.
**Impact:** Users may choose the wrong action (scheduling when they meant to log, or vice versa), leading to confusion and data entry errors. This is the primary creation action in the entire app.
**Recommendation:** Add a small description below each label or use icons to differentiate. For example: `[LOG] - Record completed service` with a checkmark icon vs. `[SCHEDULE] - Set a reminder` with a calendar icon. Alternatively, present the choice inside the AddServiceView sheet instead of at the tab bar level.

#### C2: Toast Dismiss Button Touch Target Too Small
**File:** `ToastView.swift:44-51`
**Problem:** The toast dismiss X button uses `.buttonStyle(.instrument)` which only provides opacity feedback but no minimum touch target expansion. The icon is 12pt with no padding. The `.onTapGesture` on the entire toast also conflicts -- tapping anywhere dismisses, but the X button is visually implied as the dismiss target.
**Impact:** Users may struggle to hit the small X, especially while the toast is animating in. The dual dismiss mechanism (tap anywhere + X button) is redundant -- if the whole toast is tappable to dismiss, the X button is misleading since it implies that is the only dismiss affordance.
**Recommendation:** Either (a) remove the X button entirely and rely on tap-anywhere + swipe-to-dismiss (adding a visual hint like a swipe indicator), or (b) keep the X button but add `.minimumTouchTarget()` and remove the full-toast `.onTapGesture` so the behavior is unambiguous.

#### C3: Swipe-Down Toast Dismiss Direction is Wrong
**File:** `ToastView.swift:60-67`
**Problem:** The toast appears at the bottom of the screen (positioned at `72 + Spacing.lg` from bottom in ContentView:136). The swipe gesture dismisses on `translation.height > 10` -- meaning swipe DOWN. But the toast is already near the bottom. Swiping down on a bottom-positioned element should push it off-screen downward, which is correct directionally, but the threshold of 10pt is extremely low and will trigger on nearly any accidental vertical scroll.
**Impact:** Users will accidentally dismiss toasts while trying to interact with the action button ("UNDO" on delete, for example). Losing the undo toast after deleting a vehicle is a critical data-loss scenario.
**Recommendation:** Increase the minimum swipe distance to at least 30-40pt and add a velocity check. Consider also adding a longer display duration for toasts with action buttons.

### Major

#### M1: VehicleHeader Mileage Button Has No Minimum Touch Target
**File:** `VehicleHeader.swift:40-52`
**Problem:** The mileage text button in VehicleHeader relies solely on the text content size for its tap area. For a vehicle with low mileage (e.g., "0 MI"), the tap target could be very small. No `.minimumTouchTarget()` modifier is applied.
**Impact:** Mileage update is a frequent action. Users with lower mileage values or smaller text will have difficulty tapping.
**Recommendation:** Add `.minimumTouchTarget()` or explicit `.frame(minHeight: 44)` and `.contentShape(Rectangle())` to the mileage button.

#### M2: Sync Error Indicator Touch Target is 32x32pt
**File:** `VehicleHeader.swift:83-95`
**Problem:** The sync error button has `.frame(width: 32, height: 32)`. This is below the 44pt Apple HIG minimum.
**Impact:** When a sync error occurs, users need to tap this small icon to navigate to settings. The error state is already stressful -- making the recovery action hard to tap compounds frustration.
**Recommendation:** Change to `.frame(width: 44, height: 44)` or use `.minimumTouchTarget()`.

#### M3: Attachment Remove Button Offset Creates Partial Off-Screen Target
**File:** `AttachmentPicker.swift:297-308` (AttachmentPreviewItem)
**Problem:** The remove (X) button on attachment thumbnails has `.offset(x: 4, y: -4)`, making it extend beyond the parent 60x60 frame. The button itself is 10pt icon + 4pt padding = ~18pt total. This is far below the 44pt minimum.
**Impact:** Users will struggle to delete specific attachments, especially on smaller devices. The tiny target overlapping the edge of the thumbnail is particularly hard to hit.
**Recommendation:** Enlarge the remove button touch target with `.minimumTouchTarget()` and ensure it does not clip outside the scrollable area.

#### M4: CategoryChip in ServicePresetPickerSheet Uses Capsule Shape
**File:** `ServiceTypePicker.swift:207-223`
**Problem:** `CategoryChip` uses `.clipShape(Capsule())`, which is a rounded shape. The app's design system mandates zero corner radius everywhere. This breaks the brutalist aesthetic.
**Impact:** Visual inconsistency. Every other element in the app uses sharp rectangles.
**Recommendation:** Change `.clipShape(Capsule())` to `.clipShape(Rectangle())`.

#### M5: ServicePresetPickerSheet Uses System List Styling
**File:** `ServiceTypePicker.swift:120-185`
**Problem:** The `ServicePresetPickerSheet` uses a standard `List` with default iOS styling inside a `NavigationStack`. The list background, separators, and row insets use iOS defaults rather than the brutalist design system. The category filter is inside a `ScrollView` embedded in a list row.
**Impact:** This sheet looks visually different from every other screen in the app. The system list styling (rounded rows, white background separators) clashes with the dark, sharp-cornered instrument aesthetic.
**Recommendation:** Replace with a `ScrollView` + `VStack` using the app's own component system, or at minimum apply `.listStyle(.plain)` and override backgrounds with Theme colors.

#### M6: MileageInputField Uses Non-Brutalist Font
**File:** `MileageInputField.swift:28-29, 65-67`
**Problem:** `MileageInputField` uses `.font(.bodyText)` for both the input and suffix. While `.bodyText` maps to `.brutalistBody`, the component lacks the instrument panel container styling (no border, no background, no label) that other input components like `InstrumentNumberField` provide.
**Impact:** When MileageInputField is used standalone (without parent styling), it looks bare compared to other inputs. It also duplicates some functionality with `InstrumentNumberField` which already handles mileage-like inputs.
**Recommendation:** Consider whether MileageInputField is needed as a separate component or if it should be consolidated into InstrumentNumberField with a formatting option.

#### M7: No Keyboard Dismiss Mechanism on Forms
**File:** `InstrumentTextField.swift`, `InstrumentNumberField`, `MileageInputField.swift`
**Problem:** None of the input fields provide a "Done" button toolbar for the number pad keyboard, and there is no `.scrollDismissesKeyboard(.interactively)` or tap-to-dismiss gesture documented in the input components. The number pad specifically has no return key.
**Impact:** Users on the number pad (mileage, year, cost entries) have no obvious way to dismiss the keyboard without tapping elsewhere. This is especially painful in forms where tapping elsewhere might trigger unintended actions.
**Recommendation:** Add a `.toolbar { ToolbarItemGroup(placement: .keyboard) { ... } }` with a "Done" button to all number-pad fields, or implement `.scrollDismissesKeyboard(.interactively)` on the parent form ScrollViews.

#### M8: FeatureHintView Insertion Animation Includes Scale
**File:** `FeatureHintView.swift:63-66`
**Problem:** The insertion transition uses `.scale(scale: 0.98)` combined with `.opacity`. Per the project's AESTHETIC.md, accordion/collapsible content should use "fade-only `.transition(.opacity)`, never slide `.move(edge:)`." While scale is not explicitly slide, it violates the spirit of the fade-only rule.
**Impact:** Minor animation inconsistency with the design system's documented principles.
**Recommendation:** Remove the `.scale(scale: 0.98)` portion and use plain `.opacity` for both insertion and removal.

### Minor

#### m1: VehicleSelector Component Appears Unused
**File:** `VehicleSelector.swift`
**Problem:** `VehicleSelector` is a standalone component that shows a vehicle name with a chevron-down. However, ContentView uses `VehicleHeader` for the vehicle display, and the picker is a sheet. VehicleSelector uses `.font(.title)` (system title font) instead of `.font(.brutalistHeading)`, suggesting it may be from an older design iteration.
**Impact:** Dead code increases maintenance burden and creates confusion about which component to use.
**Recommendation:** Verify if VehicleSelector is used anywhere. If not, remove it.

#### m2: FloatingActionButton Component Appears Unused
**File:** `FloatingActionButton.swift`
**Problem:** `FloatingActionButton` is a separate component, but the tab bar now has the [+] button built into `BrutalistTabBar`. The FAB uses the accent color background while the tab bar [+] uses `Theme.textPrimary` (inverted design), suggesting they are from different design generations.
**Impact:** Unused component. If it is used somewhere not in the audited files, the design is inconsistent with the tab bar's [+] button.
**Recommendation:** Verify usage. If unused, remove to reduce code surface.

#### m3: OdometerCaptureView Uses Hardcoded Colors
**File:** `OdometerCaptureView.swift:51-52`
**Problem:** The view controller uses hardcoded `ceruleanPrimary` and `accentOffWhite` UIColors instead of converting Theme colors to UIColor. Comments say "matches cerulean design system" but the app no longer uses the "cerulean" name.
**Impact:** If Theme colors change (e.g., via ThemeManager), this UIKit view will not update. The color names reference an outdated design system name.
**Recommendation:** Convert Theme colors to UIColor for use in the view controller, or at minimum update the hardcoded values and comments to match the current design system.

#### m4: InstrumentNumberField Camera Button Has Double Border
**File:** `InstrumentTextField.swift:132-147, 149-156`
**Problem:** The camera button has its own `.overlay(Rectangle().strokeBorder(...))` AND the parent HStack also has a `.overlay(Rectangle().strokeBorder(...))`. This creates a double border where the camera button meets the input field.
**Impact:** Visual artifact -- a 4px thick border at the junction point.
**Recommendation:** Remove the individual camera button border and rely on the parent container border only, or add a vertical divider line instead.

#### m5: MarbetePicker Year Range is Limited to +2 Years
**File:** `MarbetePicker.swift:80-81`
**Problem:** The year picker only offers `currentYear...(currentYear + 2)`. If a user renews their marbete early or has a multi-year registration, they cannot select years further out.
**Impact:** Minor limitation for edge cases. Most users will be fine with a 3-year range.
**Recommendation:** Consider extending to +3 or +4 years, or allowing manual year entry.

#### m6: ErrorMessageRow Does Not Support VoiceOver Dismiss Action
**File:** `ErrorMessageRow.swift:27-34`
**Problem:** The dismiss button uses `.minimumTouchTarget()` (good), but the error row itself does not have `.accessibilityAddTraits(.isButton)` or a custom accessibility action for dismiss. Screen reader users may not discover the dismiss affordance.
**Recommendation:** Add `.accessibilityAction(named: "Dismiss") { onDismiss() }` to the container.

#### m7: ListDivider Default Leading Padding is Hardcoded
**File:** `ListDivider.swift:11`
**Problem:** The default `leadingPadding` of 56pt assumes a specific icon + spacing layout. If list items change their icon size or spacing, the divider alignment breaks.
**Impact:** Fragile coupling between divider and list item layout.
**Recommendation:** Consider deriving the padding from the parent context or at minimum documenting the assumed layout.

#### m8: Toast Swipe Gesture Conflicts with ScrollView
**File:** `ToastView.swift:60-67`
**Problem:** The `DragGesture` on the toast may conflict with underlying ScrollView gestures when the toast overlaps scrollable content.
**Recommendation:** Use `.highPriorityGesture()` instead of `.gesture()` for the toast swipe dismiss.

#### m9: ShareSheet URL Identifiable Extension is @retroactive
**File:** `ShareSheet.swift:29-31`
**Problem:** `extension URL: @retroactive Identifiable` is a global conformance that could conflict with other libraries or future SwiftUI versions that add their own `Identifiable` conformance to URL.
**Impact:** Potential compile-time conflict if another module adds the same conformance.
**Recommendation:** Use a wrapper struct (e.g., `IdentifiableURL`) instead of retroactive conformance.

#### m10: ExportOptionsSheet "Generate PDF" Button Label Not Brutalist
**File:** `ExportOptionsSheet.swift:88`
**Problem:** The button label "Generate PDF" uses title case, while the brutalist style uses ALL CAPS everywhere else. The `.buttonStyle(.primary)` should handle uppercasing, but the label itself is mixed case.
**Impact:** The PrimaryButtonStyle applies `.textCase(.uppercase)`, so this is handled at runtime. However, for code consistency, the string should match the visual output.
**Recommendation:** Minor -- no visual impact since the button style uppercases it.

#### m11: InstrumentTextEditor Placeholder Misaligned
**File:** `InstrumentTextField.swift:243-249`
**Problem:** The placeholder text uses `.padding(.horizontal, Spacing.listItem)` and `.padding(.vertical, Spacing.md)` while the TextEditor uses `.padding(Spacing.listItem)`. Different padding values mean the placeholder and actual text do not start at the same position.
**Impact:** When users start typing, the text appears to shift position as the placeholder disappears.
**Recommendation:** Align the placeholder padding with the TextEditor padding.

#### m12: TappableCardModifier Provides No Visual Feedback
**File:** `TappableCardModifier.swift:12-22`
**Problem:** The modifier only adds a tap gesture -- there is no visual press feedback (opacity change, scale, highlight). Users get no confirmation that they tapped a card.
**Impact:** Cards feel unresponsive. Users may tap multiple times because they are unsure if their first tap registered.
**Recommendation:** Add a pressed state with opacity or background color change. Consider using a Button with a custom ButtonStyle instead of onTapGesture for built-in press state handling.

#### m13: StatusDot is 8x8pt with No Extended Touch Target
**File:** `StatusDot.swift:15-18`
**Problem:** StatusDot is 8x8pt. While it is typically not interactive by itself (used as a visual indicator within larger tappable rows), it is important to ensure the parent container provides an adequate touch target.
**Impact:** No direct impact since StatusDot is not a button, but worth noting for any future interactive use.

#### m14: ReceiptScannerView Error Handler Silently Cancels
**File:** `ReceiptScannerView.swift:60-67`
**Problem:** When `documentCameraViewController(_:didFailWithError:)` is called, it just calls `onCancel()` with no user-facing error message. The user sees the scanner dismiss with no explanation.
**Impact:** If the camera fails (permissions issue, hardware error), the user gets no feedback about what went wrong or how to fix it.
**Recommendation:** Surface the error to the caller so it can show an appropriate error message.

---

## Detailed Findings

### Tab Bar (BrutalistTabBar)

The custom tab bar is well-executed. Key observations:

- **Glass effect integration:** Uses `.glassEffect(.clear.tint(...), in: Rectangle())` for iOS 26 Liquid Glass aesthetic while maintaining sharp corners.
- **Adaptive layout:** When [+] is expanded, tab labels collapse to icons-only to save space. The animation uses fade-only transitions (`.transition(.opacity)`) per the design system rules.
- **Active state:** The selected tab uses `Theme.accent` color and a bottom `Rectangle` underline of `Theme.borderWidth` height. This is subtle but effective.
- **Tab order:** Services | Home | Costs -- Home is centered, which is good for the primary landing tab.
- **Haptics:** Tab changes trigger `HapticService.shared.tabChanged()` (soft impact).

**Gap:** When the [+] menu is expanded and the user taps a tab, the menu collapses first but the tab also switches. This double-action (collapse + navigate) is handled correctly in code (lines 115-121) -- the menu collapses and the tab switches in one gesture. Good.

### Swipe Navigation

- **Minimum distance:** 50pt horizontal with `abs(horizontal) > abs(vertical)` guard. This is reasonable.
- **Conflict with cards:** The `.simultaneousGesture` modifier allows both swipe and card taps to coexist. The `TappableCardModifier` uses `.onTapGesture` which has lower priority, preventing conflicts.
- **No cross-fade:** Tab content switches without animation on the content itself (only the tab bar indicator animates via `.easeOut(duration: Theme.animationMedium)`). A subtle cross-fade on the content would improve perceived fluidity.

### Vehicle Header

- **Information density:** Shows vehicle name (tappable), mileage (tappable), make/model/year, and a `[SELECT]` label. This is dense but well-organized in a two-line layout.
- **Sync error indicator:** Only appears on error, which is good -- no clutter in the normal state.
- **Settings gear:** 44x44pt touch target -- correctly sized.
- **Bottom border:** Uses `Theme.gridLine` with `Theme.borderWidth` for structural separation.

### Input Components

The input family (`InstrumentTextField`, `InstrumentNumberField`, `InstrumentDatePicker`, `InstrumentToggle`, `InstrumentTextEditor`) is comprehensive and consistent:

- All use the same label style: uppercase, `.instrumentLabel`, tertiary color, 1.5 letter spacing.
- All have matching 6pt label-to-field spacing.
- Focus states are handled uniformly with amber border + focus glow.
- Required fields show a red asterisk.

**Duplicate formatting logic:** `ServiceTypePicker` (lines 98-108) and `ServicePresetPickerSheet` (lines 187-197) both have identical `formatInterval(_:)` methods. This should be extracted to a shared method on `PresetData`.

### Camera/OCR Pipeline

The OCR flow is: Camera (OdometerCameraSheet) -> Capture (OdometerCaptureView) -> OCR Processing (handled externally) -> Confirmation (OCRConfirmationView).

- **Viewfinder guide:** 80% screen width, configurable aspect ratio, semi-transparent overlay. The guide text "ALIGN ODOMETER HERE" is positioned below the viewfinder.
- **Crop to viewfinder:** The cropping logic accounts for aspect-fill behavior and normalizes image orientation. This is robust.
- **Confirmation view:** The extracted value is editable inline with a number pad. Unit toggle (MI/KM) is available. Low-confidence gets a prominent warning.
- **Receipt scanning:** Uses VisionKit's `VNDocumentCameraViewController` which provides its own UI -- consistent with system conventions.

### Attachment System

- **Three input methods:** Photo picker, PDF document picker, receipt scanner with OCR.
- **Preview grid:** 60x60 thumbnails in a horizontal scroll. PDF gets a placeholder icon.
- **Delete UX:** The X button on thumbnails is small (see M3 above).
- **View attachments:** Tapping opens QuickLook for images/PDFs, or a ReceiptTextView for OCR-extracted text.

### Feedback Components

- **Toast positioning:** Bottom of screen, above tab bar (`72 + Spacing.lg` padding). Three styles: success, info, error with appropriate colors.
- **FeatureHintView:** One-time hints with "GOT IT" dismiss. Tracks seen state via `FeatureDiscovery`. Good for onboarding without being intrusive.

### Design System Consistency

| Token Area | Consistency | Notes |
|---|---|---|
| Colors | Excellent | All via Theme.* computed properties, supporting ThemeManager |
| Typography | Good | Brutalist font scale used almost everywhere. Legacy aliases exist but map correctly. ServiceTypePicker uses `.font(.subheadline)` and `.font(.caption)` directly in a few places |
| Spacing | Excellent | Spacing.* tokens used consistently |
| Borders | Excellent | 2px strokeBorder with Theme.gridLine everywhere |
| Corner Radius | Good | Zero everywhere except CategoryChip (see M4) |
| Animation | Good | Theme.animationFast/Medium used. FeatureHintView uses scale (see M8) |

---

## Code Quality Issues

### CQ1: Duplicate `formatInterval` Method
**Files:** `ServiceTypePicker.swift:98-108` and `ServiceTypePicker.swift:187-197`
**Issue:** Identical method defined in both `ServiceTypePicker` and `ServicePresetPickerSheet`.
**Fix:** Extract to a method on `PresetData` or a shared extension.

### CQ2: Legacy Typography Aliases Proliferation
**File:** `Typography.swift:49-67`
**Issue:** There are 17 legacy font aliases (`instrumentLarge`, `instrumentMedium`, `instrumentLabel`, `instrumentSection`, `instrumentBody`, `instrumentMono`, `displayLarge`, `headlineLarge`, `headline`, `title`, `bodyText`, `bodySecondary`, `caption`, `captionSmall`, `monoLarge`, `monoBody`) plus 10 legacy style modifiers. This doubles the API surface and creates confusion about which naming convention to use.
**Fix:** Audit usage of legacy names across the codebase. If any are unused, remove them. If in active use, migrate and remove.

### CQ3: Potential Unused Components
**Files:** `VehicleSelector.swift`, `FloatingActionButton.swift`
**Issue:** These appear to be from earlier design iterations. VehicleSelector uses system `.font(.title)` instead of brutalist typography. FloatingActionButton has a different color scheme than the tab bar [+].
**Fix:** Search for usage across the project. Remove if unused.

### CQ4: ReceiptScannerView Double Dismiss
**File:** `ReceiptScannerView.swift:48-50, 53-56, 60-64`
**Issue:** All three delegate methods call `controller.dismiss(animated:)` and then invoke the callback in the completion handler. However, since this is presented as a SwiftUI `.sheet`, the SwiftUI presentation system should handle dismissal. The manual UIKit dismiss may conflict with SwiftUI's state management.
**Fix:** Remove the `controller.dismiss(animated:)` calls and let SwiftUI handle dismiss via the sheet binding, or verify there is no double-dismiss animation.

### CQ5: OdometerCaptureView UIKit Lifecycle Concerns
**File:** `OdometerCaptureView.swift:77-87`
**Issue:** `captureSession.startRunning()` is called in `viewWillAppear` on a background thread, but `captureSession.stopRunning()` is called in `viewWillDisappear` on the main thread. Mixing threads for session lifecycle can cause crashes in edge cases.
**Fix:** Call both start and stop on the same serial queue.

### CQ6: InstrumentNumberField External Value Sync
**File:** `InstrumentTextField.swift:104-121`
**Issue:** The `InstrumentNumberField` has bidirectional sync between `textValue` (String state) and `value` (Int? binding) via two `onChange` handlers. This creates a potential feedback loop where changing `value` triggers `onChange(of: value)` which updates `textValue`, which triggers `onChange(of: textValue)` which updates `value`. The guard `if newText != textValue` prevents infinite recursion, but the pattern is fragile.
**Fix:** Consider using a single source of truth with a computed property or a Formatter-based approach.

---

## Recommendations

### High Priority (address before next release)

1. **Improve [+] menu discoverability** (C1): Add icons and brief descriptions to the "Log" and "Schedule" options to clarify intent.

2. **Fix toast interaction issues** (C2, C3): Increase swipe-dismiss threshold, add velocity check, and resolve the dual-dismiss mechanism (tap-anywhere vs. X button).

3. **Fix undersized touch targets** (M1, M2, M3): Apply `.minimumTouchTarget()` to VehicleHeader mileage, sync error icon, and attachment remove buttons.

4. **Add keyboard Done button** (M7): Implement a toolbar Done button for number pad fields across all form views.

### Medium Priority (address in next sprint)

5. **Fix CategoryChip shape** (M4): Change from `Capsule()` to `Rectangle()` to match brutalist design system.

6. **Restyle ServicePresetPickerSheet** (M5): Replace system List styling with the app's own component system.

7. **Add TappableCardModifier feedback** (m12): Provide visual press feedback (opacity or color change) so card taps feel responsive.

8. **Fix FeatureHintView animation** (M8): Remove scale from transition, use fade-only per AESTHETIC.md.

### Low Priority (maintenance/cleanup)

9. **Remove dead components** (m1, m2): Verify and remove VehicleSelector and FloatingActionButton if unused.

10. **Extract duplicate code** (CQ1): Consolidate `formatInterval` into PresetData.

11. **Clean up legacy typography** (CQ2): Audit and remove unused legacy font aliases and style modifiers.

12. **Fix OdometerCaptureView hardcoded colors** (m3): Use Theme-derived UIColors.

13. **Fix InstrumentTextEditor placeholder alignment** (m11): Match padding values between placeholder and editor.

14. **Surface ReceiptScanner errors** (m14): Pass errors to the caller instead of silently canceling.
