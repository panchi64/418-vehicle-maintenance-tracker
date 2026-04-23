import { db } from "../db/client.js";
import { dacoSnapshots, dacoStationPrices } from "../db/schema.js";
import { scrapeDaco } from "../scraper/daco.js";

/**
 * Entry point for the daily scrape cron. Run manually via
 *   npm run scrape:once
 * or schedule in production (GitHub Actions, systemd timer, pg_cron, etc).
 */
export async function runDailyScrape(): Promise<void> {
  console.log("[daily-scrape] start", new Date().toISOString());
  const result = await scrapeDaco();

  const [snapshot] = await db
    .insert(dacoSnapshots)
    .values({
      source: result.source,
      rawPayload: result.rawPayload ?? null,
      scrapedAt: result.scrapedAt,
    })
    .returning();

  if (!snapshot) {
    throw new Error("Failed to persist snapshot row");
  }

  if (result.stations.length > 0) {
    await db.insert(dacoStationPrices).values(
      result.stations.map((station) => ({
        snapshotId: snapshot.id,
        brand: station.brand,
        stationName: station.stationName ?? null,
        municipality: station.municipality ?? null,
        latitude: station.latitude ?? null,
        longitude: station.longitude ?? null,
        regular: station.regular ?? null,
        premium: station.premium ?? null,
        diesel: station.diesel ?? null,
      }))
    );
  }

  console.log(
    "[daily-scrape] done",
    `snapshot=${snapshot.id}`,
    `stations=${result.stations.length}`
  );
}

if (import.meta.url === `file://${process.argv[1]}`) {
  runDailyScrape()
    .then(() => process.exit(0))
    .catch((err) => {
      console.error("[daily-scrape] failed", err);
      process.exit(1);
    });
}
