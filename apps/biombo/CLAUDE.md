# Biombo

Puerto Rico gas-price tracker. Standalone iOS app + Postgres-backed backend. Companion to Checkpoint; shares `DesignKit` and `Localization` packages.

## Subdirectories

- **`ios/`** — Swift iOS app (Phase 0: not yet scaffolded; pending Xcode).
- **`backend/`** — Node/TS + PostgreSQL. DACO scraper + submissions API. See `backend/CLAUDE.md`.

## Identity

- **Bundle ID:** `com.418-studio.biombo`
- **Aesthetic:** per `docs/AESTHETIC.md` — Cerulean `#0033BE` + Off-White `#F5F0DC`, JetBrains Mono
- **Languages:** EN + ES (day one)
- **Minimum iOS:** 17

## Data flow

```
DACO website
    │ (daily scrape)
    ▼
backend (PostgreSQL)
    │ ◄───── photo + OCR + detected brand (multipart POST)
    ▼
Biombo iOS
    - Map (Apple MapKit w/ brutalist overlay)
    - List (distance-sorted)
    - Detail (trend chart + DACO delta)
    - Submit (camera → on-device Vision OCR → POST)
```

The backend is the **sole** integration seam with DACO. The iOS app never hits DACO directly.

## Phase tracking

See `docs/BIOMBO_IMPLEMENTATION_PLAN.md`. Current state: Phase 0 scaffolding (packages + backend skeleton + CLAUDE.md files).

## Restricted / private content

No secrets in this subtree yet. Backend will expect `DATABASE_URL` in an uncommitted `.env` — see `backend/.env.example`.
