import { describe, it, expect } from "vitest";
import { medianSmooth } from "../src/api/submissions.js";

describe("medianSmooth", () => {
  it("returns null for empty input", () => {
    expect(medianSmooth([])).toBeNull();
  });

  it("returns the single value for one-element input", () => {
    expect(medianSmooth([1.23])).toBe(1.23);
  });

  it("returns the middle value for odd-length input", () => {
    expect(medianSmooth([0.98, 1.12, 1.05])).toBe(1.05);
  });

  it("returns the average of the middle two for even-length input", () => {
    expect(medianSmooth([1.0, 1.2, 1.4, 1.6])).toBeCloseTo(1.3, 2);
  });

  it("is stable under re-ordering", () => {
    expect(medianSmooth([3, 1, 2])).toBe(medianSmooth([2, 1, 3]));
  });
});
