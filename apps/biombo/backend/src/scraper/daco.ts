import { chromium, type Browser } from "playwright";
import { DACO_BRANDS } from "./brands.js";

/**
 * Phase 0 scraper stub. The DACO site blocks WebFetch (403) and publishes
 * Excel/HTML mixtures of price data. This module is the integration seam for
 * the real scraper; Phase 0 ships a stub returning an empty snapshot so the
 * API boots end-to-end.
 *
 * Real implementation lands in Phase 1:
 * 1. Launch headless Chromium with a realistic UA.
 * 2. Navigate to https://www.daco.pr.gov/datosdecombustible/ and each linked
 *    "precio" page. Cache HTML snapshots under `data/snapshots/YYYY-MM-DD/`.
 * 3. Extract station-level prices if present, else fall back to
 *    municipality-level averages, else fall back to island-wide averages.
 * 4. Return `DacoScrapeResult` for persistence by `jobs/dailyScrape.ts`.
 */
export interface DacoScrapedStation {
  brand: string;
  stationName?: string;
  municipality?: string;
  latitude?: number;
  longitude?: number;
  regular?: number;
  premium?: number;
  diesel?: number;
}

export interface DacoScrapeResult {
  source: string;
  scrapedAt: Date;
  rawPayload?: string;
  stations: DacoScrapedStation[];
}

export async function scrapeDaco(): Promise<DacoScrapeResult> {
  // Phase 0 stub — returns empty snapshot with metadata so the rest of the
  // pipeline (persistence, API response, cron job) exercises end-to-end.
  return {
    source: "daco.pr.gov (stub)",
    scrapedAt: new Date(),
    stations: [],
  };
}

/** Reference implementation pattern for when the real scraper lands. */
export async function scrapeDacoWithBrowser(): Promise<DacoScrapeResult> {
  let browser: Browser | undefined;
  try {
    browser = await chromium.launch({ headless: true });
    const context = await browser.newContext({
      userAgent:
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    });
    const page = await context.newPage();
    await page.goto("https://www.daco.pr.gov/datosdecombustible/", {
      waitUntil: "networkidle",
    });
    const html = await page.content();

    // TODO(Phase 1): parse actual station rows. Confirm DACO brand list against DACO_BRANDS.
    void DACO_BRANDS;

    return {
      source: "daco.pr.gov",
      scrapedAt: new Date(),
      rawPayload: html,
      stations: [],
    };
  } finally {
    await browser?.close();
  }
}
