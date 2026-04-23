-- Phase 0 schema. Managed via drizzle-kit; regenerate with `npm run db:generate`.
-- Hand-written here so the initial schema is reviewable in-repo without
-- requiring node_modules.

CREATE TABLE IF NOT EXISTS "daco_snapshots" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "scraped_at" timestamptz NOT NULL DEFAULT now(),
  "source" text NOT NULL,
  "raw_payload" text
);
CREATE INDEX IF NOT EXISTS "idx_daco_snapshots_scraped_at" ON "daco_snapshots" ("scraped_at");

CREATE TABLE IF NOT EXISTS "daco_station_prices" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "snapshot_id" uuid NOT NULL REFERENCES "daco_snapshots"("id") ON DELETE CASCADE,
  "brand" text NOT NULL,
  "station_name" text,
  "municipality" text,
  "latitude" double precision,
  "longitude" double precision,
  "regular" double precision,
  "premium" double precision,
  "diesel" double precision
);
CREATE INDEX IF NOT EXISTS "idx_daco_station_prices_brand_municipality"
  ON "daco_station_prices" ("brand", "municipality");

CREATE TABLE IF NOT EXISTS "submissions" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "expires_at" timestamptz NOT NULL,
  "device_token" text NOT NULL,
  "detected_brand" text,
  "station_name" text,
  "latitude" double precision NOT NULL,
  "longitude" double precision NOT NULL,
  "parsed_regular" double precision,
  "parsed_premium" double precision,
  "parsed_diesel" double precision,
  "ocr_text" text,
  "image_bytes" bytea,
  "daco_delta_regular" double precision,
  "daco_delta_premium" double precision,
  "daco_delta_diesel" double precision,
  "confirmation_count" integer NOT NULL DEFAULT 0,
  "flag_count" integer NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS "idx_submissions_location" ON "submissions" ("latitude", "longitude");
CREATE INDEX IF NOT EXISTS "idx_submissions_expires_at" ON "submissions" ("expires_at");

CREATE TABLE IF NOT EXISTS "submission_interactions" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "submission_id" uuid NOT NULL REFERENCES "submissions"("id") ON DELETE CASCADE,
  "device_token" text NOT NULL,
  "kind" text NOT NULL CHECK ("kind" IN ('confirm', 'flag')),
  "created_at" timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS "idx_submission_interactions_unique"
  ON "submission_interactions" ("submission_id", "device_token", "kind");
