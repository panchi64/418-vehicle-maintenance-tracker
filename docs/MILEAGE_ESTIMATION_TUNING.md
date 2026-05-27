# Mileage Estimation — Tuning Notes

Living notes on the pace-estimation algorithm. Append a dated entry whenever it gets retuned; keep the "Open follow-ups" section at the top current.

## How estimation works (short version)

- Estimate = `currentMileage + pace × daysSinceMileageUpdate`
- Pace = recency-weighted EWMA over consecutive-pair pace from `MileageSnapshot`s
- Weight per interval = `exp(-daysAgo / recencyHalfLifeDays)`, measured from the interval's midpoint
- Estimate suppressed if: no pace data, <7 days of snapshots, or >60 days since last update

Files: `apps/checkpoint/ios/checkpoint/Models/MileageSnapshot.swift` (pace), `Models/Vehicle+Mileage.swift` (estimate).

## Open follow-ups

- [ ] **Validate the 2026-05-26 fix in the wild.** Watch a few real update cycles. If the estimator still consistently overshoots or undershoots in one direction after several updates, the issue is systematic bias the EWMA can't self-correct → graduate to a true bias-correction term (below).
- [ ] **Bias-correction term (only if needed).** On each mileage update, compute residual = `actual − previouslyEstimated` and feed it into a running offset (e.g., EWMA of residuals with its own half-life). Apply offset to future estimates. This learns systematic over/under prediction the pace model can't capture (e.g., the user's pace is asymmetric — long quiet weeks punctuated by trips — which means the mean pace ≠ the daily-rate the linear estimator assumes). Requires storing the last estimate-at-time-of-snapshot somewhere (on `MileageSnapshot` or recomputed from the prior snapshot list).
- [ ] **Consider a hard recency window.** Snapshots older than ~90 days currently still contribute (with tiny weight). A hard cutoff would make behavior easier to reason about and avoid pathological cases where a year-old snapshot is the only "anchor."

## Change log

### 2026-05-26 — Reduced systematic overshoot

**Symptom (reported by Francisco):** 15 days since last update, app estimated 160,449 mi, actual was 160,330 mi → ~119 mi overshoot (~7.9 mi/day). Multiple update cycles, "consistently overshoots."

**Root causes identified:**

1. **Upward-biased filter.** `calculateDailyPace` rejected any interval with `milesDriven <= 0`. Quiet weeks (legitimate "didn't drive much") got silently dropped, leaving only higher-pace intervals in the average.
2. **Sluggish half-life.** 30-day half-life meant a 60-day-old high-pace interval still carried ~14% weight. If driving patterns dropped, the EWMA took ~2 months to follow.

**Fixes applied:**

- `recencyHalfLifeDays: 30 → 14`. A 60-day-old interval now carries ~1.4% weight; estimator tracks current pace within ~2 weeks.
- Changed interval filter from `milesDriven > 0` to `milesDriven >= 0`. Zero-mile intervals now count as real data. Negative deltas (data-entry mistakes) still rejected.
- Updated `testCalculateDailyPaceWithZeroMilesDriven` — same mileage over 14 days is now correctly `0 mi/day`, not `nil`.

**Not yet done (deferred — see Open follow-ups):**

- No bias-correction term. The EWMA still has no explicit feedback loop comparing past predictions to actual updates. If the two fixes above don't resolve the overshoot, that's the next lever.
