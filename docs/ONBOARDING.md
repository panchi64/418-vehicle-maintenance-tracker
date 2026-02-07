# Onboarding — Lightweight Welcome (Post-V1.0)

Design spec for first-launch onboarding experience. Deferred from V1.0 — this document captures the full design for future implementation.

## First-Launch Detection

- `UserDefaults` key: `hasCompletedOnboarding` (Bool)
- Check on app launch in `ContentView.swift`
- Default: `false` (show onboarding on first launch)

## Welcome Overlay

### Container
- `.glassCardStyle(.strong)` background
- Full-screen overlay with semi-transparent backdrop
- Dismissable via X button in top-right corner

### Content

```
+----------------------------------------+
|                                    [X] |
|                                        |
|            CHECKPOINT                  |
|     (.brutalistTitle, uppercase)       |
|                                        |
|  01  TRACK MAINTENANCE                |
|  02  PREDICT WHAT'S NEXT              |
|  03  NEVER MISS A SERVICE             |
|                                        |
|  [  ADD YOUR FIRST VEHICLE  ]         |
|  (.buttonStyle(.primary))             |
|                                        |
+----------------------------------------+
```

### Typography & Styling

- **Title:** `.brutalistTitle`, uppercase, `Theme.textPrimary`
- **Value props:** `BrutalistDataRow` style — number in `Theme.accent`, description in `Theme.textPrimary`
- **CTA button:** `.buttonStyle(.primary)` — amber filled, uppercase label
- **Dismiss X:** `.system(size: 14, weight: .bold)`, `Theme.textTertiary`, 44pt touch target

### Behavior

- **CTA tap:** Opens `AddVehicleView` as sheet, sets `hasCompletedOnboarding = true`
- **X tap:** Dismisses overlay, sets `hasCompletedOnboarding = true`
- **No auto-dismiss** — user must explicitly interact

## Extended Feature Discovery Hints

After onboarding, show contextual hints using `FeatureDiscovery`:

| Hint Key | Trigger | Message | Location |
|----------|---------|---------|----------|
| `.dashboardGuide` | First visit to Home tab | "Tap the vehicle name to switch between vehicles" | Below `VehicleHeader` |
| `.costTracking` | First service completion | "Log costs when completing services to track spending" | `MarkServiceDoneSheet` |

## Component Location

- **File:** `Views/Components/Navigation/WelcomeView.swift`
- **Integration:** `.overlay()` in `ContentView.swift` (conditional on `!hasCompletedOnboarding`)

## Design System Tokens

All new UI must use:
- **Colors:** `Theme.accent`, `Theme.textPrimary`, `Theme.textTertiary`, `Theme.surfaceInstrument`
- **Typography:** `.brutalistTitle`, `.brutalistBody`, `.brutalistLabel`
- **Spacing:** `Spacing.lg` between sections, `Spacing.md` between rows
- **Borders:** Zero corner radius, `Theme.gridLine` stroke if needed
- **Animation:** `.revealAnimation()` for entry — no springs or bounces
