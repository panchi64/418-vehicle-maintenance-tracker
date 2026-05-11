import SwiftUI
import SwiftData

extension AddServiceView {

    /// Persist the form. When `keepOpen` is true, the screen stays open and
    /// the form resets so the user can immediately log another entry.
    func saveService(keepOpen: Bool = false) {
        let isPreset = selectedPreset != nil
        let category = selectedPreset?.category
        let hasInterval = scheduleRecurring && ((intervalMonths != nil && intervalMonths != 0) || (intervalMiles != nil && intervalMiles != 0))

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
        scheduleRecurring = false
        pendingAttachments = []
        intervalMonths = nil
        intervalMiles = nil
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
            intervalMonths: scheduleRecurring ? intervalMonths : nil,
            intervalMiles: scheduleRecurring ? intervalMiles : nil
        )
        service.vehicle = vehicle

        if scheduleRecurring {
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
        let service = Service(
            name: serviceName,
            intervalMonths: intervalMonths,
            intervalMiles: intervalMiles,
            notes: notes.isEmpty ? nil : notes
        )
        service.vehicle = vehicle

        service.deriveDueFromIntervals(anchorDate: Date(), anchorMileage: vehicle.currentMileage)

        if hasCustomDate {
            service.dueDate = dueDate
        }
        if let explicit = dueMileage {
            service.dueMileage = explicit
        }

        modelContext.insert(service)
    }
}
