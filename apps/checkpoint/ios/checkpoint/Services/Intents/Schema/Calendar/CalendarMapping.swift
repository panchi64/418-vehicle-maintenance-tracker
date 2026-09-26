//
//  CalendarMapping.swift
//  checkpoint
//
//  How an appointment's fields map onto the Calendar schema and back. Pure
//  values in, values out, so the mapping is tested without Siri.
//
//  - title ⇄ shop name. Siri may say "oil change at Firestone": a place's
//    common name wins as the shop when there is one, and tracked service
//    names found in the title link those services.
//  - note ⇄ note, with the linked services on a last line ("Services: …").
//  - status: scheduled → confirmed, cancelled → cancelled; a completed visit
//    stays confirmed (it happened).
//  - alarms: the reminders' fire dates (`Appointment.reminderDates`).
//

import Foundation
import GeoToolbox

@available(iOS 27, *)
enum CalendarMapping {

    static func status(_ status: AppointmentStatus) -> AppointmentEventStatus {
        switch status {
        case .scheduled, .completed: .confirmed
        case .cancelled: .cancelled
        }
    }

    /// The event note: the appointment's note, then the services line.
    nonisolated static func note(note: String?, serviceNames: [String]) -> String? {
        var parts: [String] = []
        if let note, !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { parts.append(note) }
        if !serviceNames.isEmpty {
            parts.append(L10n.appointmentEventServicesLine(ListFormatter.localizedString(byJoining: serviceNames)))
        }
        return parts.isEmpty ? nil : parts.joined(separator: "\n")
    }

    @MainActor
    static func alarmDates(for appointment: Appointment) -> [Date] {
        guard appointment.isScheduled else { return [] }
        // Every lead, past or not: an event's alarms describe it, they
        // aren't a to-do list.
        return Appointment.ReminderLead.allCases
            .map { appointment.startDate.addingTimeInterval(-$0.interval) }
    }

    /// The shop a schema title and location name.
    nonisolated static func shopName(title: String, location: AppointmentLocation?) -> String {
        if case .place(let place) = location,
           let name = place.commonName?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
            return name
        }
        return title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The address and coordinate a schema location carries.
    nonisolated static func place(from location: AppointmentLocation?) -> (address: String, latitude: Double?, longitude: Double?) {
        switch location {
        case .place(let place):
            return (place.address ?? "", place.coordinate?.latitude, place.coordinate?.longitude)
        case .address(let address):
            return (address, nil, nil)
        case nil:
            return ("", nil, nil)
        }
    }

    /// Tracked services whose names appear in `title`, so "oil change and
    /// tire rotation at Firestone" links both.
    @MainActor
    static func services(namedIn title: String, on vehicle: Vehicle) -> [Service] {
        (vehicle.services ?? []).filter { service in
            let name = service.name.trimmingCharacters(in: .whitespacesAndNewlines)
            return !name.isEmpty && title.localizedStandardContains(name)
        }
    }

    /// The appointment fields a `createEvent` describes.
    @MainActor
    static func fields(
        title: String,
        startDate: Date,
        endDate: Date?,
        location: AppointmentLocation?,
        note: String?,
        on vehicle: Vehicle
    ) -> AppointmentFields {
        let place = place(from: location)
        return AppointmentFields(
            shopName: shopName(title: title, location: location),
            startDate: startDate,
            endDate: endDate,
            address: place.address,
            latitude: place.latitude,
            longitude: place.longitude,
            note: note ?? "",
            serviceIDs: services(namedIn: title, on: vehicle).map(\.id)
        )
    }
}
