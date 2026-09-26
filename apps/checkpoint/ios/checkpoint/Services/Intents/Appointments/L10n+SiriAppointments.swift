//
//  L10n+SiriAppointments.swift
//  checkpoint
//
//  Siri sentences for shop appointments and vehicle notes. Same rules as
//  `L10n+Siri`: whole sentences, `siri.` keys, values formatted by the caller.
//

import Foundation

extension L10n {

    // MARK: - Appointments

    /// "Booked Daily Driver at Firestone on Oct 3, 2026 at 9:30 AM." —
    /// vehicle, shop, date, time.
    nonisolated static func siriAppointmentBooked(vehicle: String, shop: String, date: String, time: String) -> String {
        siri("siri.appointment.booked", vehicle, shop, date, time)
    }
    /// "Moved Daily Driver's Firestone appointment to Oct 4, 2026 at 10:00 AM."
    nonisolated static func siriAppointmentMoved(vehicle: String, shop: String, date: String, time: String) -> String {
        siri("siri.appointment.moved", vehicle, shop, date, time)
    }
    /// "Cancel Daily Driver's Firestone appointment on Oct 3, 2026 at 9:30 AM?"
    nonisolated static func siriAppointmentCancelAsk(vehicle: String, shop: String, date: String, time: String) -> String {
        siri("siri.appointment.cancelAsk", vehicle, shop, date, time)
    }
    /// "Cancelled Daily Driver's Firestone appointment."
    nonisolated static func siriAppointmentCancelled(vehicle: String, shop: String) -> String {
        siri("siri.appointment.cancelled", vehicle, shop)
    }

    // MARK: - Notes

    /// "Saved a note to Daily Driver."
    nonisolated static func siriNoteSaved(vehicle: String) -> String {
        siri("siri.note.saved", vehicle)
    }
    /// "Saved a pinned note to Daily Driver."
    nonisolated static func siriNotePinnedSaved(vehicle: String) -> String {
        siri("siri.note.savedPinned", vehicle)
    }
    /// "Paint code, on Daily Driver: NH-731P Nighthawk Black."
    nonisolated static func siriNoteFound(title: String, vehicle: String, text: String) -> String {
        siri("siri.note.found", title, vehicle, text)
    }
    /// "Here's Paint code, on Daily Driver." — for a note with no text beyond
    /// its title.
    nonisolated static func siriNoteFoundTitleOnly(title: String, vehicle: String) -> String {
        siri("siri.note.foundTitleOnly", title, vehicle)
    }
}
