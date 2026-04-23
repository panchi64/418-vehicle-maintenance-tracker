# CLAUDE.md

418 Studio monorepo. Multiple apps share infrastructure via local SwiftPM packages.

## Directory map

**Apps:**
- `checkpoint-app/` — Checkpoint iOS app (SwiftUI, SwiftData). See `checkpoint-app/CLAUDE.md`.
- `checkpoint-website/` — Checkpoint marketing site (SolidJS, Cloudflare). See `checkpoint-website/CLAUDE.md`.
- `apps/biombo/ios/` — Biombo iOS app (PR gas prices). See `apps/biombo/ios/CLAUDE.md` once scaffolded.
- `apps/biombo/backend/` — Biombo Node/TS + Postgres backend. See `apps/biombo/backend/CLAUDE.md`.

**Shared packages:**
- `packages/DesignKit/` — Swift design system (`ThemeProviding` protocol, tokens, modifiers). See `packages/DesignKit/CLAUDE.md`.
- `packages/Localization/` — Shared EN/ES strings via `.xcstrings`. See `packages/Localization/CLAUDE.md`.

**Docs:**
- `docs/BIOMBO_IMPLEMENTATION_PLAN.md` — active implementation plan
- `docs/AESTHETIC.md` — visual design philosophy (shared across 418 products)
- `docs/FUEL_PRICE_TRACKER.md` — original Biombo feature spec
- `docs/ARCHITECTURE.md`, `docs/FEATURES.md` — Checkpoint reference

## Progressive disclosure

This file is intentionally small. **Go to the scoped CLAUDE.md for the directory you're editing.** Do not load the whole repo into context when a single scoped file will do.

## In-flight refactor (Phase 0, 2026-04-22)

The repo is transitioning to a symmetric `apps/` + `packages/` layout. Target structure:

```
apps/
  checkpoint/{ios,web}/
  biombo/{ios,backend}/
packages/
  DesignKit/
  Localization/
```

Status:
- `packages/DesignKit/`, `packages/Localization/`, `apps/biombo/backend/` **exist** (Phase 0 scaffold).
- `checkpoint-app/` and `checkpoint-website/` **have not yet moved** — waiting on Xcode availability to verify the build after relocation.
- The DesignKit extraction from Checkpoint's `DesignSystem/` is also pending — 1,750+ call sites to verify.

Until the moves happen, use current paths for Checkpoint (`checkpoint-app/`, `checkpoint-website/`).

## Restricted files

- **`checkpoint-app/Secrets.xcconfig`** — API keys. **Never** read, cat, display, or `grep` this file.

## Build quick reference

- Checkpoint iOS: `xcodebuild build -scheme checkpoint -destination 'platform=iOS Simulator,name=iPhone 17'` (from `checkpoint-app/`)
- Checkpoint web: `npm run dev` from `checkpoint-website/`
- Biombo backend: `npm run dev` from `apps/biombo/backend/`
- DesignKit: `swift build` from `packages/DesignKit/`
- Localization: `swift build` from `packages/Localization/`

**Never run multiple `xcodebuild` commands in parallel** (spawns multiple simulators, crashes).

## Concurrency rule (Swift)

Never use `nonisolated(unsafe)` or `@unchecked Sendable`. For static constants with `Sendable` types, use `nonisolated static let`.

## Feature tracking

`docs/FEATURES.md` tracks Checkpoint feature status. When shipping a new feature: mark `✅`, add tests, commit both together.
