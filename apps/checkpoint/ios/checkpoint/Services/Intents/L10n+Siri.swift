//
//  L10n+Siri.swift
//  checkpoint
//
//  Spoken Siri responses and snippet labels assembled at run time. Keys are
//  prefixed `siri.`. Each outcome gets a whole sentence rather than a
//  spliced-in phrase, so languages that inflect differently can reorder
//  freely. Values (names, dates, mileage, money) are formatted by the caller
//  with the app's formatters before they reach a sentence.
//
//  Intent titles, parameter prompts, and fixed dialogs are
//  `LocalizedStringResource` literals translated directly in the catalog.
//  App Shortcut phrases live in `AppShortcuts.xcstrings`.
//
//  `nonisolated`: `ServiceStatus` and the formatters calling these are not
//  main-actor bound.
//

import Foundation

extension L10n {
    nonisolated private static func siri(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    nonisolated private static func siri(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: siri(key), arguments: arguments)
    }

    // MARK: - Next due / upcoming

    /// "Oil change on Daily Driver is overdue. Due mid May." — service,
    /// vehicle, due description.
    nonisolated static func siriNextDue(_ status: ServiceStatus, service: String, vehicle: String, due: String) -> String {
        siri("siri.next.\(statusKey(status))", service, vehicle, due)
    }

    /// "For Daily Driver, Oil change is overdue. Due mid May." — vehicle,
    /// service, due description.
    nonisolated static func siriSingle(_ status: ServiceStatus, vehicle: String, service: String, due: String) -> String {
        siri("siri.single.\(statusKey(status))", vehicle, service, due)
    }

    /// "Here's what's coming up for Daily Driver: A. B. C." — vehicle, list.
    nonisolated static func siriListIntro(vehicle: String, list: String) -> String {
        siri("siri.list.intro", vehicle, list)
    }
    nonisolated static func siriListItemOverdue(_ service: String) -> String {
        siri("siri.list.itemOverdue", service)
    }
    /// "Oil change: due mid may" — service, due description.
    nonisolated static func siriListItem(_ service: String, due: String) -> String {
        siri("siri.list.item", service, due)
    }
    /// "No services are scheduled for Daily Driver."
    nonisolated static func siriNothingScheduled(vehicle: String) -> String {
        siri("siri.list.none", vehicle)
    }

    nonisolated private static func statusKey(_ status: ServiceStatus) -> String {
        switch status {
        case .overdue: return "overdue"
        case .dueSoon: return "dueSoon"
        case .good: return "comingUp"
        case .neutral: return "scheduled"
        }
    }

    // MARK: - Overdue

    nonisolated static func siriOverdueNone(vehicle: String) -> String {
        siri("siri.overdue.none", vehicle)
    }
    /// "Oil Change is overdue on Daily Driver." — service, vehicle.
    nonisolated static func siriOverdueOne(service: String, vehicle: String) -> String {
        siri("siri.overdue.one", service, vehicle)
    }
    /// "3 services are overdue on Daily Driver: A, B and C." — count,
    /// vehicle, list.
    nonisolated static func siriOverdueMany(count: Int, vehicle: String, list: String) -> String {
        siri("siri.overdue.many", count, vehicle, list)
    }

    // MARK: - Last service

    /// "You last did Oil Change on Daily Driver on May 3, 2026, at 45,200 mi."
    /// — service, vehicle, date, mileage.
    nonisolated static func siriLastService(service: String, vehicle: String, date: String, mileage: String) -> String {
        siri("siri.last.found", service, vehicle, date, mileage)
    }
    /// "I couldn't find oil in Daily Driver's history." — search, vehicle.
    nonisolated static func siriLastServiceNone(search: String, vehicle: String) -> String {
        siri("siri.last.none", search, vehicle)
    }

    // MARK: - Mileage

