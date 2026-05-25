# Localization

Shared EN/ES strings for terms used in **both** Checkpoint and Biombo. Per-app strings stay in each app's own `.xcstrings` catalog — only genuinely shared vocabulary belongs here.

## What's shared

- Units (liters, gallons, miles, kilometers)
- Fuel grades (regular, premium, diesel)
- Common actions (cancel, save, delete, done)

## What's NOT shared

Anything app-specific: onboarding copy, error messages referencing Checkpoint or Biombo by name, screen-specific UI, etc. Put those in the per-app catalog.

## Adding a shared string

1. Add the key to `Sources/Localization/Resources/Shared.xcstrings` with both `en` and `es` translations (`"state": "translated"`).
2. Add a typed accessor in `L10n.swift` under the relevant `L10n.Shared.*` enum.
3. Consumers call `L10n.Shared.Units.liters` etc.

## Usage from an app

```swift
import Localization

Text(L10n.Shared.Units.liters)   // "Liters" / "Litros"
```

`bundle: .module` in `NSLocalizedString` ensures lookup reads from the package's own `.xcstrings` regardless of which app loads it.

## Build

```bash
swift build
```

Tests need Xcode (`XCTest` not in CommandLineTools).
