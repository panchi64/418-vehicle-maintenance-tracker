//
//  L10n+Siri.swift
//  checkpoint
//
//  Spoken Siri responses assembled at run time. Keys are prefixed `siri.`.
//  Each status gets a whole sentence rather than a spliced-in verb phrase,
//  so languages that inflect differently can reorder freely.
//
//  Intent titles, parameter prompts, and fixed dialogs are
//  `LocalizedStringResource` literals translated directly in the catalog.
//
//  `nonisolated`: `SiriServiceStatus` and the intents' formatters are not
//  main-actor bound.
//

import Foundation

extension L10n {
    nonisolated private static func siri(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    // MARK: - Status words

    nonisolated static var siriStatusOverdue: String { siri("siri.status.overdue") }
    nonisolated static var siriStatusDueSoon: String { siri("siri.status.dueSoon") }
    nonisolated static var siriStatusComingUp: String { siri("siri.status.comingUp") }
    nonisolated static var siriStatusScheduled: String { siri("siri.status.scheduled") }

    // MARK: - Check Next Due

    /// "Oil change on Daily Driver is overdue. Due mid May." — service,
    /// vehicle, due description.
    nonisolated static func siriNextDue(_ status: SiriServiceStatus, service: String, vehicle: String, due: String) -> String {
        let key: String
        switch status {
        case .overdue: key = "siri.next.overdue"
        case .dueSoon: key = "siri.next.dueSoon"
        case .good: key = "siri.next.comingUp"
        case .neutral: key = "siri.next.scheduled"
        }
        return String(format: siri(key), service, vehicle, due)
    }

    // MARK: - List Upcoming Services

    /// "For Daily Driver, Oil change is overdue. Due mid May." — vehicle,
    /// service, due description.
    nonisolated static func siriSingle(_ status: SiriServiceStatus, vehicle: String, service: String, due: String) -> String {
        let key: String
        switch status {
        case .overdue: key = "siri.single.overdue"
        case .dueSoon: key = "siri.single.dueSoon"
        case .good: key = "siri.single.comingUp"
        case .neutral: key = "siri.single.scheduled"
        }
        return String(format: siri(key), vehicle, service, due)
    }

    /// "Here's what's coming up for Daily Driver: A. B. C." — vehicle, list.
    nonisolated static func siriListIntro(vehicle: String, list: String) -> String {
        String(format: siri("siri.list.intro"), vehicle, list)
    }
    nonisolated static func siriListItemOverdue(_ service: String) -> String {
        String(format: siri("siri.list.itemOverdue"), service)
    }
    /// "Oil change: due mid may" — service, due description.
    nonisolated static func siriListItem(_ service: String, due: String) -> String {
        String(format: siri("siri.list.item"), service, due)
    }
}
