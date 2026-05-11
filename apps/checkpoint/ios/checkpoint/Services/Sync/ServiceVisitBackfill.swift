//
//  ServiceVisitBackfill.swift
//  checkpoint
//
//  One-time backfill that converts the legacy "divide cluster total by N
//  services" data into Service Visits.
//
//  Why this lives here and not as a SwiftData SchemaMigrationPlan:
//  the app shipped without VersionedSchema, so introducing one for the first
//  migration is risky — SwiftData has to recognize existing on-disk stores as
//  "V1" and that's not guaranteed when the previous shipped binary used
//  lightweight automatic migration. A plain idempotent backfill in regular
//  Swift, gated by a UserDefaults flag, achieves the same user outcome with
//  far less risk and is easier to test.
//
//  Algorithm:
//    1. Fetch all ServiceLogs that have no parent visit.
//    2. Group by (vehicle.id, day-truncated performedDate, mileageAtService).
//    3. Skip groups of size 1 — those are real standalone logs.
//    4. For each group of size ≥ 2:
//         - Sum non-nil .cost values into impliedTotal (visit.totalCost).
//         - Pick mode of non-nil .costCategory as visit.costCategory.
//         - Create ServiceVisit(isItemized: false, ...).
//         - Re-parent each log to the visit; blank log.cost and log.costCategory.
//    5. Save the context once at the end.
//

import Foundation
import SwiftData
import os

private let backfillLogger = Logger(subsystem: "com.418-studio.checkpoint", category: "ServiceVisitBackfill")

enum ServiceVisitBackfill {
    /// UserDefaults flag — bumped by suffix when we iterate the algorithm.
    private static let completionFlagKey = "checkpoint.serviceVisitBackfill.v1.completed"

    /// Runs the backfill once per device. No-ops on subsequent launches.
    /// Safe to call repeatedly; safe to call before any user data exists.
    @MainActor
    static func runIfNeeded(context: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: completionFlagKey) else { return }

        do {
            try perform(context: context)
            UserDefaults.standard.set(true, forKey: completionFlagKey)
            backfillLogger.info("ServiceVisit backfill completed.")
        } catch {
            backfillLogger.error("ServiceVisit backfill failed: \(error.localizedDescription). Will retry on next launch.")
        }
    }

    /// Perform the backfill. Exposed for tests.
    @MainActor
    static func perform(context: ModelContext) throws {
        // #Predicate against an optional to-one relationship can fail to compile
        // on some SwiftData versions, so we filter in-memory instead. Acceptable
        // because this runs once per device on a small dataset.
        let allFetched = try context.fetch(FetchDescriptor<ServiceLog>())
        let allLogs = allFetched.filter { $0.visit == nil }

        // Group by (vehicleID, startOfDay(performedDate), mileageAtService).
        // Logs without a vehicle are left alone (defensive — not expected in
        // current code paths).
        let calendar = Calendar.current
        struct GroupKey: Hashable {
            let vehicleID: UUID
            let day: Date
            let mileage: Int
        }

        var groups: [GroupKey: [ServiceLog]] = [:]
        for log in allLogs {
            guard let vehicleID = log.vehicle?.id else { continue }
            let day = calendar.startOfDay(for: log.performedDate)
            let key = GroupKey(vehicleID: vehicleID, day: day, mileage: log.mileageAtService)
            groups[key, default: []].append(log)
        }

        var createdVisits = 0
        for (_, logs) in groups where logs.count >= 2 {
            // Recover implied total. nil only when every log in the group has nil cost.
            let costs = logs.compactMap { $0.cost }
            let impliedTotal: Decimal? = costs.isEmpty ? nil : costs.reduce(Decimal.zero, +)

            // Pick the mode category among non-nil values; tiebreak by .maintenance.
            let categories = logs.compactMap { $0.costCategory }
            let visitCategory = mode(of: categories) ?? (impliedTotal != nil ? .maintenance : nil)

            // First non-empty notes survives as the visit-level note. Per-log
            // notes that differ stay on each log unchanged.
            let visitNotes = logs.compactMap { $0.notes }.first { !$0.isEmpty }

            // Anchor the visit to the first log's date and mileage (they're
            // identical within the group by construction).
            let anchor = logs[0]
            let visit = ServiceVisit(
                vehicle: anchor.vehicle,
                performedDate: anchor.performedDate,
                mileageAtVisit: anchor.mileageAtService,
                totalCost: impliedTotal,
                costCategory: visitCategory,
                isItemized: false,
                shopName: nil,
                notes: visitNotes
            )
            context.insert(visit)

            for log in logs {
                log.visit = visit
                log.cost = nil
                log.costCategory = nil
            }
            createdVisits += 1
        }

        if context.hasChanges {
            try context.save()
        }
        backfillLogger.info("Backfill scanned \(allLogs.count) logs and created \(createdVisits) Service Visits.")
    }

    /// Reset the completion flag. Test-only helper; not used at runtime.
    static func resetForTests() {
        UserDefaults.standard.removeObject(forKey: completionFlagKey)
    }
}

/// Most-common element. Returns nil when input is empty.
private func mode<T: Hashable>(of values: [T]) -> T? {
    var counts: [T: Int] = [:]
    for v in values { counts[v, default: 0] += 1 }
    return counts.max(by: { $0.value < $1.value })?.key
}
