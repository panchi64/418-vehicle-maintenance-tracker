//
//  Vehicle+Mileage.swift
//  checkpoint
//
//  Mileage tracking, pace calculation, and estimation
//

import Foundation
import SwiftData

extension Vehicle {
    /// Commit a new odometer reading: update `currentMileage` / `mileageUpdatedAt`
    /// and insert a `MileageSnapshot` (throttled to one per day) into `context`.
    ///
    /// This is the single source of the mileage-commit logic shared by manual
    /// entry, Siri, and companion-app (Biombo) updates. It performs only the
    /// model mutation; callers own side effects (widgets, notifications, save).
    ///
    /// - Returns: `true` if a snapshot was created (i.e. none existed for today).
    @discardableResult
    func recordMileage(
        _ mileage: Int,
        recordedAt: Date = .now,
        source: MileageSource,
        in context: ModelContext
    ) -> Bool {
        currentMileage = mileage
        mileageUpdatedAt = recordedAt

        let shouldCreateSnapshot = !MileageSnapshot.hasSnapshotToday(
            snapshots: mileageSnapshots ?? []
        )
        if shouldCreateSnapshot {
            let snapshot = MileageSnapshot(
                vehicle: self,
                mileage: mileage,
                recordedAt: recordedAt,
                source: source
            )
            context.insert(snapshot)
        }
        return shouldCreateSnapshot
    }
}

extension Vehicle {
    /// Whether the user has entered an initial mileage (0 = not yet set)
    var isMileageInitialized: Bool {
        currentMileage > 0
    }

    /// Calculate daily miles pace from mileage snapshots
    /// Returns nil if insufficient data (less than 7 days)
    var dailyMilesPace: Double? {
        MileageSnapshot.calculateDailyPace(from: mileageSnapshots ?? [])
    }

    /// Check if we have enough data for pace calculation (7+ days)
    var hasSufficientPaceData: Bool {
        dailyMilesPace != nil
    }

    /// Pace result with confidence metadata
    var paceResult: PaceResult? {
        MileageSnapshot.calculatePaceResult(from: mileageSnapshots ?? [])
    }

    /// Confidence level of the pace data
    var paceConfidence: ConfidenceLevel? {
        paceResult?.confidence
    }

    /// Maximum days since last update before we stop trusting estimates
    private static let maxEstimationDays = 60

    /// Estimated current mileage based on driving pace (in miles)
    /// Returns nil if insufficient pace data or stale data (>60 days)
    var estimatedMileage: Int? {
        guard let pace = dailyMilesPace,
              let daysSince = daysSinceMileageUpdate,
              daysSince <= Self.maxEstimationDays,
              daysSince > 0 else { return nil }

        let estimatedDriven = pace * Double(daysSince)
        return currentMileage + Int(round(estimatedDriven))
    }

    /// Returns estimated mileage if available, otherwise actual mileage (in miles)
    var effectiveMileage: Int {
        estimatedMileage ?? currentMileage
    }

    /// Whether the mileage displayed is estimated (vs actual)
    var isUsingEstimatedMileage: Bool {
        estimatedMileage != nil
    }

    /// Days since mileage was last updated
    var daysSinceMileageUpdate: Int? {
        guard let updatedAt = mileageUpdatedAt else { return nil }
        return Calendar.current.dateComponents([.day], from: updatedAt, to: .now).day
    }

    /// Whether to show the mileage update prompt (never updated, 0 mileage, or 14+ days)
    var shouldPromptMileageUpdate: Bool {
        if currentMileage == 0 { return true }
        guard let days = daysSinceMileageUpdate else {
            return true // Never updated
        }
        return days >= 14
    }

    /// Whether the vehicle header should surface the update prompt (dot + a11y announcement).
    /// Couples the data signal (`shouldPromptMileageUpdate`) with the caller's interactivity:
    /// read-only consumers should not advertise a prompt the user can't act on.
    func shouldDisplayMileageUpdatePrompt(isInteractive: Bool) -> Bool {
        isInteractive && shouldPromptMileageUpdate
    }

