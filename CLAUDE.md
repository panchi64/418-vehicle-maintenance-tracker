# CLAUDE.md

418 Studio monorepo. Multiple apps share infrastructure via local SwiftPM packages.

## Directory map

**Apps:**
- `apps/checkpoint/ios/` — Checkpoint iOS app (SwiftUI, SwiftData). See `apps/checkpoint/ios/CLAUDE.md`.
- `apps/checkpoint/web/` — Checkpoint marketing site (SolidJS, Cloudflare). See `apps/checkpoint/web/CLAUDE.md`.
- `apps/biombo/ios/` — Biombo iOS app (PR gas prices). See `apps/biombo/ios/CLAUDE.md` once scaffolded.
- `apps/biombo/backend/` — Biombo Node/TS + Postgres backend. See `apps/biombo/backend/CLAUDE.md`.

**Shared packages:**
- `packages/DesignKit/` — Swift design system (`ThemeProviding` protocol, tokens, modifiers). See `packages/DesignKit/CLAUDE.md`.
- `packages/Localization/` — Shared EN/ES strings via `.xcstrings`. See `packages/Localization/CLAUDE.md`.
- `packages/VehicleSharing/` — Cross-app odometer bridge over App Group `group.com.418-studio.shared`. Checkpoint publishes odometers + drains queued updates; Biombo reads + queues. See `packages/VehicleSharing/CLAUDE.md`.

**Internal tooling:**
- `tools/depth-backdrops/` — Local web app (Python/FastAPI + React/WebGL) that generates the cerulean depth-map backdrops behind device mockups in App Store screenshots. Run `tools/depth-backdrops/dev.sh`. See `tools/depth-backdrops/CLAUDE.md`.

**Docs:**
- `docs/BIOMBO_IMPLEMENTATION_PLAN.md` — active implementation plan
- `docs/AESTHETIC.md` — visual design philosophy (shared across 418 products)
- `docs/FUEL_PRICE_TRACKER.md` — original Biombo feature spec
- `docs/ARCHITECTURE.md`, `docs/FEATURES.md` — Checkpoint reference

## Progressive disclosure

This file is intentionally small. **Go to the scoped CLAUDE.md for the directory you're editing.** Do not load the whole repo into context when a single scoped file will do.

## Restricted files

- **`apps/checkpoint/ios/Secrets.xcconfig`** — API keys. **Never** read, cat, display, or `grep` this file.

## Build quick reference

- Checkpoint iOS: `xcodebuild build -project apps/checkpoint/ios/checkpoint.xcodeproj -scheme checkpoint -destination 'platform=iOS Simulator,name=iPhone 17'`
- Checkpoint web: `npm run dev` from `apps/checkpoint/web/`
- Biombo iOS: `xcodebuild build -project apps/biombo/ios/Biombo.xcodeproj -scheme Biombo -destination 'platform=iOS Simulator,name=iPhone 17'`
- Biombo backend: `npm run dev` from `apps/biombo/backend/`
- DesignKit: `swift build` from `packages/DesignKit/`
- Localization: `swift build` from `packages/Localization/`
- VehicleSharing: `swift test` from `packages/VehicleSharing/`
- Depth backdrops tool: `./dev.sh` from `tools/depth-backdrops/`

**Xcode note:** if `xcodebuild` errors with "requires Xcode", run commands with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` prefix or `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`.

**Never run multiple `xcodebuild` commands in parallel** (spawns multiple simulators, crashes).

## Concurrency rule (Swift)

Never use `nonisolated(unsafe)` or `@unchecked Sendable`. For static constants with `Sendable` types, use `nonisolated static let`.

## Feature tracking

`docs/FEATURES.md` tracks Checkpoint feature status. When shipping a new feature: mark `✅`, add tests, commit both together.
