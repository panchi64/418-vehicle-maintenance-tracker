import { describe, it, expect } from "vitest";
import { DACO_BRANDS, normalizeBrand } from "../src/scraper/brands.js";
import { scrapeDaco } from "../src/scraper/daco.js";

describe("DACO_BRANDS", () => {
  it("contains core PR station brands", () => {
    expect(DACO_BRANDS).toContain("Puma");
    expect(DACO_BRANDS).toContain("Shell");
    expect(DACO_BRANDS).toContain("Total");
  });
});

describe("normalizeBrand", () => {
  it("matches case-insensitive substrings", () => {
    expect(normalizeBrand("GULF GAS PREMIUM")).toBe("Gulf");
    expect(normalizeBrand("puma oeste")).toBe("Puma");
  });

  it("returns null for unknown brands", () => {
    expect(normalizeBrand("lukoil")).toBeNull();
  });
});

describe("scrapeDaco (stub)", () => {
  it("returns a well-formed result", async () => {
    const result = await scrapeDaco();
    expect(result.source).toContain("daco.pr.gov");
    expect(result.stations).toEqual([]);
    expect(result.scrapedAt).toBeInstanceOf(Date);
  });
});
