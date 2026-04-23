# DesignKit

Shared design system for 418 Studio iOS apps. Codifies the brutalist philosophy in `docs/AESTHETIC.md` into tokens, modifiers, and a theme-provider protocol.

## Architecture

- **`ThemeProviding` protocol** (`ThemeProviding.swift`) — the contract each app conforms to. Exposes all color tokens, font design, and color scheme.
- **`ThemeEnvironment`** (`ThemeEnvironment.swift`) — SwiftUI `EnvironmentKey` so views read `@Environment(\.theme)` instead of a singleton.
- **`Providers/AestheticBrutalistTheme`** — Biombo's default provider. Cerulean `#0033BE` + Off-White `#F5F0DC`, `.monospaced` font design.
- **`Spacing`** — 4pt base scale. Values mirror Checkpoint's current `Spacing` enum exactly so the eventual extraction is a source-level no-op.
- **`Color(hex:)`** extension — utility ported from Checkpoint.

## Usage

```swift
import DesignKit

@main
struct BiomboApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .designKitTheme(AestheticBrutalistTheme.shared)
        }
    }
}

struct SomeView: View {
    @Environment(\.theme) private var theme
    var body: some View {
        Text("Hello").foregroundStyle(theme?.textPrimary ?? .primary)
    }
}
```

## What's NOT here yet

Phase 0 ships the skeleton only. Still to migrate from `checkpoint-app/checkpoint/DesignSystem/`:
- `Theme.swift` view modifiers (`.cardStyle`, `.brutalistBorder`, `.glassCardStyle`, `.screenPadding`)
- `Typography.swift` font extensions
- `InstrumentSection`, `BrutalistChartStyle`, `TappableCardModifier`, `TouchTarget`
- Components: `InstrumentSectionHeader`, `BrutalistDataRow`, `AtmosphericBackground`
- `Themes.json` resource
- `CheckpointDefaultTheme` provider (current amber/dark palette)

That extraction touches ~1,750 call sites in Checkpoint. It's deferred until Xcode is available to run `xcodebuild test -scheme checkpoint` and confirm no regressions.

## Adding a new color token

1. Add the property to `ThemeProviding`.
2. Add a default implementation via protocol extension (optional, for backward compat).
3. Implement it on all existing providers (`AestheticBrutalistTheme`, later `CheckpointDefaultTheme`).
4. Run `swift build` from `packages/DesignKit/` before committing.
