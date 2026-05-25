# apps/

Top-level directory for each product in the monorepo. Every app has its own scoped CLAUDE.md — go to the one you're working in rather than loading this index.

## What lives here

- **`biombo/`** — Biombo (PR gas prices). Contains `ios/` (Swift iOS app) and `backend/` (Node/TS + Postgres). The backend is strictly separate from the iOS code and is **not bundled** into the app binary.

## What's NOT here yet

- **Checkpoint** currently lives at `checkpoint-app/` (iOS) and `checkpoint-website/` (web) at the repo root. The planned move to `apps/checkpoint/{ios,web}/` is pending Xcode availability for build verification.

When that move happens, this file is updated to describe the unified layout.

## Conventions

Each product directory owns its own tooling:
- Swift apps: `xcodeproj`, per-target `CLAUDE.md`, per-app `.xcstrings` catalog
- Backend services: `package.json`, migrations, self-contained tests

Shared SwiftPM packages live under `packages/`, not here.