    /// "Daily Driver is now at 45,200 mi." — vehicle, mileage.
    nonisolated static func siriMileageUpdated(vehicle: String, mileage: String) -> String {
        siri("siri.mileage.updated", vehicle, mileage)
    }
    /// Confirmation for a reading below the one on file — vehicle, mileage on
    /// file, spoken reading.
    nonisolated static func siriMileageConfirmLower(vehicle: String, current: String, reading: String) -> String {
        siri("siri.mileage.confirmLower", vehicle, current, reading)
    }
    /// Confirmation for an unusual jump — increase, vehicle, mileage on
    /// file, spoken reading.
    nonisolated static func siriMileageConfirmJump(increase: String, vehicle: String, current: String, reading: String) -> String {
        siri("siri.mileage.confirmJump", increase, vehicle, current, reading)
    }
    /// "Daily Driver is at 45,200 mi." — a reading with no date.
    nonisolated static func siriMileageCurrent(vehicle: String, mileage: String) -> String {
        siri("siri.mileage.current", vehicle, mileage)
    }
    /// "Daily Driver was at 45,200 mi on May 3." — vehicle, mileage, date.
    nonisolated static func siriMileageRecorded(vehicle: String, mileage: String, date: String) -> String {
        siri("siri.mileage.recorded", vehicle, mileage, date)
    }
    /// Estimate plus pace — vehicle, estimate, daily pace, last reading, date.
    nonisolated static func siriMileageEstimated(vehicle: String, estimate: String, pace: String, recorded: String, date: String) -> String {
        siri("siri.mileage.estimated", vehicle, estimate, pace, recorded, date)
    }
    nonisolated static func siriMileageNone(vehicle: String) -> String {
        siri("siri.mileage.none", vehicle)
    }

    // MARK: - Mark done / log

    /// "Mark Oil Change done on Daily Driver?" — service, vehicle.
    nonisolated static func siriDoneConfirm(service: String, vehicle: String) -> String {
        siri("siri.done.confirm", service, vehicle)
    }
    /// "Marked Oil Change done on Daily Driver." — service, vehicle.
    nonisolated static func siriDoneSaved(service: String, vehicle: String) -> String {
        siri("siri.done.saved", service, vehicle)
    }
    /// "Oil Change isn't on the schedule for Daily Driver. Log it instead."
    nonisolated static func siriDoneNotTracked(service: String, vehicle: String) -> String {
        siri("siri.done.notTracked", service, vehicle)
    }
    /// "Log Oil Change and Tire Rotation on Daily Driver?" — list, vehicle.
    nonisolated static func siriLogConfirm(services: String, vehicle: String) -> String {
        siri("siri.log.confirm", services, vehicle)
    }
    /// "Logged Oil Change and Tire Rotation on Daily Driver." — list, vehicle.
    nonisolated static func siriLogSaved(services: String, vehicle: String) -> String {
        siri("siri.log.saved", services, vehicle)
    }
    /// "Marked Oil Change done on Daily Driver. Next due May 12, 2027." —
    /// service, vehicle, the next reminder the completion left.
    nonisolated static func siriDoneSaved(service: String, vehicle: String, nextDue: String) -> String {
        siri("siri.done.savedNext", service, vehicle, nextDue)
    }

    // MARK: - Schedule phrases

    /// "May 12, 2027" — when a reminder fires by date.
    nonisolated static func siriDueDate(_ date: String) -> String {
        siri("siri.due.date", date)
    }
    /// "at 50,000 mi" — when a reminder fires by mileage.
    nonisolated static func siriDueMileage(_ mileage: String) -> String {
        siri("siri.due.mileage", mileage)
    }
    /// "May 12, 2027 or at 50,000 mi, whichever comes first".
    nonisolated static func siriDueBoth(date: String, mileage: String) -> String {
        siri("siri.due.both", date, mileage)
    }

    // MARK: - Add / edit / snooze / stop / delete

