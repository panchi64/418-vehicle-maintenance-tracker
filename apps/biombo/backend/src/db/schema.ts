import {
  pgTable,
  uuid,
  text,
  timestamp,
  doublePrecision,
  integer,
  customType,
  index,
} from "drizzle-orm/pg-core";

const bytea = customType<{ data: Buffer; default: false }>({
  dataType() {
    return "bytea";
  },
});

export const dacoSnapshots = pgTable(
  "daco_snapshots",
  {
    id: uuid("id").defaultRandom().primaryKey(),
    scrapedAt: timestamp("scraped_at", { withTimezone: true }).defaultNow().notNull(),
    source: text("source").notNull(),
    rawPayload: text("raw_payload"),
  },
  (t) => ({
    scrapedAtIdx: index("idx_daco_snapshots_scraped_at").on(t.scrapedAt),
  })
);

export const dacoStationPrices = pgTable(
  "daco_station_prices",
  {
    id: uuid("id").defaultRandom().primaryKey(),
    snapshotId: uuid("snapshot_id")
      .references(() => dacoSnapshots.id, { onDelete: "cascade" })
      .notNull(),
    brand: text("brand").notNull(),
    stationName: text("station_name"),
    municipality: text("municipality"),
    latitude: doublePrecision("latitude"),
    longitude: doublePrecision("longitude"),
    regular: doublePrecision("regular"),
    premium: doublePrecision("premium"),
    diesel: doublePrecision("diesel"),
  },
  (t) => ({
    brandMunicipalityIdx: index("idx_daco_station_prices_brand_municipality").on(
      t.brand,
      t.municipality
    ),
  })
);

export const submissions = pgTable(
  "submissions",
  {
    id: uuid("id").defaultRandom().primaryKey(),
    createdAt: timestamp("created_at", { withTimezone: true }).defaultNow().notNull(),
    expiresAt: timestamp("expires_at", { withTimezone: true }).notNull(),
    deviceToken: text("device_token").notNull(),
    detectedBrand: text("detected_brand"),
    stationName: text("station_name"),
    latitude: doublePrecision("latitude").notNull(),
    longitude: doublePrecision("longitude").notNull(),
    parsedRegular: doublePrecision("parsed_regular"),
    parsedPremium: doublePrecision("parsed_premium"),
    parsedDiesel: doublePrecision("parsed_diesel"),
    ocrText: text("ocr_text"),
    imageBytes: bytea("image_bytes"),
    dacoDeltaRegular: doublePrecision("daco_delta_regular"),
    dacoDeltaPremium: doublePrecision("daco_delta_premium"),
    dacoDeltaDiesel: doublePrecision("daco_delta_diesel"),
    confirmationCount: integer("confirmation_count").default(0).notNull(),
    flagCount: integer("flag_count").default(0).notNull(),
  },
  (t) => ({
    locationIdx: index("idx_submissions_location").on(t.latitude, t.longitude),
    expiresAtIdx: index("idx_submissions_expires_at").on(t.expiresAt),
  })
);

export const submissionInteractions = pgTable(
  "submission_interactions",
  {
    id: uuid("id").defaultRandom().primaryKey(),
    submissionId: uuid("submission_id")
      .references(() => submissions.id, { onDelete: "cascade" })
      .notNull(),
    deviceToken: text("device_token").notNull(),
    kind: text("kind", { enum: ["confirm", "flag"] as const }).notNull(),
    createdAt: timestamp("created_at", { withTimezone: true }).defaultNow().notNull(),
  },
  (t) => ({
    uniqueDeviceInteraction: index("idx_submission_interactions_unique").on(
      t.submissionId,
      t.deviceToken,
      t.kind
    ),
  })
);