    /// Formatted string for last mileage update
    var mileageUpdateDescription: String {
        guard let days = daysSinceMileageUpdate else {
            return "Never updated"
        }
        if days == 0 {
            return "Updated today"
        } else if days == 1 {
            return "Updated yesterday"
        } else {
            return "Updated \(days) days ago"
        }
    }

    // MARK: - Period-based driving

    /// Miles driven year-to-date (since Jan 1 of the current calendar year).
    /// Falls back to "miles since first reading this year" when no pre-Jan-1 anchor exists,
    /// marking the result `isPartial = true` so callers can suppress YoY comparisons.
    /// Returns nil when there is no usable mileage history.
    var milesDrivenYearToDate: MileagePeriodResult? {
        let cal = Calendar.current
        let now = Date.now
        guard let startOfYear = cal.date(from: cal.dateComponents([.year], from: now)) else {
            return nil
        }
        let snapshots = (mileageSnapshots ?? []).sorted { $0.recordedAt < $1.recordedAt }
        guard !snapshots.isEmpty else { return nil }

        let baseline: MileageSnapshot
        let effectiveStart: Date
        let isPartial: Bool
        if let preYearAnchor = snapshots.last(where: { $0.recordedAt < startOfYear }) {
            baseline = preYearAnchor
            effectiveStart = startOfYear
            isPartial = false
        } else if let firstInYear = snapshots.first(where: { $0.recordedAt >= startOfYear }) {
            baseline = firstInYear
            effectiveStart = firstInYear.recordedAt
            isPartial = true
        } else {
            return nil
        }

        let driven = currentMileage - baseline.mileage
        guard driven >= 0 else { return nil }

        // Need at least a day's gap so the number means something.
        let daysElapsed = cal.dateComponents([.day], from: effectiveStart, to: now).day ?? 0
        guard daysElapsed >= 1 else { return nil }

        return MileagePeriodResult(miles: driven, effectiveStart: effectiveStart, isPartial: isPartial)
    }

    /// Miles driven in the same calendar window of the previous year
    /// (Jan 1 of last year → today's month/day of last year). Used for YoY comparison.
    /// Returns nil unless we have anchor snapshots bracketing both dates.
    var milesDrivenSamePeriodLastYear: Int? {
        let cal = Calendar.current
        let now = Date.now

        var startComponents = cal.dateComponents([.year], from: now)
        guard let currentYear = startComponents.year else { return nil }
        startComponents.year = currentYear - 1
        guard let startOfLastYear = cal.date(from: startComponents) else { return nil }

        var endComponents = cal.dateComponents([.year, .month, .day], from: now)
        endComponents.year = currentYear - 1
        guard let endOfPeriodLastYear = cal.date(from: endComponents) else { return nil }

        let sorted = (mileageSnapshots ?? []).sorted { $0.recordedAt < $1.recordedAt }
        return Self.milesBetween(sortedSnapshots: sorted, from: startOfLastYear, to: endOfPeriodLastYear)
    }

    /// Miles driven between two dates using snapshot anchors. Both anchors must exist
    /// (most-recent snapshot at-or-before each date) and end must be later than start.
    private static func milesBetween(sortedSnapshots: [MileageSnapshot], from startDate: Date, to endDate: Date) -> Int? {
        guard !sortedSnapshots.isEmpty,
              let startAnchor = sortedSnapshots.last(where: { $0.recordedAt <= startDate }),
              let endAnchor = sortedSnapshots.last(where: { $0.recordedAt <= endDate }),
              endAnchor.recordedAt > startAnchor.recordedAt else {
            return nil
        }
        let driven = endAnchor.mileage - startAnchor.mileage
        return driven >= 0 ? driven : nil
    }
}

/// Result of a period-based mileage calculation.
struct MileagePeriodResult: Equatable {
    /// Miles driven during the period (in internal storage units — miles).
    let miles: Int
    /// Start date actually used. May be after the requested start when no pre-period anchor exists.
    let effectiveStart: Date
    /// True when the calculation was shortened because no pre-period anchor existed.
    /// Callers should treat the number as "since [effectiveStart]" rather than full-period.
    let isPartial: Bool
}
