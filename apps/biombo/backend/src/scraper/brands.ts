/**
 * Canonical DACO brand list. Phase 0 stub — expand once the real DACO page
 * selectors are reverse-engineered. Used by the iOS app's BrandDetectionService
 * (served over GET /brands) to match OCR text against known station brands.
 */
export const DACO_BRANDS = [
  "Puma",
  "Shell",
  "Total",
  "Gulf",
  "Sol",
  "Texaco",
  "Mobil",
  "Esso",
  "Costco",
  "Sam's Club",
] as const;

export type DacoBrand = (typeof DACO_BRANDS)[number];

export function normalizeBrand(raw: string): DacoBrand | null {
  const lowered = raw.trim().toLowerCase();
  for (const brand of DACO_BRANDS) {
    if (lowered.includes(brand.toLowerCase())) {
      return brand;
    }
  }
  return null;
}
