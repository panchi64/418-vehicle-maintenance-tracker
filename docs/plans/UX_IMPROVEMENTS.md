# UX Improvements Plan: Onboarding, Vehicle Registration, Contextual Insights, and Settings

## Context

The app is functionally complete for v1.0 but the UX has gaps that impact first-impression and ongoing engagement:
1. **No onboarding** — New users land on seeded sample data with no explanation of the app's value
2. **Vehicle registration feels bare** — VIN field has no value proposition, lookup button is hidden until valid 17-char VIN
3. **Service/mileage views lack contextual meaning** — Data is shown but doesn't tell a story
4. **Settings are unorganized** — Sections were added incrementally with no logical grouping

---

## Part 1: Guided Onboarding Flow

### New Files
- `Views/Onboarding/OnboardingView.swift` — Coordinator with page-based flow
- `Views/Onboarding/OnboardingPageView.swift` — Reusable page template (icon, title, description)
- `Utilities/OnboardingState.swift` — `@AppStorage`-backed `hasCompletedOnboarding` flag

### Flow (3 screens + CTA)

**Screen 1: Welcome**
- Large app icon / vehicle silhouette
- Title: "Your vehicle. Your data."
- Subtitle: "Track maintenance, costs, and mileage — all in one place."

**Screen 2: Smart Features**
- Icon: `barcode.viewfinder`
- Title: "Scan your VIN"
- Subtitle: "Auto-fill vehicle details and get recall alerts from NHTSA."

**Screen 3: Stay Ahead**
- Icon: `gauge.medium`
- Title: "Keep your odometer current"
- Subtitle: "Regular mileage updates power smart reminders so you never miss a service."

**CTA: "Add Your First Vehicle" → dismisses onboarding, opens AddVehicleFlowView**

### Integration
- `ContentView.swift`: Check `OnboardingState.hasCompletedOnboarding`. If false, present `OnboardingView` as fullScreenCover. On completion, set flag and open AddVehicleFlowView.
- Remove `seedSampleDataIfNeeded()` from production — move to debug/preview-only context.

### Design
- Reuse: `AtmosphericBackground`, `brutalistTitle`/`brutalistBody` typography, `Theme.accent` for CTA
- Page indicators: reuse `StepIndicator` square dots pattern from `VehicleBasicsStep.swift`
- Horizontal paging via `TabView(.page)` with custom indicators
- Final button: `.buttonStyle(.primary)`

### Key Files Modified
- `ContentView.swift` — fullScreenCover for onboarding, guard on `hasCompletedOnboarding`

---

## Part 2: Vehicle Registration VIN Improvements

### Changes to `VehicleBasicsStep.swift`

**A. VIN Value Proposition Banner**
Add a persistent inline callout above the VIN input:
> "Enter your VIN to auto-fill make, model, and year — and check for open recalls."

Style with `barcode.viewfinder` icon, `Theme.accent` accent left border, `brutalistSecondary` text.

**B. Always-Visible VIN Progress**
Replace hidden `VINLookupButton` behavior:
- Show VIN character count: `"12 / 17 CHARACTERS"` below input (`brutalistLabel`, `textTertiary`)
- When valid: transition to `"VIN VALID — LOOK UP DETAILS"` in `Theme.accent`
- Auto-trigger lookup or show prominent button

**C. Auto-Fill Feedback**
When VIN lookup succeeds:
- Inline success message: checkmark + "DETAILS FILLED FROM VIN"
- Auto-filled fields (make, model, year) get subtle accent flash

### Key Files Modified
- `Views/Vehicle/AddVehicleFlow/VehicleBasicsStep.swift` — VIN section overhaul
- `Views/Vehicle/AddVehicleFlow/VehicleFormState.swift` — add `vinLookupSucceeded` flag

---

## Part 3: Contextual Insights

### 3A: Service Detail Insights

**File: `Views/Service/ServiceDetailView.swift`**

