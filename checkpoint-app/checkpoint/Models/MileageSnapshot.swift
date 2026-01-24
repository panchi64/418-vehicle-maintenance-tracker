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

// MARK: - Pace Calculation Helpers

extension MileageSnapshot {
    /// Calculate daily miles pace from an array of snapshots
    /// Requires at least 7 days of data to return a meaningful pace
    static func calculateDailyPace(from snapshots: [MileageSnapshot]) -> Double? {
        guard snapshots.count >= 2 else { return nil }

        // Sort by date ascending
        let sorted = snapshots.sorted { $0.recordedAt < $1.recordedAt }

        guard let oldest = sorted.first,
              let newest = sorted.last else { return nil }

        let daysBetween = Calendar.current.dateComponents(
            [.day],
            from: oldest.recordedAt,
            to: newest.recordedAt
        ).day ?? 0

        // Require at least 7 days of data for meaningful pace
        guard daysBetween >= 7 else { return nil }

        let milesDriven = newest.mileage - oldest.mileage
        guard milesDriven > 0 else { return nil }

        return Double(milesDriven) / Double(daysBetween)
    }

    /// Check if there's already a snapshot for today (for throttling)
    static func hasSnapshotToday(snapshots: [MileageSnapshot]) -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        return snapshots.contains { snapshot in
            calendar.startOfDay(for: snapshot.recordedAt) == today
        }
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
