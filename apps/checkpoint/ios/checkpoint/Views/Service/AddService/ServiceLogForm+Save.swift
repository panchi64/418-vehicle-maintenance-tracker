import SwiftUI
import SwiftData

extension ServiceLogForm {

    /// Persist the form. One entry point, branching on the door and on the
    /// DERIVED intent — never on a mode the user had to choose.
    func save() {
        HapticService.shared.success()

        if let log = model.mode.editing {
            saveEdit(of: log)
        } else if model.isLogging {
            saveLog()
        } else {
            saveSchedule()
        }

        // The icon reflects the selected vehicle; a Duplicate saved to another
        // one must not repaint it with that vehicle's status.
        if vehicle.id == appState.selectedVehicle?.id {
            AppIconService.shared.updateIcon(for: vehicle, services: services)
        }
        WidgetDataService.shared.updateWidget(for: vehicle)
        clearDraft()
        if !model.mode.isEdit { appState.recordCompletedAction() }
        onSaved?()
        dismiss()
    }

    // MARK: - Log / complete

    private func saveLog() {
        let target = logTarget
        if model.mode.completing != nil {
            AnalyticsService.shared.capture(.serviceMarkedDone(
                hasCost: Decimal(string: model.cost) != nil,
                hasNotes: !model.notes.isEmpty,
                hasAttachments: !model.pendingAttachments.isEmpty,
                attachmentCount: model.pendingAttachments.count
            ))
        } else {
            AnalyticsService.shared.capture(.serviceLogged(
                isPreset: model.selectedPreset != nil,
                category: model.selectedPreset?.category,
                hasInterval: model.isRecurringSchedule
            ))
        }
        // Completing a service reschedules inside `ServiceCompletionService`;
        // only a created one needs it here.
        let undo = LoggedServiceWriter.save(model, completing: target, in: modelContext)
        if target == nil, model.isRecurring {
            ServiceNotificationScheduler.rescheduleNotifications(for: vehicle)
        }
        showLoggedToast(undo: undo)
    }

    /// A recurring completion is offered Undo; one that left no reminder
    /// behind is offered "Schedule next" instead — except on a vehicle other
    /// than the selected one (a Duplicate moved across), where [+] would open
    /// on the wrong vehicle, so it keeps Undo.
    private func showLoggedToast(undo: RecordedServiceUndo) {
        let context = modelContext
        let toastAction: ToastService.ToastAction

        if !undo.leftFutureReminder, vehicle.id == appState.selectedVehicle?.id {
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

    // MARK: - Schedule

    private func saveSchedule() {
        AnalyticsService.shared.capture(.serviceScheduled(
            isPreset: model.selectedPreset != nil,
            category: model.selectedPreset?.category,
            hasInterval: model.isRecurringSchedule
        ))
        let dueDate = model.nextDueDate
        let dueMileage = model.scheduledDueMileage
        // Without Repeat, drop the interval — the policy matches the toggle.
        let service = Service(
            name: model.serviceName,
            dueDate: dueDate,
            dueMileage: dueMileage,
            intervalMonths: model.isRecurring ? model.intervalMonths : nil,
            intervalMiles: model.isRecurring ? model.intervalMiles : nil,
            notes: model.notes.isEmpty ? nil : model.notes,
            isRecurring: model.isRecurringSchedule
        )
        service.vehicle = vehicle
        modelContext.insert(service)
        ServiceNotificationScheduler.rescheduleNotifications(for: vehicle)

        // Says when it will come back, rather than a bare "saved".
        let message: String
        if let dueDate {
            message = L10n.toastReminderSetFor(Formatters.mediumDate.string(from: dueDate))
        } else if let dueMileage {
            message = L10n.toastReminderSetAt(Formatters.mileage(dueMileage))
        } else {
            message = L10n.toastReminderSet
        }
        ToastService.shared.show(message, icon: "clock", style: .success)
    }

    // MARK: - Edit

    private func saveEdit(of log: ServiceLog) {
        guard let mileage = model.mileageAtService else { return }
        let newNotes = model.notes.isEmpty ? nil : model.notes
        AnalyticsService.shared.capture(.serviceLogEdited(
            notesChanged: newNotes != log.notes,
            attachmentsAdded: model.pendingAttachments.count
        ))

        // Read before writing: the offer is judged against the loaded values.
        let movesReminder = model.alsoMoveNextReminder && model.offersMoveReminder

        log.applyEditedOccasion(performedDate: model.performedDate, mileage: mileage)
        log.applyEditedCost(Decimal(string: model.cost), category: model.costCategory)
        log.notes = newNotes

        if movesReminder {
            for anchor in model.reminderAnchorLogs {
                anchor.service?.recalculateDueDates(performedDate: model.performedDate, mileage: mileage)
            }
            ServiceNotificationScheduler.rescheduleNotifications(for: vehicle)
        }

        ServiceCompletionService.insertAttachments(model.pendingAttachments, on: log, in: modelContext)
        ToastService.shared.show(L10n.toastServiceLogUpdated, icon: "checkmark", style: .success)
    }
}
