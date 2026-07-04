import SwiftUI
import SwiftData

extension AddServiceView {

    /// Persist the form. When `keepOpen` is true, the screen stays open and
    /// the form resets so the user can immediately log another entry.
    func saveService(keepOpen: Bool = false) {
        let isPreset = model.selectedPreset != nil
        let category = model.selectedPreset?.category
        let hasInterval = model.isRecurring && Service.hasIntervalPolicy(
            intervalMonths: model.intervalMonths,
            intervalMiles: model.intervalMiles
        )

        HapticService.shared.success()

        var undo: RecordedServiceUndo?

        if model.mode == .record {
            AnalyticsService.shared.capture(.serviceLogged(
                isPreset: isPreset,
                category: category,
                hasInterval: hasInterval
            ))
            undo = saveLoggedService()
        } else {
            AnalyticsService.shared.capture(.serviceScheduled(
                isPreset: isPreset,
                category: category,
                hasInterval: hasInterval
            ))
            saveScheduledService()
        }
        updateAppIcon()
        updateWidgetData()

        if model.mode == .record {
            let context = modelContext
            let toastAction: ToastService.ToastAction?
            if !model.isRecurring {
                // No future Service was spawned — offer the user a one-tap
                // way to schedule one from the completion's anchors.
                let prefill = PostRecordPrefill(
                    serviceName: model.serviceName,
                    performedDate: model.performedDate,
                    performedMileage: model.mileageAtService ?? vehicle.currentMileage,
                    intervalMonths: model.intervalMonths,
                    intervalMiles: model.intervalMiles
                )
                let state = appState
                toastAction = ToastService.ToastAction(label: "SCHEDULE NEXT") {
                    state.postRecordPrefill = prefill
                    state.addServiceMode = .remind
                    state.showAddService = true
                    HapticService.shared.selectionChanged()
                }
            } else {
                toastAction = undo.map { snapshot in
                    ToastService.ToastAction(label: "UNDO") {
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
        } else {
            ToastService.shared.show(L10n.toastReminderSet, icon: "clock", style: .success)
        }
        appState.recordCompletedAction()

        if keepOpen {
            model.resetLogModeFields()
        } else {
            dismiss()
        }
    }

    private func updateAppIcon() {
        AppIconService.shared.updateIcon(for: vehicle, services: services)
    }

    private func updateWidgetData() {
        WidgetDataService.shared.updateWidget(for: vehicle)
    }

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

        if mileage > vehicle.currentMileage {
            vehicle.currentMileage = mileage
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
