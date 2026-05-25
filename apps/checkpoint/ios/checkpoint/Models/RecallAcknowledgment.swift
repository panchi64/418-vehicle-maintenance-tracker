//
//  RecallAcknowledgment.swift
//  checkpoint
//
//  Per-recall user state (open / scheduled / resolved + snooze) keyed by
//  vehicleID + NHTSA campaign number. Persisted via SwiftData so
//  acknowledgements survive relaunch and follow each vehicle.
//

import Foundation
import SwiftData

enum RecallStatus: String, Codable, CaseIterable, Sendable {
    case open
    case scheduled
    case resolved
}

@Model
final class RecallAcknowledgment: Identifiable {
    var id: UUID = UUID()
    var vehicleID: UUID = UUID()
    var campaignNumber: String = ""
    private var statusRaw: String = RecallStatus.open.rawValue
    var snoozedUntil: Date?
    var updatedAt: Date = Date.now

    var status: RecallStatus {
        get { RecallStatus(rawValue: statusRaw) ?? .open }
        set {
            statusRaw = newValue.rawValue
            updatedAt = .now
        }
    }

    init(
        vehicleID: UUID,
        campaignNumber: String,
        status: RecallStatus = .open,
        snoozedUntil: Date? = nil
    ) {
        self.id = UUID()
        self.vehicleID = vehicleID
        self.campaignNumber = campaignNumber
        self.statusRaw = status.rawValue
        self.snoozedUntil = snoozedUntil
        self.updatedAt = .now
    }

    /// True when a non-park-it recall is currently snoozed (snoozedUntil in the future).
    var isActivelySnoozed: Bool {
        guard let until = snoozedUntil else { return false }
        return until > .now
    }
}
