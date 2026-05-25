import type { FastifyInstance } from "fastify";
import { DACO_BRANDS } from "../scraper/brands.js";

export async function registerBrandRoutes(app: FastifyInstance): Promise<void> {
  app.get("/brands", async () => ({
    brands: DACO_BRANDS,
  }));
}
