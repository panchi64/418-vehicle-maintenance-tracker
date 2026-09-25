//
//  EditServiceView+Actions.swift
//  checkpoint
//
//  Loading, saving, and deleting for Edit Service.
//

import SwiftUI
import SwiftData

extension EditServiceView {

    // MARK: - Data Loading

    func loadServiceData() {
        serviceName = service.name
        hasDueDate = service.dueDate != nil
        dueDate = service.dueDate ?? Date()
        dueMileage = service.dueMileage
        intervalMonths = service.intervalMonths
        intervalMiles = service.intervalMiles
        isRecurring = service.isRecurring
        notes = service.notes ?? ""

        loadedServiceName = service.name
        loadedSchedule = ReminderImpactCalculator.Schedule(dueDate: service.dueDate, dueMileage: service.dueMileage)
        loadedIntervalMonths = service.intervalMonths
        loadedIntervalMiles = service.intervalMiles
        loadedIsRecurring = service.isRecurring
        loadedNotes = service.notes ?? ""
    }

    // MARK: - Save

    func saveChanges() {
        HapticService.shared.success()
        AnalyticsService.shared.capture(.serviceEdited)

        service.name = serviceName
        let schedule = proposedSchedule
        service.dueDate = schedule.dueDate
        service.dueMileage = schedule.dueMileage
        service.intervalMonths = isRecurring ? intervalMonths : nil
        service.intervalMiles = isRecurring ? intervalMiles : nil
        service.isRecurring = isRecurring && Service.hasIntervalPolicy(
            intervalMonths: intervalMonths,
            intervalMiles: intervalMiles
        )
        service.notes = notes.isEmpty ? nil : notes

        // The rebuild is the whole operation — it purges the vehicle's pending
        // set before re-adding.
        ServiceNotificationScheduler.rescheduleNotifications(for: vehicle)

        refreshSurfaces()
        ToastService.shared.show(L10n.toastServiceUpdated, icon: "checkmark", style: .success)
        dismiss()
    }

    // MARK: - Delete

    func deleteService() {
        AnalyticsService.shared.capture(.serviceDeleted)
        modelContext.delete(service)
        // Deleting the service cascades to its logs, which .nullify their
        // attachments. Any attachment left with neither a log nor a vehicle is
        // swept so it doesn't linger in external storage with no owner.
        Document.purgeOrphans(in: modelContext)
        // Rebuild the vehicle's reminders around what's left, so a stale
        // bundled banner can't name the deleted service.
        ServiceNotificationScheduler.rescheduleNotifications(for: vehicle)
        refreshSurfaces()
        dismiss()
    }

    /// App icon badge and widget follow every schedule change.
    private func refreshSurfaces() {
        AppIconService.shared.updateIcon(for: vehicle, services: services)
        WidgetDataService.shared.updateWidget(for: vehicle)
    }
}
