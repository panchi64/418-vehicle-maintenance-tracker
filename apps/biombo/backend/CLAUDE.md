# Biombo Backend

Node 20+ / TypeScript. Fastify HTTP API + Playwright DACO scraper + Drizzle ORM over PostgreSQL.

## NEVER bundle into the iOS app

The iOS app talks to this via HTTP only. No source, type definitions, or runtime code from this directory is ever compiled into the Biombo app binary. If you're editing the iOS app and find yourself reaching for code in this directory, stop — the right move is to extend the HTTP API contract.

## Architecture

```
src/
├── index.ts          # Fastify bootstrap
├── db/
│   ├── client.ts     # Postgres pool + Drizzle instance
│   └── schema.ts     # Drizzle schema — source of truth for DB shape
├── api/
│   ├── prices.ts     # GET /prices/current, /prices/history
│   ├── brands.ts     # GET /brands (canonical DACO brand list)
│   └── submissions.ts # POST /submissions, confirm, flag, image
├── scraper/
│   ├── daco.ts       # Playwright scraper (Phase 0 stub)
│   └── brands.ts     # DACO_BRANDS canonical list + normalizeBrand()
└── jobs/
    └── dailyScrape.ts # cron entry: `npm run scrape:once`
migrations/
└── 0001_init.sql     # hand-authored initial schema (matches schema.ts)
tests/
└── scraper.test.ts   # vitest — runs against stubs; DB tests need local Postgres
```

## Commands

```bash
npm install                    # first time
cp .env.example .env           # local dev
psql $DATABASE_URL < migrations/0001_init.sql
npm run dev                    # Fastify on :8787
npm run typecheck              # tsc --noEmit
npm test                       # vitest
npm run scrape:once            # manual DACO scrape
npm run db:generate            # drizzle-kit: regenerate migrations from schema.ts
```

## Database

Postgres only — deployment host is deferred. All data (images included) lives in Postgres. Submissions' `image_bytes` is a `bytea` column; served back via `GET /submissions/:id/image` with 1-day cache. If image volume outgrows Postgres, promote blobs to object storage without breaking the iOS contract.

`gen_random_uuid()` requires the `pgcrypto` extension in some Postgres deployments — enable it in a bootstrap migration if needed.

## Scraper (Phase 0 state)

`scrapeDaco()` returns an empty stub. `scrapeDacoWithBrowser()` is a reference Playwright implementation waiting for real parsing logic. DACO blocks default crawlers (403); the headless UA spoof is the first line of defense.

Selectors will break. The dailyScrape job logs raw HTML to `rawPayload` so parse breaks can be debugged from last-good snapshots.

## API contract

See `README.md` for the route table. Any change to request/response shapes also requires an update in the iOS `BiomboAPIService` test fixtures.

## Security

- No auth — the API is intentionally anonymous. Submissions are rate-limited by opaque `device_token` (UUID generated on first iOS launch, stored in Keychain).
- Image uploads capped at 2 MB via Fastify multipart limits. iOS compresses to 400×400 / JPEG 0.5 ≈ 30–50 KB before POST.
- Validate all request bodies with Zod. Never trust client-supplied fields.
