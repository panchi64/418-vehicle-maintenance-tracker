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
    /// each backfill is idempotent.
    @MainActor
    static func runPostLaunchBackfills(in context: ModelContext) {
        backfillIsRecurring(in: context)
        backfillDocumentVehicles(in: context)
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

    /// Populate `ServiceAttachment.vehicles` for existing rows. Before the
    /// Documents library, attachments only knew about their service log; the
    /// vehicle link was derived through that log. The new library views by
    /// vehicle, so each attachment needs a direct vehicle reference.
    ///
    /// Runs on every launch (no UserDefaults gate) because CloudKit-synced
    /// rows can arrive at any time after first launch on a new device. A
    /// per-device flag would set itself before iCloud delivered anything and
    /// permanently lock those rows out of the Documents library. The
    /// per-launch cost is bounded by the number of attachments with empty
    /// vehicles (typically zero after the first run).
    @MainActor
    private static func backfillDocumentVehicles(in context: ModelContext) {
        do {
            let descriptor = FetchDescriptor<ServiceAttachment>()
            let attachments = try context.fetch(descriptor)
            var updated = 0
            for attachment in attachments where (attachment.vehicles?.isEmpty ?? true) {
                if let vehicle = attachment.serviceLog?.vehicle {
                    attachment.vehicles = [vehicle]
                    updated += 1
                }
            }
            if updated > 0 {
                try context.save()
                migrationLogger.info("Document-vehicle backfill linked \(updated) attachments")
            }
        } catch {
            migrationLogger.error("Document-vehicle backfill failed: \(error.localizedDescription)")
        }
    }
}
