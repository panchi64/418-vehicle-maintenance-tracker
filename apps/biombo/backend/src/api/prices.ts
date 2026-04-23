import type { FastifyInstance } from "fastify";
import { desc, eq, gt } from "drizzle-orm";
import { db } from "../db/client.js";
import { dacoSnapshots, dacoStationPrices, submissions } from "../db/schema.js";

export async function registerPriceRoutes(app: FastifyInstance): Promise<void> {
  app.get("/prices/current", async () => {
    const latestSnapshot = await db
      .select()
      .from(dacoSnapshots)
      .orderBy(desc(dacoSnapshots.scrapedAt))
      .limit(1);

    const snapshot = latestSnapshot[0];
    const dacoStations = snapshot
      ? await db
          .select()
          .from(dacoStationPrices)
          .where(eq(dacoStationPrices.snapshotId, snapshot.id))
      : [];

    const now = new Date();
    const liveSubmissions = await db
      .select()
      .from(submissions)
      .where(gt(submissions.expiresAt, now));

    return {
      snapshotId: snapshot?.id ?? null,
      scrapedAt: snapshot?.scrapedAt ?? null,
      daco: dacoStations,
      community: liveSubmissions.filter((s) => s.flagCount < 3),
    };
  });

  app.get("/prices/history", async (request) => {
    const { stationId, days } = request.query as {
      stationId?: string;
      days?: string;
    };
    void stationId;
    void days;
    // Phase 0 stub — returns empty series. Real implementation queries
    // daco_station_prices joined with daco_snapshots across the date range.
    return { stationId: stationId ?? null, points: [] };
  });
}
