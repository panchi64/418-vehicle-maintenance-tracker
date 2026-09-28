# apps/

Top-level directory for each product in the monorepo. Every app has its own scoped CLAUDE.md — go to the one you're working in rather than loading this index.

## What lives here

- **`checkpoint/`** — Checkpoint (vehicle maintenance). Contains `ios/` (SwiftUI + SwiftData app, widget, watch app) and `web/` (SolidJS marketing site on Cloudflare).
- **`biombo/`** — Biombo (a map of everyday life in Puerto Rico; greenfield rebuild). See `biombo/CLAUDE.md`.

## Conventions

Each product directory owns its own tooling:
- Swift apps: `xcodeproj`, per-target `CLAUDE.md`, per-app `.xcstrings` catalog
- Backend services: `package.json`, migrations, self-contained tests

Shared SwiftPM packages live under `packages/`, not here.

## UI/UX rules are per app

`docs/SURFACE_DOCTRINE.md` and `docs/AESTHETIC.md` govern **Checkpoint** only. Biombo's design and product docs live in `biombo/docs/` and are separate.
