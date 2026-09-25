//
//  ServiceLogFormModel+Edit.swift
//  checkpoint
//
//  The edit door: loading a history entry, telling whether Save would change
//  it, and the reminder a date/mileage edit can move (F9).
//

import Foundation

extension ServiceLogFormModel {

    func loadForEdit(_ log: ServiceLog) {
        let loadedCost = log.editableCost.map { NSDecimalNumber(decimal: $0).stringValue } ?? ""
        let loadedCategory = log.editableCostCategory ?? .maintenance
        let loadedNotes = log.notes ?? ""

        customServiceName = log.service?.name ?? L10n.serviceFallbackName
        timing = .earlier
        customDate = log.performedDate
        mileageAtService = log.mileageAtService
        cost = loadedCost
        costCategory = loadedCategory
        notes = loadedNotes

        editBaseline = ServiceLogEditValues(
            performedDate: log.performedDate,
            mileage: log.mileageAtService,
            costText: loadedCost,
            costCategory: loadedCategory,
            notes: loadedNotes
        )

        // A date/mileage edit moves every service of a visit, so any of them
        // that anchors its service's next reminder can have that reminder moved.
        let occasionLogs = log.occasionLogs
        occasionServiceCount = occasionLogs.count
        let anchors = occasionLogs.filter(\.anchorsNextReminder)
        reminderAnchorLogs = anchors.filter { $0.id == log.id } + anchors.filter { $0.id != log.id }
    }

    var editValues: ServiceLogEditValues {
        ServiceLogEditValues(
            performedDate: performedDate,
            mileage: mileageAtService,
            costText: cost,
            costCategory: costCategory,
            notes: notes
        )
    }

    /// Whether Save would write something different from what was loaded.
    var hasEditChanges: Bool {
        editValues != editBaseline || !pendingAttachments.isEmpty
    }

    // MARK: - F6: "Was …" while a value differs

    var originalDate: Date? {
        guard let base = editBaseline, performedDate != base.performedDate else { return nil }
        return base.performedDate
    }

    /// The loaded reading, while the (non-empty) field differs from it. A
    /// cleared field is a blocked save, not a change to annotate.
    var originalMileage: Int?? {
        guard let base = editBaseline, let mileageAtService, mileageAtService != base.mileage else { return nil }
        return .some(base.mileage)
    }

    var originalCost: Decimal?? {
        guard let base = editBaseline, editValues.cost != base.cost else { return nil }
        return .some(base.cost)
    }

    // MARK: - F9: moving the next reminder

    var dateOrMileageChanged: Bool {
        originalDate != nil || originalMileage != nil
    }

    var offersMoveReminder: Bool {
        mode.isEdit && dateOrMileageChanged && !reminderAnchorLogs.isEmpty
    }

    /// The service whose reminder the impact preview shows — this log's own
    /// when it anchors one, else the first visit sibling that does.
    private var previewService: Service? { reminderAnchorLogs.first?.service }

    var currentReminderSchedule: ReminderImpactCalculator.Schedule {
        ReminderImpactCalculator.Schedule(dueDate: previewService?.dueDate, dueMileage: previewService?.dueMileage)
    }

    /// Mirrors `Service.recalculateDueDates`: always interval-derived from this
    /// log's (edited) date/mileage, no explicit override.
    var proposedReminderSchedule: ReminderImpactCalculator.Schedule {
        guard let service = previewService, let mileageAtService else { return currentReminderSchedule }
        return ReminderImpactCalculator.projected(
            intervalMonths: service.intervalMonths,
            intervalMiles: service.intervalMiles,
            anchorDate: performedDate,
            anchorMileage: mileageAtService,
            explicitDueDate: nil,
            explicitDueMileage: nil
        )
    }
}