    /// "Added Oil Change to Daily Driver, due May 12, 2027." — service,
    /// vehicle, due phrase.
    nonisolated static func siriAddSaved(service: String, vehicle: String, due: String) -> String {
        siri("siri.add.saved", service, vehicle, due)
    }
    /// "Oil Change is already on the schedule for Daily Driver, due …."
    nonisolated static func siriAddExists(service: String, vehicle: String, due: String) -> String {
        siri("siri.add.exists", service, vehicle, due)
    }
    /// "Updated Oil Change. It's due May 12, 2027." — service, due phrase.
    nonisolated static func siriEditSaved(service: String, due: String) -> String {
        siri("siri.edit.saved", service, due)
    }
    /// "Updated Oil Change. It isn't scheduled." — service.
    nonisolated static func siriEditSavedUnscheduled(service: String) -> String {
        siri("siri.edit.savedUnscheduled", service)
    }
    nonisolated static func siriSnoozeSaved(service: String) -> String {
        siri("siri.snooze.saved", service)
    }
    nonisolated static func siriSnoozeNotDue(service: String) -> String {
        siri("siri.snooze.notDue", service)
    }
    nonisolated static func siriStopConfirm(service: String, vehicle: String) -> String {
        siri("siri.stop.confirm", service, vehicle)
    }
    nonisolated static func siriStopSaved(service: String) -> String {
        siri("siri.stop.saved", service)
    }
    nonisolated static func siriStopNotTracked(service: String) -> String {
        siri("siri.stop.notTracked", service)
    }
    nonisolated static func siriDeleteServiceConfirm(_ names: [String]) -> String {
        names.count == 1
            ? siri("siri.deleteService.confirmOne", names[0])
            : siri("siri.deleteService.confirmMany", names.count)
    }
    nonisolated static func siriDeleteServiceDone(_ names: [String]) -> String {
        names.count == 1
            ? siri("siri.deleteService.doneOne", names[0])
            : siri("siri.deleteService.doneMany", names.count)
    }
    /// One entry: service, date. Several: count.
    nonisolated static func siriDeleteLogConfirm(count: Int, service: String, date: String) -> String {
        count == 1
            ? siri("siri.deleteLog.confirmOne", service, date)
            : siri("siri.deleteLog.confirmMany", count)
    }
    nonisolated static func siriDeleteLogDone(count: Int, service: String, date: String) -> String {
        count == 1
            ? siri("siri.deleteLog.doneOne", service, date)
            : siri("siri.deleteLog.doneMany", count)
    }

    // MARK: - Reminders, Photos (iOS 27 schemas)

    /// "Due at 50,000 mi" — a reminder note's due-mileage line.
    nonisolated static func siriReminderNoteDue(_ mileage: String) -> String {
        siri("siri.reminder.noteDue", mileage)
    }
    /// "Every 5,000 mi" — a reminder note's interval line.
    nonisolated static func siriReminderNoteEvery(_ mileage: String) -> String {
        siri("siri.reminder.noteEvery", mileage)
    }
    /// "Added Weekend Car to Checkpoint." — vehicle.
    nonisolated static func siriVehicleAdded(_ vehicle: String) -> String {
        siri("siri.vehicle.added", vehicle)
    }
    /// "Saved the photo to Daily Driver's documents." / "Saved 3 photos …".
    nonisolated static func siriPhotosSaved(count: Int, vehicle: String) -> String {
        count == 1
            ? siri("siri.photos.savedOne", vehicle)
            : siri("siri.photos.savedMany", count, vehicle)
    }

    // MARK: - Spending

    /// "You've spent $1,234 on Daily Driver — Year to Date." — amount,
    /// vehicle, period.
    nonisolated static func siriSpending(amount: String, vehicle: String, period: String) -> String {
        siri("siri.spend.total", amount, vehicle, period)
    }
    /// With a category — amount, vehicle, category, period.
    nonisolated static func siriSpending(amount: String, vehicle: String, category: String, period: String) -> String {
        siri("siri.spend.category", amount, vehicle, category, period)
    }

    // MARK: - Receipts

    /// "Log Oil Change on Daily Driver from this receipt?" — list, vehicle.
    nonisolated static func siriReceiptConfirm(services: String, vehicle: String) -> String {
        siri("siri.receipt.confirm", services, vehicle)
    }
    /// "Logged Oil Change on Daily Driver from the receipt." — list, vehicle.
    nonisolated static func siriReceiptSaved(services: String, vehicle: String) -> String {
        siri("siri.receipt.saved", services, vehicle)
    }

    // MARK: - Snippet labels

    nonisolated static var siriSnippetDate: String { siri("siri.snippet.date") }
    nonisolated static var siriSnippetOdometer: String { siri("siri.snippet.odometer") }
    nonisolated static var siriSnippetCost: String { siri("siri.snippet.cost") }
    nonisolated static var siriSnippetShop: String { siri("siri.snippet.shop") }
    nonisolated static var siriSnippetDone: String { siri("siri.snippet.done") }
    nonisolated static var siriSnippetNothingDue: String { siri("siri.snippet.nothingDue") }
    nonisolated static var siriSnippetExpenses: String { siri("siri.snippet.expenses") }
    /// "Daily Driver · Year to Date" — vehicle, period.
    nonisolated static func siriSnippetCaption(vehicle: String, period: String) -> String {
        siri("siri.snippet.caption", vehicle, period)
    }
}
