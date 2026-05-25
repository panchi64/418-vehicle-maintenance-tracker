import type { FastifyInstance } from "fastify";
import { and, desc, eq, gt, lt } from "drizzle-orm";
import { db } from "../db/client.js";
import { dacoSnapshots, dacoStationPrices, submissions } from "../db/schema.js";
import { medianSmooth } from "./submissions.js";

const MEDIAN_WINDOW_MS = 24 * 60 * 60 * 1000;
const MAX_FLAG_COUNT = 3;

type CommunityRow = typeof submissions.$inferSelect;

export async function registerPriceRoutes(app: FastifyInstance): Promise<void> {
  app.get("/prices/current", async () => {
    const [latest] = await db
      .select()
      .from(dacoSnapshots)
      .orderBy(desc(dacoSnapshots.scrapedAt))
      .limit(1);

    const dacoStations = latest
      ? await db
          .select()
          .from(dacoStationPrices)
          .where(eq(dacoStationPrices.snapshotId, latest.id))
      : [];

    const now = new Date();
    const visible = await db
      .select()
      .from(submissions)
      .where(
        and(
          gt(submissions.expiresAt, now),
          lt(submissions.flagCount, MAX_FLAG_COUNT)
        )
      );

    return {
      snapshotId: latest?.id ?? null,
      scrapedAt: latest?.scrapedAt ?? null,
      daco: dacoStations,
      community: smoothCommunity(visible),
    };
  });

  app.get("/prices/history", async (request) => {
    const { stationId, days } = request.query as {
      stationId?: string;
      days?: string;
    };
    void stationId;
    void days;
    return { stationId: stationId ?? null, points: [] };
  });
}

function smoothCommunity(rows: CommunityRow[]): CommunityRow[] {
  const windowCutoff = new Date(Date.now() - MEDIAN_WINDOW_MS);
  const groups = new Map<string, CommunityRow[]>();

  for (const row of rows) {
    if (row.createdAt < windowCutoff) continue;
    const key = groupKey(row);
    const bucket = groups.get(key) ?? [];
    bucket.push(row);
    groups.set(key, bucket);
  }

  const smoothed: CommunityRow[] = [];
  for (const bucket of groups.values()) {
    if (bucket.length < 3) {
      smoothed.push(...bucket);
      continue;
    }
    bucket.sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
    const representative = { ...bucket[0]! } satisfies CommunityRow;
    representative.parsedRegular = medianSmooth(
      bucket.map((r) => r.parsedRegular).filter((v): v is number => v != null)
    );
    representative.parsedPremium = medianSmooth(
      bucket.map((r) => r.parsedPremium).filter((v): v is number => v != null)
    );
    representative.parsedDiesel = medianSmooth(
      bucket.map((r) => r.parsedDiesel).filter((v): v is number => v != null)
    );
    smoothed.push(representative);
  }
  return smoothed;
}

function groupKey(row: CommunityRow): string {
  const brand = row.detectedBrand ?? "unknown";
  const lat = row.latitude.toFixed(3);
  const lng = row.longitude.toFixed(3);
  return `${brand}@${lat},${lng}`;
}
