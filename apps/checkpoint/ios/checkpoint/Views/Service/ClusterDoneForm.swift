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
//  picker: the services are the cluster's, or a booked appointment's.
//
//  From an appointment ("Log Visit") the form starts on the appointment's day
//  and shows its shop, which goes on the visit (`AppointmentCompletion`).
//

import SwiftUI
import SwiftData

struct ClusterDoneForm: View {
    let services: [Service]
    let vehicle: Vehicle
    /// An appointment's day and shop; nil for a suggested cluster.
    let prefill: VisitPrefill?
    var onSaved: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query private var allServices: [Service]

    @State private var performedDate: Date
    @State private var mileage: Int?
    @State private var costInput = ""
    @State private var costError: String?
    @State private var costCategory: CostCategory = .maintenance
    @State private var shopName: String
    @State private var notes = ""
    @State private var pendingAttachments: [AttachmentPicker.AttachmentData] = []
    @State private var showBlocker = false

    init(cluster: ServiceCluster, onSaved: (() -> Void)? = nil) {
        self.init(services: cluster.services, vehicle: cluster.vehicle, prefill: nil, onSaved: onSaved)
    }

    init(services: [Service], vehicle: Vehicle, prefill: VisitPrefill?, onSaved: (() -> Void)? = nil) {
        self.services = services
        self.vehicle = vehicle
        self.prefill = prefill
        self.onSaved = onSaved
        _performedDate = State(initialValue: prefill?.performedDate ?? Date())
        _shopName = State(initialValue: prefill?.shopName ?? "")
    }

    private var isDirty: Bool {
        let dateChanged = prefill.map { performedDate != $0.performedDate }
            ?? !Calendar.current.isDateInToday(performedDate)
        return dateChanged
            || mileage != vehicle.currentMileage
            || !costInput.isEmpty
            || shopName != (prefill?.shopName ?? "")
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
                        .readableContentWidth()
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
        FormSection(title: L10n.formServicesCount(services.count)) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(services, id: \.id) { service in
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

            // Only from an appointment, which named the shop: it goes on the
            // visit. A suggested cluster keeps its resolved shape.
            if prefill?.shopName != nil {
                InstrumentTextField(
                    label: L10n.formShop,
                    text: $shopName,
                    placeholder: L10n.formShopPlaceholder
                )
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
        let shop = shopName.trimmingCharacters(in: .whitespacesAndNewlines)
        ServiceVisitWriter.record(
            services.map { .tracked($0) },
            on: vehicle,
            details: ServiceVisitWriter.Details(
                performedDate: performedDate,
                mileage: mileage,
                totalCost: cost,
                costCategory: costCategory,
                shopName: shop.isEmpty ? nil : shop,
                notes: notes.isEmpty ? nil : notes
            ),
            attachments: pendingAttachments,
            in: modelContext
        )
        IntentDonations.loggedServices(services.map(\.name), on: vehicle)

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
