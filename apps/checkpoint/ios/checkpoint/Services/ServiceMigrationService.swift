//
//  ServiceMigrationService.swift
//  checkpoint
//
//  One-time post-launch backfills that mutate existing user data to match
//  current model semantics. Each backfill is idempotent and gated by a
//  UserDefaults key so it runs exactly once per device.
//

import Foundation
import SwiftData
import os

private let migrationLogger = Logger(category: "ServiceMigration")

struct ServiceMigrationService {

    private static let recurringBackfillKey = "recurringBackfillV1Completed"

    /// Run any pending post-launch backfills. Safe to call on every launch —
    /// each backfill checks its own completion flag.
    @MainActor
    static func runPostLaunchBackfills(in context: ModelContext) {
        backfillIsRecurring(in: context)
    }

    /// Flip `isRecurring = true` for any Service that has a non-zero interval.
    ///
    /// Pre-refactor, recurrence was implicit (any Service with intervals
    /// auto-recurred). The new model makes recurrence explicit via the
    /// `isRecurring` flag. Without this backfill, existing user data would
    /// silently become one-shot after the first completion post-upgrade.
    @MainActor
    private static func backfillIsRecurring(in context: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: recurringBackfillKey) else { return }

        do {
            // Scope the fetch to candidates only so the launch cost is bounded
            // by service-with-interval count, not the whole table.
            let predicate = #Predicate<Service> { service in
                !service.isRecurring &&
                ((service.intervalMonths ?? 0) > 0 || (service.intervalMiles ?? 0) > 0)
            }
            let candidates = try context.fetch(FetchDescriptor<Service>(predicate: predicate))
            for service in candidates {
                service.isRecurring = true
            }
            if !candidates.isEmpty {
                try context.save()
                migrationLogger.info("Recurring backfill flipped \(candidates.count) services")
            }
            UserDefaults.standard.set(true, forKey: recurringBackfillKey)
        } catch {
            migrationLogger.error("Recurring backfill failed: \(error.localizedDescription)")
        }
    }
}
