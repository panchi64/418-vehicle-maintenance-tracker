import Fastify from "fastify";
import multipart from "@fastify/multipart";
import { registerPriceRoutes } from "./api/prices.js";
import { registerBrandRoutes } from "./api/brands.js";
import { registerSubmissionRoutes } from "./api/submissions.js";

async function main() {
  const app = Fastify({
    logger: process.env.NODE_ENV === "production" ? true : { level: "info" },
    bodyLimit: 10 * 1024 * 1024,
  });

  await app.register(multipart, {
    limits: {
      fileSize: 2 * 1024 * 1024,
      files: 1,
    },
  });

  await registerPriceRoutes(app);
  await registerBrandRoutes(app);
  await registerSubmissionRoutes(app);

  app.get("/health", async () => ({ ok: true }));

  const port = Number(process.env.PORT ?? 8787);
  const host = process.env.HOST ?? "0.0.0.0";
  await app.listen({ port, host });
  app.log.info(`biombo-backend listening on http://${host}:${port}`);
}

main().catch((err) => {
  console.error("biombo-backend failed to start", err);
  process.exit(1);
});
