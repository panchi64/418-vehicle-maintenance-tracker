//
//  AddServiceView+Save.swift
//  checkpoint
//
//  Save logic extracted from AddServiceView
//

import SwiftUI
import SwiftData

extension AddServiceView {

    // MARK: - Save Logic

    func saveService() {
        // Analytics
        let isPreset = selectedPreset != nil
        let category = selectedPreset?.category
        let hasInterval = scheduleRecurring && ((intervalMonths != nil && intervalMonths != 0) || (intervalMiles != nil && intervalMiles != 0))

        HapticService.shared.success()

        if mode == .record {
            AnalyticsService.shared.capture(.serviceLogged(
                isPreset: isPreset,
                category: category,
                hasInterval: hasInterval
            ))
            saveLoggedService()
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
            ToastService.shared.show(L10n.toastServiceRecorded, icon: "checkmark", style: .success)
        } else {
            ToastService.shared.show(L10n.toastReminderSet, icon: "clock", style: .success)
        }
        appState.recordCompletedAction()
        dismiss()
    }

    // MARK: - App Icon

    private func updateAppIcon() {
        AppIconService.shared.updateIcon(for: vehicle, services: services)
    }

    // MARK: - Widget Data

    private func updateWidgetData() {
        WidgetDataService.shared.updateWidget(for: vehicle)
    }

    // MARK: - Save Logged Service

    private func saveLoggedService() {
        let mileage = mileageAtService ?? vehicle.currentMileage

        // Create service
        let service = Service(
            name: serviceName,
            lastPerformed: performedDate,
            lastMileage: mileage,
            intervalMonths: scheduleRecurring ? intervalMonths : nil,
            intervalMiles: scheduleRecurring ? intervalMiles : nil
        )
        service.vehicle = vehicle

        // Derive next due date/mileage from intervals (only when recurring)
        if scheduleRecurring {
            service.deriveDueFromIntervals(anchorDate: performedDate, anchorMileage: mileage)
        }

        modelContext.insert(service)

        // Create service log entry
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

        // Save attachments
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
        }

        // Update vehicle mileage if service mileage is higher
        if mileage > vehicle.currentMileage {
            vehicle.currentMileage = mileage
        }
    }

    // MARK: - Save Scheduled Service

    private func saveScheduledService() {
        let service = Service(
            name: serviceName,
            intervalMonths: intervalMonths,
            intervalMiles: intervalMiles,
            notes: notes.isEmpty ? nil : notes
        )
        service.vehicle = vehicle

        // Derive deadlines from intervals (same logic as record mode and mark-complete)
        service.deriveDueFromIntervals(anchorDate: Date(), anchorMileage: vehicle.currentMileage)

        // Apply user overrides: custom date or explicit due mileage take precedence
        if hasCustomDate {
            service.dueDate = dueDate
        }
        if let explicit = dueMileage {
            service.dueMileage = explicit
        }

        modelContext.insert(service)
    }
}
