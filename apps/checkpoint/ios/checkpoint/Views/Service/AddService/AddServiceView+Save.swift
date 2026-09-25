import SwiftUI
import SwiftData

extension AddServiceView {

    /// Persist the form. One entry point branching on the DERIVED intent —
    /// there were two (`saveLoggedService` / `saveScheduledService`) selected by
    /// a mode the user had to choose. When `keepOpen` is true, the screen stays
    /// open and the form resets so another entry can be logged immediately.
    func saveService(keepOpen: Bool = false) {
        guard let intent = model.intent else { return }

        let isPreset = model.selectedPreset != nil
        let category = model.selectedPreset?.category
        let hasInterval = model.isRecurringSchedule

        HapticService.shared.success()

        switch intent {
        case .log:
            AnalyticsService.shared.capture(.serviceLogged(
                isPreset: isPreset,
                category: category,
                hasInterval: hasInterval
            ))
            // Completing a matched service reschedules inside
            // `ServiceCompletionService`; only a created one needs it here.
            let target = logTarget
            let undo = LoggedServiceWriter.save(model, completing: target, in: modelContext)
            if target == nil, model.isRecurring {
                ServiceNotificationScheduler.rescheduleNotifications(for: vehicle)
            }
            finish(keepOpen: keepOpen) { showLoggedToast(undo: undo) }

        case .schedule:
            AnalyticsService.shared.capture(.serviceScheduled(
                isPreset: isPreset,
                category: category,
                hasInterval: hasInterval
            ))
            saveScheduledService()
            ServiceNotificationScheduler.rescheduleNotifications(for: vehicle)
            finish(keepOpen: keepOpen) {
                ToastService.shared.show(
                    scheduledToastMessage,
                    icon: "clock",
                    style: .success
                )
            }
        }
    }

    private func finish(keepOpen: Bool, showToast: () -> Void) {
        AppIconService.shared.updateIcon(for: vehicle, services: services)
        WidgetDataService.shared.updateWidget(for: vehicle)
        ServiceFormDraftStore.clear(for: vehicle.id)

        showToast()
        appState.recordCompletedAction()

        if keepOpen {
            model.resetLogModeFields()
        } else {
            dismiss()
        }
    }

    // MARK: - Toasts

    /// A recurring completion states the occurrence it just scheduled, rather
    /// than a bare "saved" — the user asked for something to come back, and the
    /// app should say when.
    private var scheduledToastMessage: String {
        if let due = model.nextDueDate {
            return L10n.toastReminderSetFor(Formatters.mediumDate.string(from: due))
        }
        if let mileage = model.nextDueMileage {
            return L10n.toastReminderSetAt(Formatters.mileage(mileage))
        }
        return L10n.toastReminderSet
    }

    private func showLoggedToast(undo: RecordedServiceUndo) {
        let context = modelContext
        let toastAction: ToastService.ToastAction

        if !undo.leftFutureReminder {
            // No future Service was left behind — offer a one-tap way to
            // schedule one from the completion's anchors.
            let prefill = PostRecordPrefill(
                serviceName: model.serviceName,
                performedDate: model.performedDate,
                performedMileage: model.logAnchorMileage,
                intervalMonths: model.intervalMonths,
                intervalMiles: model.intervalMiles
            )
            let state = appState
            toastAction = ToastService.ToastAction(label: L10n.toastScheduleNext.uppercased()) {
                state.present(.addService(postRecord: prefill))
                HapticService.shared.selectionChanged()
            }
        } else {
            let vehicle = vehicle
            toastAction = ToastService.ToastAction(label: L10n.commonUndo.uppercased()) {
                undo.perform(in: context)
                // The undone save changed what is due; reminders and the
                // widget must follow it back.
                ServiceNotificationScheduler.rescheduleNotifications(for: vehicle)
                WidgetDataService.shared.updateWidget(for: vehicle)
                HapticService.shared.selectionChanged()
                AnalyticsService.shared.capture(.serviceLogUndone)
            }
        }

        ToastService.shared.show(
            L10n.toastServiceRecorded,
            icon: "checkmark",
            style: .success,
            action: toastAction
        )
    }

    // MARK: - Persistence

    private func saveScheduledService() {
        // When the user has not enabled "Repeats", drop any interval values
        // they may have typed — the policy should match the toggle's intent.
        let service = Service(
            name: model.serviceName,
            dueDate: model.nextDueDate,
            dueMileage: model.nextDueMileage,
            intervalMonths: model.isRecurring ? model.intervalMonths : nil,
            intervalMiles: model.isRecurring ? model.intervalMiles : nil,
            notes: model.notes.isEmpty ? nil : model.notes,
            isRecurring: model.isRecurringSchedule
        )
        service.vehicle = vehicle
        modelContext.insert(service)
    }
}
