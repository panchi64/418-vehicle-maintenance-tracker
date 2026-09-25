//
//  Service+DueLine.swift
//  checkpoint
//
//  "Due 32,500 mi or Oct 4" — both triggers, whichever comes first. Shared by
//  `ServiceRow` and the Service Detail hero so the two can't word it apart.
//

import Foundation

extension Service {
    @MainActor
    var dueLine: String {
        let mileage = dueMileage.map { Formatters.mileage($0) }
        let date = dueDate.map { $0.formatted(.dateTime.month(.abbreviated).day()) }
        switch (mileage, date) {
        case let (mileage?, date?): return L10n.servicesRowDueEither(mileage, date)
        case let (mileage?, nil): return L10n.servicesRowDue(mileage)
        case let (nil, date?): return L10n.servicesRowDue(date)
        case (nil, nil): return L10n.rowNoDueDate
        }
    }
}
