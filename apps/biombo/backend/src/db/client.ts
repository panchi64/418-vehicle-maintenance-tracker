import pg from "pg";
import { drizzle } from "drizzle-orm/node-postgres";
import * as schema from "./schema.js";

const connectionString =
  process.env.DATABASE_URL ?? "postgres://localhost:5432/biombo";

export const pool = new pg.Pool({ connectionString });
export const db = drizzle(pool, { schema });
export type DB = typeof db;
