//
//  DueServices.swift
//  checkpoint
//
//  What the due-date queries read: a vehicle's tracked services, most urgent
//  first, each with the status and due phrase every other surface shows —
//  judged against the vehicle's effective mileage (`MileageEstimate`), and
//  phrased by the widget's `dueDescription` so Siri, the widget and the Next
//  Up card say the same thing.
//

import Foundation
import SwiftData

/// One service as a query answers it. Sendable, so a snippet can hold it.
nonisolated struct DueServiceRow: Sendable, Identifiable {
    let service: ServiceEntity
    /// "Due mid May", "500 miles remaining" — already localized.
    let due: String

    var id: UUID { service.id }
    var name: String { service.name }
    var status: ServiceStatus { service.status }
}

@MainActor
enum DueServices {

    /// Services with a due date or mileage, most urgent first.
    static func upcoming(on vehicle: Vehicle) -> [DueServiceRow] {
        let estimate = vehicle.mileageEstimate
        return (vehicle.services ?? [])
            .filter(\.hasDueTracking)
            .sortedByUrgency(estimate)
            .map { row(for: $0, estimate: estimate) }
    }

    static func overdue(on vehicle: Vehicle) -> [DueServiceRow] {
        upcoming(on: vehicle).filter { $0.status == .overdue }
    }

    static func row(for service: Service, estimate: MileageEstimate) -> DueServiceRow {
        let effectiveDue = service.effectiveDueDate(currentMileage: estimate.effective, dailyPace: estimate.pace)
        return DueServiceRow(
            service: ServiceEntity(model: service),
            due: WidgetDataService.dueDescription(for: service, effectiveDue: effectiveDue)
        )
    }
}

/// Values formatted for speech. Everything a sentence splices in goes
/// through here, so dialogs use the app's own formatters and units.
@MainActor
enum SpokenValue {

    static func date(_ date: Date) -> String {
        Formatters.mediumDate.string(from: date)
    }

    /// Stored miles in the user's unit: "45,200 mi" or "72,742 km".
    static func mileage(_ miles: Int) -> String {
        Formatters.mileage(miles)
    }

    static func money(_ amount: Decimal) -> String {
        Formatters.currency.string(from: amount as NSDecimalNumber) ?? "\(amount)"
    }

    /// "A, B and C" / "A, B y C".
    static func list(_ items: [String]) -> String {
        ListFormatter.localizedString(byJoining: items)
    }

    /// When a reminder fires, or nil when it has neither a date nor a mileage.
    static func schedule(dueDate: Date?, dueMileage: Int?) -> String? {
        switch (dueDate, dueMileage) {
        case let (date?, miles?): return L10n.siriDueBoth(date: self.date(date), mileage: mileage(miles))
        case let (date?, nil): return L10n.siriDueDate(self.date(date))
        case let (nil, miles?): return L10n.siriDueMileage(mileage(miles))
        case (nil, nil): return nil
        }
    }
}
