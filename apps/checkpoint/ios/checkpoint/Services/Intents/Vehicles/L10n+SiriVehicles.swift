//
//  L10n+SiriVehicles.swift
//  checkpoint
//
//  Siri sentences for the vehicle intents: Add Vehicle, Get Vehicle Details,
//  the marbete, and recalls. Same rules as `L10n+Siri`: whole sentences,
//  `siri.` keys, values formatted by the caller.
//

import Foundation

extension L10n {

    // MARK: - Add Vehicle

    /// "Add 2020 Honda Civic to Checkpoint with the usual maintenance
    /// schedule, like Oil Change and Tire Rotation?" — vehicle, two services.
    nonisolated static func siriVehicleScheduleAsk(vehicle: String, first: String, second: String) -> String {
        siri("siri.vehicle.scheduleAsk", vehicle, first, second)
    }
    /// "Added 2020 Honda Civic to Checkpoint, with its maintenance schedule."
    nonisolated static func siriVehicleAddedWithSchedule(_ vehicle: String) -> String {
        siri("siri.vehicle.addedWithSchedule", vehicle)
    }

    // MARK: - Vehicle details

    /// "Daily Driver's license plate is ABC-123." — vehicle, value.
    nonisolated static func siriDetail(_ detail: VehicleDetail, vehicle: String, value: String) -> String {
        siri("siri.detail.\(detail.rawValue)", vehicle, value)
    }
    /// "Checkpoint doesn't have Daily Driver's VIN. Add it in Edit Vehicle."
    nonisolated static func siriDetailMissing(_ detail: VehicleDetail, vehicle: String) -> String {
        siri("siri.detail.missing.\(detail.rawValue)", vehicle)
    }
    /// "Oil: 0W-20." — one fact in the everything-on-file answer.
    nonisolated static func siriDetailFact(_ detail: VehicleDetail, value: String) -> String {
        siri("siri.detail.fact.\(detail.rawValue)", value)
    }
    /// "Here's what Checkpoint has for Daily Driver. Oil: 0W-20. …" —
    /// vehicle, facts.
    nonisolated static func siriDetailSummary(vehicle: String, facts: String) -> String {
        siri("siri.detail.summary", vehicle, facts)
    }
    nonisolated static func siriDetailNothing(vehicle: String) -> String {
        siri("siri.detail.nothing", vehicle)
    }

    // MARK: - Marbete

    /// "Daily Driver's marbete expired at the end of March 2026. …"
    nonisolated static func siriMarbeteExpired(vehicle: String, month: String) -> String {
        siri("siri.marbete.expired", vehicle, month)
    }
    /// "Mark Daily Driver's marbete renewed through March 2027?"
    nonisolated static func siriMarbeteRenewConfirm(vehicle: String, month: String) -> String {
        siri("siri.marbete.renewConfirm", vehicle, month)
    }
    /// "Done. Daily Driver's marbete now runs through March 2027."
    nonisolated static func siriMarbeteRenewed(vehicle: String, month: String) -> String {
        siri("siri.marbete.renewed", vehicle, month)
    }

    // MARK: - Recalls

    nonisolated static func siriRecallsNone(vehicle: String) -> String {
        siri("siri.recalls.none", vehicle)
    }
    /// "Daily Driver has an open recall: Air Bags." — vehicle, component.
    nonisolated static func siriRecallsOne(vehicle: String, component: String) -> String {
        siri("siri.recalls.one", vehicle, component)
    }
    /// "Daily Driver has 2 open recalls: Air Bags and Fuel Pump." — vehicle,
    /// count, list.
    nonisolated static func siriRecallsMany(vehicle: String, count: Int, list: String) -> String {
        siri("siri.recalls.many", vehicle, count, list)
    }
    /// The recall sentence, then NHTSA's advice not to drive it.
    nonisolated static func siriRecallsParkIt(_ sentence: String) -> String {
        siri("siri.recalls.parkIt", sentence)
    }
    /// The recall sentence, then the offer — "Add it as a planned service?"
    /// or "Add them as planned services?".
    nonisolated static func siriRecallsOfferPlan(summary: String, count: Int) -> String {
        count == 1
            ? siri("siri.recalls.offerOne", summary)
            : siri("siri.recalls.offerMany", summary)
    }
    nonisolated static var siriRecallsNotPlanned: String { siri("siri.recalls.notPlanned") }
    /// "Added a planned service for Daily Driver's recall." / "Added 2 …".
    /// Zero: every one was already on the schedule by name.
    nonisolated static func siriRecallsPlanned(count: Int, vehicle: String) -> String {
        switch count {
        case 0: return siri("siri.recalls.plannedNone", vehicle)
        case 1: return siri("siri.recalls.plannedOne", vehicle)
        default: return siri("siri.recalls.plannedMany", count, vehicle)
        }
    }

    // MARK: - Snippet labels

    /// "2 open recalls", "No open recalls".
    nonisolated static func siriSnippetRecallCount(_ count: Int) -> String {
        switch count {
        case 0: return siri("siri.snippet.recallsNone")
        case 1: return siri("siri.snippet.recallsOne")
        default: return siri("siri.snippet.recallsMany", count)
        }
    }
    nonisolated static var siriSnippetPlanned: String { siri("siri.snippet.planned") }
}
