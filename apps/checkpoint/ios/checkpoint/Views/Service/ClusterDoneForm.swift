//
//  ClusterDoneForm.swift
//  checkpoint
//
//  Complete several services as one visit.
//
//  The old cluster sheet divided one entered total by N services and stored
//  the divided number on every log — a fabricated per-service cost that
//  propagated through history, detail views, and analytics. This stores the
//  entered total on one `ServiceVisit` and leaves per-log `cost` nil.
//
//  Same shape and conventions as `ServiceLogForm` (toolbar Save, dismiss
//  protection, F11 odometer adoption stated before save), minus the service
//  picker: the services are the cluster's.
//

import SwiftUI
import SwiftData

struct ClusterDoneForm: View {
    let cluster: ServiceCluster
    var onSaved: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query private var allServices: [Service]

    @State private var performedDate = Date()
    @State private var mileage: Int?
    @State private var costInput = ""
    @State private var costError: String?
    @State private var costCategory: CostCategory = .maintenance
    @State private var notes = ""
    @State private var pendingAttachments: [AttachmentPicker.AttachmentData] = []
    @State private var showBlocker = false

    private var vehicle: Vehicle { cluster.vehicle }

    private var isDirty: Bool {
        !Calendar.current.isDateInToday(performedDate)
            || mileage != vehicle.currentMileage
            || !costInput.isEmpty
            || !notes.isEmpty
            || !pendingAttachments.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ZStack {
                    AtmosphericBackground()

                    ScrollView {
                        VStack(alignment: .leading, spacing: Spacing.xl) {
                            servicesSection
                            detailsSection
                                .id("details")
                            moreSection
                        }
                        .padding(.horizontal, Spacing.screenHorizontal)
                        .padding(.top, Spacing.md)
                        .padding(.bottom, Spacing.xxl)
                    }
                }
                .keyboardDismissToolbar()
                .formToolbar(
                    title: L10n.formTitleCompleteVisit,
                    subtitle: vehicle.displayName,
                    canSave: mileage != nil,
                    isDirty: isDirty,
                    onSave: save,
                    onBlocked: {
                        showBlocker = true
                        withAnimation { proxy.scrollTo("details", anchor: .center) }
                    }
                )
                .trackScreen(.markServiceDone)
                .onAppear {
                    // The last *confirmed* reading, never the estimate.
                    if mileage == nil { mileage = vehicle.currentMileage }
                }
            }
        }
    }

    // MARK: - Sections

    private var servicesSection: some View {
        FormSection(title: L10n.formServicesCount(cluster.serviceCount)) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(cluster.services, id: \.id) { service in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(service.name)
                            .font(.brutalistBodyEmphasis)
                            .foregroundStyle(Theme.textPrimary)
                        if let serviceNotes = service.notes, !serviceNotes.isEmpty {
                            Text(serviceNotes)
                                .font(.brutalistSecondary)
                                .foregroundStyle(Theme.textTertiary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: TouchTarget.minimum, alignment: .leading)
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(Theme.gridLine).frame(height: Theme.borderWidth)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    private var detailsSection: some View {
        FormSection(title: L10n.formDetails) {
            InstrumentDatePicker(label: L10n.formDatePerformed, date: $performedDate)

            InstrumentNumberField(
                label: L10n.formOdometerAtService,
                value: $mileage,
                placeholder: Formatters.mileageNumber(vehicle.currentMileage),
                suffix: DistanceSettings.shared.unit.abbreviation,
                requirement: .required(reason: L10n.formEnterReading)
            )

            if showBlocker, mileage == nil {
                FormAdvisory.blocking(L10n.formEnterReading)
            }

            // Adoption of a newer reading is stated before save (F11).
            if let summary = MileageCommit.adoptionSummary(reading: mileage, observedAt: performedDate, for: vehicle) {
                FormAdvisory.info(summary)
            }

            InstrumentTextField(
                label: L10n.formTotalCost,
                text: $costInput,
                placeholder: "0.00",
                keyboardType: .decimalPad,
                prefix: Formatters.currency.currencySymbol
            )
            .onChange(of: costInput) { _, newValue in
                costInput = CostValidation.filterCostInput(newValue)
                costError = CostValidation.validate(costInput)
            }

            if let costError {
                FormAdvisory.caution(costError) { self.costError = nil }
            }
        }
    }

    private var moreSection: some View {
        FormSection(title: L10n.formMoreDetails) {
            InlinePicker(
                label: L10n.formCategory,
                options: CostCategory.allCases.map { PickerOption(value: $0, label: $0.displayName) },
                selection: $costCategory
            )

            RichNotesEditor(
                label: L10n.formNotes,
                text: $notes,
                placeholder: L10n.formNotesPlaceholder,
                minHeight: 80
            )

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(L10n.formAttachments.uppercased())
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.textTertiary)
                    .tracking(1.5)
                AttachmentPicker(attachments: $pendingAttachments)
            }
        }
    }

    // MARK: - Save

    private func save() {
        guard let mileage else { return }
        HapticService.shared.success()
        AnalyticsService.shared.capture(.serviceClusterMarkAllDone)

        let cost = Decimal(string: costInput)
        let visit = ServiceVisit(
            vehicle: vehicle,
            performedDate: performedDate,
            mileageAtVisit: mileage,
            totalCost: cost,
            costCategory: cost != nil ? costCategory : nil,
            isItemized: false,
            shopName: nil,
            notes: notes.isEmpty ? nil : notes
        )
        modelContext.insert(visit)

        // The first child log carries any attachments.
        var firstLog: ServiceLog?
        for service in cluster.services {
            let log = ServiceLog(
                service: service,
                vehicle: vehicle,
                performedDate: performedDate,
                mileageAtService: mileage,
                cost: nil,
                costCategory: nil,
                notes: nil
            )
            log.visit = visit
            modelContext.insert(log)
            if firstLog == nil { firstLog = log }

            ServiceCompletionService.completeService(
                service,
                performedDate: performedDate,
                mileage: mileage,
                in: modelContext
            )
        }
        if let firstLog {
            ServiceCompletionService.insertAttachments(pendingAttachments, on: firstLog, in: modelContext)
        }

        // F11: one commit path, gated on the reading being the newest.
        MileageCommit.commitIfNewest(
            reading: mileage,
            observedAt: performedDate,
            source: .serviceCompletion,
            for: vehicle,
            in: modelContext
        )

        AppIconService.shared.updateIcon(for: vehicle, services: allServices)
        WidgetDataService.shared.updateWidget(for: vehicle)
        ToastService.shared.show(L10n.toastServiceLogged, icon: "checkmark", style: .success)
        onSaved?()
        appState.recordCompletedAction()
        dismiss()
    }
}

#Preview {
    let vehicle = Vehicle.sampleVehicle
    let services = Service.sampleServices(for: vehicle)
    let cluster = ServiceCluster(
        services: Array(services.prefix(3)),
        anchorService: services[0],
        vehicle: vehicle,
        mileageWindow: 1000,
        daysWindow: 30
    )

    return ClusterDoneForm(cluster: cluster)
        .environment(AppState())
        .modelContainer(for: [Vehicle.self, Service.self, ServiceLog.self, ServiceVisit.self, VisitLineItem.self, MileageSnapshot.self, ServiceAttachment.self], inMemory: true)
}
