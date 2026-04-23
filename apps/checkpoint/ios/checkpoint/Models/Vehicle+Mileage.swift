//
//  Vehicle+Mileage.swift
//  checkpoint
//
//  Mileage tracking, pace calculation, and estimation
//

import Foundation

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
}
