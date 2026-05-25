# packages/

Shared SwiftPM packages consumed by every iOS app in the monorepo.

## What's here

- **`DesignKit/`** — design system (tokens, modifiers, `ThemeProviding` protocol, built-in theme providers). Consumed by Checkpoint and Biombo; each app injects its own `ThemeProviding` conformer.
- **`Localization/`** — genuinely shared strings (units, fuel grades, common verbs) as a `.xcstrings` catalog. App-specific strings stay in each app's own catalog.

## When to add a new package

Only when two+ apps need the same code. Single-app code belongs in the app's own target, not here.

## Build

```bash
cd packages/DesignKit && swift build
cd packages/Localization && swift build
```

Both packages declare `.iOS(.v17)`, `.watchOS(.v10)`, `.macOS(.v14)`. macOS is included so `swift build` works from CLI without Xcode.

Tests (`swift test`) require Xcode for `XCTest`. CLI-only environments cannot run them.

## Phase 0 state

Both packages are scaffolds. The real code migration from Checkpoint's `DesignSystem/` and `.strings` files happens once Xcode is available to verify the 1,750+ call-site refactor doesn't regress Checkpoint.
