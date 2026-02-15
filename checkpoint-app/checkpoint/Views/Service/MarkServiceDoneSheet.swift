//
//  MarkServiceDoneSheet.swift
//  checkpoint
//
//  Sheet view for marking a service as completed
//

import SwiftUI
import SwiftData

struct MarkServiceDoneSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query private var services: [Service]

    let service: Service
    let vehicle: Vehicle
    var onSaved: (() -> Void)? = nil

    @State private var performedDate: Date = Date()
    @State private var mileage: Int? = nil
    @State private var cost: String = ""
    @State private var costError: String?
    @State private var notes: String = ""
    @State private var pendingAttachments: [AttachmentPicker.AttachmentData] = []

    var body: some View {
        NavigationStack {
            ZStack {
                // Glass background
                Theme.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Service Details Section
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            InstrumentSectionHeader(title: "Service Details")

                            InstrumentDatePicker(
                                label: "Date Performed",
                                date: $performedDate
                            )

                            InstrumentNumberField(
                                label: "Mileage",
                                value: $mileage,
                                placeholder: "Required",
                                suffix: "mi"
                            )
                        }

                        // Optional Section
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            InstrumentSectionHeader(title: "Optional")

                            InstrumentTextField(
                                label: "Cost",
                                text: $cost,
                                placeholder: "$0.00",
                                keyboardType: .decimalPad
                            )
                            .onChange(of: cost) { _, newValue in
                                cost = CostValidation.filterCostInput(newValue)
                                costError = CostValidation.validate(cost)
                            }

                            if let costError {
                                ErrorMessageRow(message: costError) {
                                    self.costError = nil
                                }
                            }

                            InstrumentTextEditor(
                                label: "Notes",
                                text: $notes,
                                placeholder: "Add notes...",
                                minHeight: 80
                            )
                        }

                        // Attachments Section
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            InstrumentSectionHeader(title: "Attachments")

                            AttachmentPicker(attachments: $pendingAttachments)
                        }

                        Spacer(minLength: Spacing.xl)
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.vertical, Spacing.lg)
                }
            }
            .navigationTitle("Mark as Done")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .toolbarButtonStyle()
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { markAsDone() }
                        .toolbarButtonStyle(isDisabled: mileage == nil)
                        .disabled(mileage == nil)
                }
            }
            .trackScreen(.markServiceDone)
            .onAppear {
                mileage = vehicle.currentMileage
            }
        }
    }

    private func markAsDone() {
        HapticService.shared.success()
        AnalyticsService.shared.capture(.serviceMarkedDone(
            hasCost: !cost.isEmpty && Decimal(string: cost) != nil,
            hasNotes: !notes.isEmpty,
            hasAttachments: !pendingAttachments.isEmpty,
            attachmentCount: pendingAttachments.count
        ))

        let mileageInt = mileage ?? vehicle.currentMileage

        // Create service log
        let log = ServiceLog(
            service: service,
            vehicle: vehicle,
            performedDate: performedDate,
            mileageAtService: mileageInt,
            cost: Decimal(string: cost),
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

        // Update service with new due dates
        service.lastPerformed = performedDate
        service.lastMileage = mileageInt

        if let months = service.intervalMonths, months > 0 {
            service.dueDate = Calendar.current.date(byAdding: .month, value: months, to: performedDate)
        } else {
            service.dueDate = nil
        }
        if let miles = service.intervalMiles, miles > 0 {
            service.dueMileage = mileageInt + miles
        } else {
            service.dueMileage = nil
        }

        // Update vehicle mileage if service mileage is higher
        if mileageInt > vehicle.currentMileage {
            vehicle.currentMileage = mileageInt
            vehicle.mileageUpdatedAt = performedDate
        }

        // Create mileage snapshot for pace calculation (throttled: max 1 per day)
        let shouldCreateSnapshot = !MileageSnapshot.hasSnapshotToday(
            snapshots: vehicle.mileageSnapshots ?? []
        )

        if shouldCreateSnapshot {
            let snapshot = MileageSnapshot(
                vehicle: vehicle,
                mileage: mileageInt,
                recordedAt: performedDate,
                source: .serviceCompletion
            )
            modelContext.insert(snapshot)
        }

        updateAppIcon()
        updateWidgetData()
        ToastService.shared.show(L10n.toastServiceLogged, icon: "checkmark", style: .success)
        onSaved?()
        appState.recordCompletedAction()
        dismiss()
    }

    private func updateAppIcon() {
        AppIconService.shared.updateIcon(for: vehicle, services: services)
    }

    private func updateWidgetData() {
        WidgetDataService.shared.updateWidget(for: vehicle)
    }
}

#Preview {
    @Previewable @State var vehicle = Vehicle(
        name: "Test Car",
        make: "Toyota",
        model: "Camry",
        year: 2022,
        currentMileage: 32500
    )

    @Previewable @State var service = Service(
        name: "Oil Change",
        dueDate: Calendar.current.date(byAdding: .day, value: 12, to: .now),
        dueMileage: 33000,
        intervalMonths: 6,
        intervalMiles: 5000
    )

    MarkServiceDoneSheet(service: service, vehicle: vehicle)
        .environment(AppState())
        .modelContainer(for: [Vehicle.self, Service.self, ServiceLog.self, MileageSnapshot.self], inMemory: true)
        .preferredColorScheme(.dark)
}
