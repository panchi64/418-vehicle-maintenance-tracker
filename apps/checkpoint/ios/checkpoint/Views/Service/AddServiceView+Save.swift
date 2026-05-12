import SwiftUI
import SwiftData

extension AddServiceView {

    /// Persist the form. When `keepOpen` is true, the screen stays open and
    /// the form resets so the user can immediately log another entry.
    func saveService(keepOpen: Bool = false) {
        let isPreset = selectedPreset != nil
        let category = selectedPreset?.category
        let hasInterval = isRecurring && Service.hasIntervalPolicy(
            intervalMonths: intervalMonths,
            intervalMiles: intervalMiles
        )

        HapticService.shared.success()

        var undo: RecordedServiceUndo?

        if mode == .record {
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

        if mode == .record {
            let context = modelContext
            let undoAction: ToastService.ToastAction? = undo.map { snapshot in
                ToastService.ToastAction(label: "UNDO") {
                    snapshot.perform(in: context)
                    HapticService.shared.selectionChanged()
                    AnalyticsService.shared.capture(.serviceLogUndone)
                }
            }
            ToastService.shared.show(
                L10n.toastServiceRecorded,
                icon: "checkmark",
                style: .success,
                action: undoAction
            )
        } else {
            ToastService.shared.show(L10n.toastReminderSet, icon: "clock", style: .success)
        }
        appState.recordCompletedAction()

        if keepOpen {
            resetLogModeFields()
        } else {
            dismiss()
        }
    }

    func resetLogModeFields() {
        selectedPreset = nil
        customServiceName = ""
        performedDate = Date()
        mileageAtService = vehicle.currentMileage
        cost = ""
        costCategory = .maintenance
        notes = ""
        isRecurring = false
        pendingAttachments = []
        intervalMonths = nil
        intervalMiles = nil
        hasCustomDate = false
        dueDate = Date()
        nextDueMileage = nil
    }

    private func updateAppIcon() {
        AppIconService.shared.updateIcon(for: vehicle, services: services)
    }

    private func updateWidgetData() {
        WidgetDataService.shared.updateWidget(for: vehicle)
    }

    private func saveLoggedService() -> RecordedServiceUndo {
        let mileage = mileageAtService ?? vehicle.currentMileage
        let priorMileage = vehicle.currentMileage

        let service = Service(
            name: serviceName,
            lastPerformed: performedDate,
            lastMileage: mileage,
            intervalMonths: isRecurring ? intervalMonths : nil,
            intervalMiles: isRecurring ? intervalMiles : nil,
            isRecurring: isRecurring
        )
        service.vehicle = vehicle

        if isRecurring {
            service.deriveDueFromIntervals(anchorDate: performedDate, anchorMileage: mileage)
        }

        modelContext.insert(service)

        let costDecimal = Decimal(string: cost)
        let log = ServiceLog(
            service: service,
            vehicle: vehicle,
            performedDate: performedDate,
            mileageAtService: mileage,
            cost: costDecimal,
            costCategory: costDecimal != nil ? costCategory : nil,
            notes: notes.isEmpty ? nil : notes
        )
        modelContext.insert(log)

        var insertedAttachments: [ServiceAttachment] = []
        for attachmentData in pendingAttachments {
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
            name: serviceName,
            dueDate: nextDueDate,
            dueMileage: nextDueMileage,
            intervalMonths: isRecurring ? intervalMonths : nil,
            intervalMiles: isRecurring ? intervalMiles : nil,
            notes: notes.isEmpty ? nil : notes,
            isRecurring: isRecurringSchedule
        )
        service.vehicle = vehicle
        modelContext.insert(service)
    }
}
