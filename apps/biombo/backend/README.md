# Biombo Backend

Node/TypeScript + PostgreSQL service that:
1. Scrapes DACO daily for baseline PR gas prices (Playwright-driven, `src/scraper/`).
2. Serves a public HTTP API consumed by the Biombo iOS app (`src/api/`).
3. Accepts crowd-sourced photo+OCR submissions, cross-references them against DACO to compute per-station price deltas.

**This directory is isolated from the iOS app.** It is never bundled into the app binary.

## Quick start

```bash
npm install
cp .env.example .env                   # point DATABASE_URL at a local Postgres
psql $DATABASE_URL < migrations/0001_init.sql
npm run dev                            # starts Fastify on :8787
npm run scrape:once                    # runs the scraper manually
npm test                               # vitest
npm run typecheck                      # tsc --noEmit
```

Phase 0 state: the scraper is a stub that writes an empty snapshot. Real DACO parsing lands in Phase 1. See `docs/BIOMBO_IMPLEMENTATION_PLAN.md` for the phase plan.

## API contract (Phase 0 draft)

| Method | Path                          | Purpose                                                |
|--------|-------------------------------|--------------------------------------------------------|
| GET    | `/health`                     | Liveness probe                                         |
| GET    | `/prices/current`             | Latest DACO snapshot + live community submissions      |
| GET    | `/prices/history?stationId=…` | 30-day price series for a given station                |
| GET    | `/brands`                     | Canonical DACO brand list (used by iOS for detection)  |
| POST   | `/submissions`                | Multipart: `image` (file) + `metadata` (JSON) fields   |
| POST   | `/submissions/:id/confirm`    | `{ deviceToken }`                                      |
| POST   | `/submissions/:id/flag`       | `{ deviceToken }`                                      |
| GET    | `/submissions/:id/image`      | JPEG bytes, cached 1 day                               |

### Submission metadata shape
```json
{
  "deviceToken": "uuid-from-keychain",
  "detectedBrand": "Puma",
  "stationName": "Puma San Patricio",
  "latitude": 18.418,
  "longitude": -66.075,
  "parsedRegular": 0.98,
  "parsedPremium": 1.12,
  "parsedDiesel": 1.05,
  "ocrText": "REG 0.98 / PREM 1.12 / DSL 1.05"
}
```

## Infra

Postgres only — host is deferred. Image bytes live in `submissions.image_bytes` as `bytea`. If per-image traffic grows, promote images to object storage without changing the iOS contract (served via `/submissions/:id/image`).
