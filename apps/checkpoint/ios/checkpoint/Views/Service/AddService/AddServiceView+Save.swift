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
            let undo = saveLoggedService()
            if model.isRecurring {
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

    private func showLoggedToast(undo: RecordedServiceUndo?) {
        let context = modelContext
        let toastAction: ToastService.ToastAction?

        if !model.isRecurring {
            // No future Service was spawned — offer a one-tap way to schedule
            // one from the completion's anchors.
            let prefill = PostRecordPrefill(
                serviceName: model.serviceName,
                performedDate: model.performedDate,
                performedMileage: model.mileageAtService ?? vehicle.currentMileage,
                intervalMonths: model.intervalMonths,
                intervalMiles: model.intervalMiles
            )
            let state = appState
            toastAction = ToastService.ToastAction(label: L10n.toastScheduleNext.uppercased()) {
                state.postRecordPrefill = prefill
                state.showAddService = true
                HapticService.shared.selectionChanged()
            }
        } else {
            toastAction = undo.map { snapshot in
                ToastService.ToastAction(label: L10n.commonUndo.uppercased()) {
                    snapshot.perform(in: context)
                    HapticService.shared.selectionChanged()
                    AnalyticsService.shared.capture(.serviceLogUndone)
                }
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

    private func saveLoggedService() -> RecordedServiceUndo {
        let mileage = model.mileageAtService ?? vehicle.currentMileage
        let priorMileage = vehicle.currentMileage

        let service = Service(
            name: model.serviceName,
            lastPerformed: model.performedDate,
            lastMileage: mileage,
            intervalMonths: model.isRecurring ? model.intervalMonths : nil,
            intervalMiles: model.isRecurring ? model.intervalMiles : nil,
            isRecurring: model.isRecurring
        )
        service.vehicle = vehicle

        if model.isRecurring {
            service.deriveDueFromIntervals(anchorDate: model.performedDate, anchorMileage: mileage)
        }

        modelContext.insert(service)

        let costDecimal = Decimal(string: model.cost)
        let log = ServiceLog(
            service: service,
            vehicle: vehicle,
            performedDate: model.performedDate,
            mileageAtService: mileage,
            cost: costDecimal,
            costCategory: costDecimal != nil ? model.costCategory : nil,
            notes: model.notes.isEmpty ? nil : model.notes
        )
        modelContext.insert(log)

        var insertedAttachments: [ServiceAttachment] = []
        for attachmentData in model.pendingAttachments {
            let thumbnailData = ServiceAttachment.generateThumbnailData(
                from: attachmentData.data,
                mimeType: attachmentData.mimeType
            )
            let attachment = ServiceAttachment(
                serviceLog: log,
                data: attachmentData.data,
                thumbnailData: thumbnailData,
                fileName: attachmentData.fileName,
                mimeType: attachmentData.mimeType,
                extractedText: attachmentData.extractedText
            )
            modelContext.insert(attachment)
            insertedAttachments.append(attachment)
        }

        // F11: one commit path. Gated on the reading being the *newest* rather
        // than merely the highest, so backfilling an old service can't
        // overwrite a current odometer — and routed through `recordMileage` so
        // `mileageUpdatedAt` and the snapshot move with it.
        //
        // `keepCurrent` is the user's explicit answer to the one contradiction
        // the app cannot settle, so it wins over the automatic rule.
        if model.mileageResolution != .keepCurrent {
            MileageCommit.commitIfNewest(
                reading: mileage,
                observedAt: model.performedDate,
                source: .serviceCompletion,
                for: vehicle,
                in: modelContext
            )
        }

        return RecordedServiceUndo(
            service: service,
            log: log,
            attachments: insertedAttachments,
            vehicle: vehicle,
            priorVehicleMileage: priorMileage
        )
    }

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
