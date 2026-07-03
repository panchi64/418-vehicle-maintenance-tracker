//
//  RecallAckState.swift
//  checkpoint
//
//  Mutation surface for `RecallAcknowledgment` records and the visibility
//  filter that decides which recalls show on Home. Views observe the
//  underlying SwiftData models via `@Query`; this file owns the writes
//  (setStatus, snooze, clearExpiredSnoozes) and the read-side filter.
//

import Foundation
import SwiftData
import os

private let recallAckLogger = Logger(category: "RecallAck")

/// Thin write API over `RecallAcknowledgment`. Constructed per-call with the
/// active `ModelContext` so it never holds long-lived SwiftData state.
@MainActor
struct RecallAckStore {
    let context: ModelContext

    /// Fetch every acknowledgment for a vehicle as a campaign-number-keyed dict.
    func acknowledgments(for vehicleID: UUID) -> [String: RecallAcknowledgment] {
        let descriptor = FetchDescriptor<RecallAcknowledgment>(
            predicate: #Predicate { $0.vehicleID == vehicleID }
        )
        let rows = (try? context.fetch(descriptor)) ?? []
        return Dictionary(rows.map { ($0.campaignNumber, $0) }, uniquingKeysWith: { lhs, _ in lhs })
    }

    /// Upsert + set status. Snooze is cleared whenever status changes (a
    /// scheduled recall isn't snoozed; reopening clears any prior snooze).
    @discardableResult
    func setStatus(
        _ status: RecallStatus,
        vehicleID: UUID,
        campaignNumber: String
    ) -> RecallAcknowledgment {
        let ack = upsert(vehicleID: vehicleID, campaignNumber: campaignNumber)
        ack.status = status
        ack.snoozedUntil = nil
        save()
        return ack
    }

    /// Snooze every non-park-it recall in the set for `days`. Returns the
    /// number of records snoozed. No-op (returns 0) if any recall is parkIt —
    /// safety overrides the user's preference here.
    @discardableResult
    func snooze(_ recalls: [RecallInfo], days: Int, vehicleID: UUID) -> Int {
        guard recalls.contains(where: { $0.parkIt }) == false else {
            recallAckLogger.info("Snooze refused: recall set contains parkIt entries")
            return 0
        }
        guard let until = Calendar.current.date(byAdding: .day, value: days, to: .now) else {
            return 0
        }
        let existing = acknowledgments(for: vehicleID)
        var count = 0
        for recall in recalls where !recall.parkIt {
            let ack = existing[recall.campaignNumber] ?? insertNew(
                vehicleID: vehicleID,
                campaignNumber: recall.campaignNumber
            )
            ack.snoozedUntil = until
            ack.updatedAt = .now
            count += 1
        }
        save()
        return count
    }

    /// Drop expired snoozes so the card reappears the moment the snooze elapses.
    func clearExpiredSnoozes(for vehicleID: UUID) {
        let now = Date.now
        let descriptor = FetchDescriptor<RecallAcknowledgment>(
            predicate: #Predicate { ack in
                ack.vehicleID == vehicleID && ack.snoozedUntil != nil
            }
        )
        let rows = (try? context.fetch(descriptor)) ?? []
        var changed = false
        for ack in rows where (ack.snoozedUntil ?? .distantFuture) <= now {
            ack.snoozedUntil = nil
            ack.updatedAt = .now
            changed = true
        }
        if changed { save() }
    }

    /// Persist pending changes, logging any failure instead of swallowing it.
    /// A dropped write here would silently desync a recall's acknowledged /
    /// snoozed state from what the user just chose.
    private func save() {
        do {
            try context.save()
        } catch {
            recallAckLogger.error("RecallAcknowledgment save failed: \(error.localizedDescription)")
        }
    }

    private func upsert(vehicleID: UUID, campaignNumber: String) -> RecallAcknowledgment {
        let descriptor = FetchDescriptor<RecallAcknowledgment>(
            predicate: #Predicate { ack in
                ack.vehicleID == vehicleID && ack.campaignNumber == campaignNumber
            }
        )
        if let existing = (try? context.fetch(descriptor))?.first {
            return existing
        }
        return insertNew(vehicleID: vehicleID, campaignNumber: campaignNumber)
    }

    private func insertNew(vehicleID: UUID, campaignNumber: String) -> RecallAcknowledgment {
        let new = RecallAcknowledgment(vehicleID: vehicleID, campaignNumber: campaignNumber)
        context.insert(new)
        return new
    }
}

/// Stateless visibility filter. Park-it recalls always show, regardless of
/// snooze or resolved status — safety override.
enum RecallVisibility {
    static func visibleRecalls(
        from recalls: [RecallInfo],
        acknowledgments: [String: RecallAcknowledgment],
        now: Date = .now
    ) -> [RecallInfo] {
        recalls.filter { recall in
            if recall.parkIt { return true }
            guard let ack = acknowledgments[recall.campaignNumber] else { return true }
            if ack.status == .resolved { return false }
            if let until = ack.snoozedUntil, until > now { return false }
            return true
        }
    }
}
