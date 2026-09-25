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
        ServiceDeleteAction.delete([service], vehicle: vehicle, in: modelContext)
        dismiss()
    }

    /// App icon badge and widget follow every schedule change.
    private func refreshSurfaces() {
        AppIconService.shared.updateIcon(for: vehicle, services: services)
        WidgetDataService.shared.updateWidget(for: vehicle)
    }
}
