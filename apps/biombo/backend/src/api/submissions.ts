import type { FastifyInstance, FastifyReply } from "fastify";
import { and, desc, eq, gte } from "drizzle-orm";
import { z } from "zod";
import { db } from "../db/client.js";
import {
  dacoStationPrices,
  dacoSnapshots,
  submissions,
  submissionInteractions,
} from "../db/schema.js";

const SUBMISSION_TTL_MS = 48 * 60 * 60 * 1000;
const RATE_LIMIT_WINDOW_MS = 24 * 60 * 60 * 1000;
const MAX_SUBMISSIONS_PER_DEVICE_PER_DAY = 20;

const deviceTokenSchema = z.string().min(8).max(128);

const submissionInputSchema = z.object({
  deviceToken: deviceTokenSchema,
  detectedBrand: z.string().nullable().optional(),
  stationName: z.string().nullable().optional(),
  latitude: z.number().min(-90).max(90),
  longitude: z.number().min(-180).max(180),
  parsedRegular: z.number().positive().optional(),
  parsedPremium: z.number().positive().optional(),
  parsedDiesel: z.number().positive().optional(),
  ocrText: z.string().nullable().optional(),
});

const interactionSchema = z.object({ deviceToken: deviceTokenSchema });

export async function registerSubmissionRoutes(
  app: FastifyInstance
): Promise<void> {
  app.post("/submissions", async (request, reply) => {
    const parts = request.parts();
    let metadataJSON: string | undefined;
    let imageBuffer: Buffer | undefined;

    for await (const part of parts) {
      if (part.type === "file" && part.fieldname === "image") {
        imageBuffer = await part.toBuffer();
      } else if (part.type === "field" && part.fieldname === "metadata") {
        metadataJSON = typeof part.value === "string" ? part.value : undefined;
      }
    }

    if (!metadataJSON) {
      return reply.code(400).send({ error: "Missing metadata field" });
    }

    const parsed = submissionInputSchema.safeParse(JSON.parse(metadataJSON));
    if (!parsed.success) {
      return reply.code(400).send({ error: parsed.error.flatten() });
    }
    const input = parsed.data;

    const windowStart = new Date(Date.now() - RATE_LIMIT_WINDOW_MS);
    const recent = await db
      .select({ id: submissions.id })
      .from(submissions)
      .where(
        and(
          eq(submissions.deviceToken, input.deviceToken),
          gte(submissions.createdAt, windowStart)
        )
      )
      .limit(MAX_SUBMISSIONS_PER_DEVICE_PER_DAY);

    if (recent.length >= MAX_SUBMISSIONS_PER_DEVICE_PER_DAY) {
      return reply.code(429).send({ error: "submission limit reached" });
    }

    const deltas = await computeDacoDeltas(input);

    const [row] = await db
      .insert(submissions)
      .values({
        deviceToken: input.deviceToken,
        detectedBrand: input.detectedBrand ?? null,
        stationName: input.stationName ?? null,
        latitude: input.latitude,
        longitude: input.longitude,
        parsedRegular: input.parsedRegular ?? null,
        parsedPremium: input.parsedPremium ?? null,
        parsedDiesel: input.parsedDiesel ?? null,
        ocrText: input.ocrText ?? null,
        imageBytes: imageBuffer ?? null,
        expiresAt: new Date(Date.now() + SUBMISSION_TTL_MS),
        dacoDeltaRegular: deltas.regular,
        dacoDeltaPremium: deltas.premium,
        dacoDeltaDiesel: deltas.diesel,
      })
      .returning();

    return reply.code(201).send({ submission: row });
  });

  app.post<{ Params: { id: string }; Body: unknown }>(
    "/submissions/:id/confirm",
    async (request, reply) =>
      toggleInteraction({
        submissionId: request.params.id,
        rawBody: request.body,
        kind: "confirm",
        reply,
      })
  );

  app.post<{ Params: { id: string }; Body: unknown }>(
    "/submissions/:id/flag",
    async (request, reply) =>
      toggleInteraction({
        submissionId: request.params.id,
        rawBody: request.body,
        kind: "flag",
        reply,
      })
  );

  app.get<{ Params: { id: string } }>(
    "/submissions/:id/image",
    async (request, reply) => {
      const [row] = await db
        .select()
        .from(submissions)
        .where(eq(submissions.id, request.params.id))
        .limit(1);
      if (!row?.imageBytes) return reply.code(404).send();
      return reply
        .header("Content-Type", "image/jpeg")
        .header("Cache-Control", "public, max-age=86400")
        .send(row.imageBytes);
    }
  );
}

