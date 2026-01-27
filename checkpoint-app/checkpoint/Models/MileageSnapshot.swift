//
//  MileageSnapshot.swift
//  checkpoint
//
//  SwiftData model for tracking mileage readings over time
//  Used for pace calculation (daily miles driven)
//

import Foundation
import SwiftData

enum MileageSource: String, Codable {
    case manual = "manual"
    case serviceCompletion = "service_completion"
}

@Model
final class MileageSnapshot: Identifiable {
    var id: UUID = UUID()
    var vehicle: Vehicle?
    var mileage: Int
    var recordedAt: Date
    var source: MileageSource

    init(
        vehicle: Vehicle? = nil,
        mileage: Int,
        recordedAt: Date = .now,
        source: MileageSource = .manual
    ) {
        self.vehicle = vehicle
        self.mileage = mileage
        self.recordedAt = recordedAt
        self.source = source
    }
}

// MARK: - Pace Result

/// Result of pace calculation including confidence metadata
struct PaceResult {
    let milesPerDay: Double
    let confidence: ConfidenceLevel
    let dataPointCount: Int
    let dateRange: DateInterval

    /// Minimum days of data required
    static let minimumDays = 7

    /// Days for high confidence (30+ days)
    static let highConfidenceDays = 30

    /// Days for medium confidence (14-29 days)
    static let mediumConfidenceDays = 14

    /// Minimum snapshots for high confidence
    static let highConfidenceSnapshots = 5

    /// Minimum snapshots for medium confidence
    static let mediumConfidenceSnapshots = 3
}

// MARK: - Pace Calculation Helpers

extension MileageSnapshot {
    /// Half-life for recency weighting (in days)
    /// Snapshots older than this have weight reduced by half
    private static let recencyHalfLifeDays: Double = 30.0

    /// Calculate daily miles pace from an array of snapshots using recency-weighted averaging
    /// Recent snapshots are weighted more heavily using exponential decay (EWMA)
    /// Requires at least 7 days of data to return a meaningful pace
    static func calculateDailyPace(from snapshots: [MileageSnapshot]) -> Double? {
        guard snapshots.count >= 2 else { return nil }

        // Sort by date ascending
        let sorted = snapshots.sorted { $0.recordedAt < $1.recordedAt }

        guard let oldest = sorted.first,
              let newest = sorted.last else { return nil }

        let totalDaysBetween = Calendar.current.dateComponents(
            [.day],
            from: oldest.recordedAt,
            to: newest.recordedAt
        ).day ?? 0

        // Require at least 7 days of data for meaningful pace
        guard totalDaysBetween >= 7 else { return nil }

        // Calculate weighted pace using consecutive snapshot pairs
        var weightedPaceSum: Double = 0
        var weightSum: Double = 0
        let now = Date.now

        for i in 0..<(sorted.count - 1) {
            let earlier = sorted[i]
            let later = sorted[i + 1]

            // Calculate pace for this pair
            let daysBetweenPair = Calendar.current.dateComponents(
                [.day],
                from: earlier.recordedAt,
                to: later.recordedAt
            ).day ?? 0

            guard daysBetweenPair > 0 else { continue }

            let milesDriven = later.mileage - earlier.mileage
            guard milesDriven > 0 else { continue }

            let pace = Double(milesDriven) / Double(daysBetweenPair)

            // Calculate weight based on midpoint recency
            // Use the midpoint of the interval to determine recency
            let midpointDate = earlier.recordedAt.addingTimeInterval(
                later.recordedAt.timeIntervalSince(earlier.recordedAt) / 2
            )
            let daysAgo = Calendar.current.dateComponents(
                [.day],
                from: midpointDate,
                to: now
            ).day ?? 0

            // Exponential decay: weight = e^(-daysAgo / halfLife)
            let weight = exp(-Double(daysAgo) / recencyHalfLifeDays)

            weightedPaceSum += pace * weight
            weightSum += weight
        }

        // Return weighted average
        guard weightSum > 0 else { return nil }
        return weightedPaceSum / weightSum
    }

    /// Check if there's already a snapshot for today (for throttling)
    static func hasSnapshotToday(snapshots: [MileageSnapshot]) -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        return snapshots.contains { snapshot in
            calendar.startOfDay(for: snapshot.recordedAt) == today
        }
    }

    /// Calculate pace result with confidence level from snapshots
    /// - Parameter snapshots: Array of mileage snapshots
    /// - Returns: PaceResult with pace, confidence, and metadata, or nil if insufficient data
    static func calculatePaceResult(from snapshots: [MileageSnapshot]) -> PaceResult? {
        guard snapshots.count >= 2 else { return nil }

        // Sort by date ascending
        let sorted = snapshots.sorted { $0.recordedAt < $1.recordedAt }

        guard let oldest = sorted.first,
              let newest = sorted.last else { return nil }

        let calendar = Calendar.current
        let totalDaysBetween = calendar.dateComponents(
            [.day],
            from: oldest.recordedAt,
            to: newest.recordedAt
        ).day ?? 0

        // Require at least minimum days of data
        guard totalDaysBetween >= PaceResult.minimumDays else { return nil }

        // Calculate the pace using existing EWMA method
        guard let pace = calculateDailyPace(from: snapshots) else { return nil }

        // Determine confidence level based on data quality
        let snapshotCount = sorted.count
        let confidence: ConfidenceLevel

        if totalDaysBetween >= PaceResult.highConfidenceDays &&
           snapshotCount >= PaceResult.highConfidenceSnapshots {
            confidence = .high
        } else if totalDaysBetween >= PaceResult.mediumConfidenceDays &&
                  snapshotCount >= PaceResult.mediumConfidenceSnapshots {
            confidence = .medium
        } else {
            confidence = .low
        }

        let dateRange = DateInterval(start: oldest.recordedAt, end: newest.recordedAt)

        return PaceResult(
            milesPerDay: pace,
            confidence: confidence,
            dataPointCount: snapshotCount,
            dateRange: dateRange
        )
    }
}

// MARK: - Sample Data

extension MileageSnapshot {
    static func sampleSnapshots(for vehicle: Vehicle) -> [MileageSnapshot] {
        let calendar = Calendar.current
        var snapshots: [MileageSnapshot] = []

        // Create snapshots over 14 days showing ~40 miles/day pace
        for dayOffset in stride(from: 14, through: 0, by: -1) {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: .now) ?? .now
            let mileage = vehicle.currentMileage - (dayOffset * 40)

            let snapshot = MileageSnapshot(
                vehicle: vehicle,
                mileage: mileage,
                recordedAt: date,
                source: dayOffset == 0 ? .manual : .serviceCompletion
            )
            snapshots.append(snapshot)
        }

        return snapshots
    }
}
