# apps/

Top-level directory for each product in the monorepo. Every app has its own scoped CLAUDE.md — go to the one you're working in rather than loading this index.

## What lives here

- **`checkpoint/`** — Checkpoint (vehicle maintenance). Contains `ios/` (SwiftUI + SwiftData app, widget, watch app) and `web/` (SolidJS marketing site on Cloudflare).
- **`biombo/`** — Biombo (PR gas prices). Contains `ios/` (Swift iOS app) and `backend/` (Node/TS + Postgres). The backend is strictly separate from the iOS code and is **not bundled** into the app binary.

## Conventions

Each product directory owns its own tooling:
- Swift apps: `xcodeproj`, per-target `CLAUDE.md`, per-app `.xcstrings` catalog
- Backend services: `package.json`, migrations, self-contained tests

Shared SwiftPM packages live under `packages/`, not here.

## UI/UX rules apply across apps

`docs/SURFACE_DOCTRINE.md` governs screen structure for every app here, not just Checkpoint. `docs/AESTHETIC.md` governs visual identity. Read both before building a user-facing surface in either product.