async function computeDacoDeltas(input: {
  detectedBrand?: string | null | undefined;
  parsedRegular?: number | undefined;
  parsedPremium?: number | undefined;
  parsedDiesel?: number | undefined;
}) {
  const empty = { regular: null, premium: null, diesel: null } as {
    regular: number | null;
    premium: number | null;
    diesel: number | null;
  };
  if (!input.detectedBrand) return empty;

  const [latest] = await db
    .select()
    .from(dacoSnapshots)
    .orderBy(desc(dacoSnapshots.scrapedAt))
    .limit(1);
  if (!latest) return empty;

  const matches = await db
    .select()
    .from(dacoStationPrices)
    .where(
      and(
        eq(dacoStationPrices.snapshotId, latest.id),
        eq(dacoStationPrices.brand, input.detectedBrand)
      )
    );

  const avg = (key: "regular" | "premium" | "diesel") => {
    const values = matches
      .map((m) => m[key])
      .filter((v): v is number => v != null);
    if (values.length === 0) return null;
    return values.reduce((a, b) => a + b, 0) / values.length;
  };

  const delta = (sample: number | undefined, average: number | null) => {
    if (sample == null || average == null) return null;
    return Number((sample - average).toFixed(3));
  };

  return {
    regular: delta(input.parsedRegular, avg("regular")),
    premium: delta(input.parsedPremium, avg("premium")),
    diesel: delta(input.parsedDiesel, avg("diesel")),
  };
}

async function toggleInteraction({
  submissionId,
  rawBody,
  kind,
  reply,
}: {
  submissionId: string;
  rawBody: unknown;
  kind: "confirm" | "flag";
  reply: FastifyReply;
}) {
  const parsed = interactionSchema.safeParse(rawBody);
  if (!parsed.success) {
    return reply.code(400).send({ error: parsed.error.flatten() });
  }
  const { deviceToken } = parsed.data;

  const [existingInteraction] = await db
    .select()
    .from(submissionInteractions)
    .where(
      and(
        eq(submissionInteractions.submissionId, submissionId),
        eq(submissionInteractions.deviceToken, deviceToken),
        eq(submissionInteractions.kind, kind)
      )
    )
    .limit(1);

  if (existingInteraction) {
    return reply.code(200).send({ ok: true, duplicate: true });
  }

  await db.insert(submissionInteractions).values({
    submissionId,
    deviceToken,
    kind,
  });

  const counterField = kind === "confirm" ? "confirmationCount" : "flagCount";
  const [row] = await db
    .select()
    .from(submissions)
    .where(eq(submissions.id, submissionId))
    .limit(1);
  if (!row) return reply.code(404).send({ error: "not found" });

  await db
    .update(submissions)
    .set({ [counterField]: row[counterField] + 1 })
    .where(eq(submissions.id, submissionId));

  return reply.code(200).send({ ok: true });
}

export function medianSmooth(values: number[]): number | null {
  if (values.length === 0) return null;
  const sorted = [...values].sort((a, b) => a - b);
  const mid = Math.floor(sorted.length / 2);
  if (sorted.length % 2 === 0) {
    return (sorted[mid - 1]! + sorted[mid]!) / 2;
  }
  return sorted[mid]!;
}