New "Insights" section between status card and schedule:
- **Time since last service**: "Last performed 5 months ago"
- **Miles driven since**: "3,200 mi driven since last service"
- **Average cost**: "Average cost: $45" (from logs mean)
- **Times serviced**: "Serviced 4 times"

Use `InstrumentSectionHeader(title: "Insights")` + `BrutalistDataRow`-style rows. Only show where data exists.

### 3B: Service Row Context

**File: `Views/Components/Lists/ServiceRow.swift`**

Add subtle secondary line: "Last: 5 mo ago" below progress bar/miles line (`brutalistLabel`, `textTertiary`).

### 3C: Mileage Update Motivation

**File: `Views/Components/Cards/QuickMileageUpdateCard.swift`**

Add subtitle connecting mileage to services:
- "Keeps N service reminders accurate" (N = services with `dueMileage != nil`)
- When overdue/dueSoon services exist: "N services approaching — update for accurate tracking"

Requires passing mileage-tracked service count into the card.

**File: `MileageUpdateSheet`** (inside same file)

Add brief explainer at sheet top:
- "Your mileage powers service reminders. More updates = more accurate predictions."
- Only show when `daysSinceMileageUpdate > 7`

### 3D: NextUpCard — Last Service Context

**File: `Views/Components/Cards/NextUpCard.swift`**

Add "LAST SERVICE" data row when `service.lastPerformed` exists:
- Format: "LAST SERVICE" label → "5 months ago" value

---

## Part 4: Settings Reorganization

### Current Order (problematic)
1. DATA & SYNC
2. DISPLAY (distance unit, mileage estimation)
3. ALERTS (due soon thresholds, app icon auto-change)
4. SEASONAL REMINDERS (toggle, climate zone)
5. SERVICE BUNDLING (toggle, mileage/days windows)
6. WIDGETS (default vehicle, mileage display)
7. ANALYTICS

### Problems
- App icon auto-change is under "Alerts" but it's a display setting
- Seasonal reminders and service bundling are separate but both "smart feature" settings
- Data & Sync is first but rarely accessed after initial setup
- No logical flow from most-relevant to least-relevant

### New Order

**1. DISPLAY** *(most commonly adjusted)*
- Distance unit
- Mileage estimation toggle
- App icon auto-change *(moved from Alerts)*

**2. REMINDERS** *(renamed from "Alerts" — groups all notification/threshold settings)*
- Due soon mileage threshold
- Due soon days threshold
- Seasonal alerts toggle
- Climate zone picker

**3. SMART FEATURES** *(merged seasonal + bundling into one section)*
- Service bundling toggle
- Bundling mileage window
- Bundling days window

**4. WIDGETS**
- Default vehicle
- Mileage display mode

**5. DATA & SYNC** *(moved down — rarely changed after setup)*
- iCloud sync status/controls

**6. PRIVACY** *(renamed from "Analytics" — clearer intent)*
- Analytics opt-out

### Key File Modified
- `Views/Settings/SettingsView.swift` — reorder sections, rename headers, move AppIconToggle

---

## Verification

1. **Build**: `xcodebuild build -scheme checkpoint -destination 'platform=iOS Simulator,name=iPhone 17'`
2. **Unit Tests**: `xcodebuild test -scheme checkpoint -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:checkpointTests`
3. **Manual QA**:
   - Fresh install → onboarding appears → complete → AddVehicleFlow opens
   - Enter partial VIN → see character count → enter full VIN → see lookup prompt + auto-fill feedback
   - Service detail → insights section with time/miles/cost context
   - Home tab → mileage card shows service count motivation
   - NextUpCard → "last service" context row
   - Settings → sections logically grouped, app icon under Display, reminders consolidated

## Implementation Order

1. ~~Settings reorganization~~ ✅
2. Onboarding (new files, minimal risk)
3. VIN registration improvements (isolated to AddVehicleFlow)
4. Contextual insights (incremental additions to existing views)
