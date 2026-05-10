//
//  MarkServiceVisitDoneSheet.swift
//  checkpoint
//
//  Unified "mark done" sheet for both single services and clusters.
//
//  Why one sheet for two origins:
//    The old `MarkClusterDoneSheet` divided one entered total by N services and
//    stored the divided number on every log — a fabricated per-service cost
//    that propagated through history, detail views, and analytics. The new
//    flow stores the entered total on a `ServiceVisit` and leaves per-log
//    `cost` nil. One UI, one save path, no division.
//
//  Save behavior by origin:
//    .singleService(Service)
//        Creates a standalone `ServiceLog` with `cost` populated directly.
//        No `ServiceVisit` is created. This preserves the per-service
//        "Average Cost" insight for users who never bundle.
//    .cluster(ServiceCluster)
//        Creates one `ServiceVisit` with the entered total, plus N child
//        `ServiceLog`s with `cost = nil` and `visit` set to the new visit.
//

import SwiftUI
import SwiftData

struct MarkServiceVisitDoneSheet: View {
    enum Origin {
        case singleService(Service, Vehicle)
        case cluster(ServiceCluster)
    }

    let origin: Origin
    var onSaved: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query private var allServices: [Service]

    @State private var performedDate: Date = Date()
    @State private var mileage: Int? = nil
    @State private var costInput: String = ""
    @State private var costError: String?
    @State private var costCategory: CostCategory = .maintenance
    @State private var notes: String = ""
    @State private var pendingAttachments: [AttachmentPicker.AttachmentData] = []

    private var vehicle: Vehicle {
        switch origin {
        case .singleService(_, let vehicle): return vehicle
        case .cluster(let cluster): return cluster.vehicle
        }
    }

    private var services: [Service] {
        switch origin {
        case .singleService(let service, _): return [service]
        case .cluster(let cluster): return cluster.services
        }
    }

    private var navigationTitle: String {
        switch origin {
        case .singleService: return "Mark as Done"
        case .cluster: return "Mark All Done"
        }
    }

    private var costFieldLabel: String {
        switch origin {
        case .singleService: return "Cost"
        case .cluster: return "Total Cost"
        }
    }

    private var costSectionTitle: String {
        switch origin {
        case .singleService: return "Optional"
        case .cluster: return "Cost (Optional)"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        if case .singleService(let service, _) = origin,
                           let plannedNotes = service.notes,
                           !plannedNotes.isEmpty {
                            plannedNotesSection(plannedNotes)
                        }

                        if case .cluster(let cluster) = origin {
                            servicesListSection(cluster: cluster)
                        }

                        detailsSection

                        costSection

                        if case .cluster = origin {
                            sharedNotesSection
                        } else {
                            inlineNotesField
                        }

                        attachmentsSection

                        Spacer(minLength: Spacing.xl)
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.vertical, Spacing.lg)
                }
            }
            .numberPadDoneButton()
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .toolbarButtonStyle()
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .toolbarButtonStyle(isDisabled: mileage == nil)
                        .disabled(mileage == nil)
                }
            }
            .trackScreen(.markServiceDone)
            .onAppear {
                mileage = vehicle.effectiveMileage
            }
        }
    }

    // MARK: - Sections

    private func plannedNotesSection(_ plannedNotes: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            InstrumentSectionHeader(title: "Planned Notes")

            Text(plannedNotes)
                .font(.brutalistBody)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Spacing.md)
                .background(Theme.surfaceInstrument)
                .brutalistBorder()
        }
    }

    private func servicesListSection(cluster: ServiceCluster) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            InstrumentSectionHeader(title: "Services (\(cluster.serviceCount))")

            VStack(spacing: 0) {
                ForEach(Array(cluster.services.enumerated()), id: \.element.id) { index, service in
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        HStack(spacing: Spacing.sm) {
                            Rectangle()
                                .fill(Theme.statusGood)
                                .frame(width: 4, height: 4)

                            Text(service.name.uppercased())
                                .font(.brutalistBody)
                                .foregroundStyle(Theme.textPrimary)

                            Spacer()
                        }

                        if let serviceNotes = service.notes, !serviceNotes.isEmpty {
                            Text(serviceNotes)
                                .font(.brutalistSecondary)
                                .foregroundStyle(Theme.textTertiary)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.leading, Spacing.sm + 4)
                        }
                    }
                    .padding(Spacing.md)

                    if index < cluster.services.count - 1 {
                        Rectangle()
                            .fill(Theme.gridLine)
                            .frame(height: 1)
                    }
                }
            }
            .background(Theme.surfaceInstrument)
            .brutalistBorder()
        }
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            let title: String = {
                switch origin {
                case .singleService: return "Service Details"
                case .cluster: return "Details"
                }
            }()

            InstrumentSectionHeader(title: title)

            InstrumentDatePicker(
                label: "Date Performed",
                date: $performedDate
            )

            InstrumentNumberField(
                label: "Mileage",
                value: $mileage,
                placeholder: "Required",
                suffix: DistanceSettings.shared.unit.abbreviation
            )
        }
    }

    private var costSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            InstrumentSectionHeader(title: costSectionTitle)

            InstrumentTextField(
                label: costFieldLabel,
                text: $costInput,
                placeholder: "$0.00",
                keyboardType: .decimalPad
            )
            .onChange(of: costInput) { _, newValue in
                costInput = CostValidation.filterCostInput(newValue)
                costError = CostValidation.validate(costInput)
            }

            if let costError {
                ErrorMessageRow(message: costError) {
                    self.costError = nil
                }
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("CATEGORY")
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.textTertiary)
                    .tracking(1)

                InstrumentSegmentedControl(
                    options: CostCategory.allCases,
                    selection: $costCategory
                ) { category in
                    category.displayName
                }
            }
        }
    }

    private var inlineNotesField: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            InstrumentTextEditor(
                label: "Notes",
                text: $notes,
                placeholder: "Add notes...",
                minHeight: 80
            )
        }
    }

    private var sharedNotesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            InstrumentSectionHeader(title: "Notes (Optional)")

            InstrumentTextEditor(
                label: "Shared Notes",
                text: $notes,
                placeholder: "Add notes for all services...",
                minHeight: 80
            )
        }
    }

    private var attachmentsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            InstrumentSectionHeader(title: "Attachments")

            AttachmentPicker(attachments: $pendingAttachments)
        }
    }

    // MARK: - Save

    private func save() {
        HapticService.shared.success()
        let costDecimal = Decimal(string: costInput)
        let mileageInt = mileage ?? vehicle.effectiveMileage
        let trimmedNotes = notes.isEmpty ? nil : notes

        switch origin {
        case .singleService:
            saveSingleService(
                costDecimal: costDecimal,
                mileageInt: mileageInt,
                trimmedNotes: trimmedNotes
            )
        case .cluster:
            saveCluster(
                costDecimal: costDecimal,
                mileageInt: mileageInt,
                trimmedNotes: trimmedNotes
            )
        }

        // Update vehicle mileage if higher than current.
        if mileageInt > vehicle.currentMileage {
            vehicle.currentMileage = mileageInt
            vehicle.mileageUpdatedAt = performedDate
        }

        // One mileage snapshot per day, regardless of how many services.
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

        AppIconService.shared.updateIcon(for: vehicle, services: allServices)
        WidgetDataService.shared.updateWidget(for: vehicle)

        ToastService.shared.show(L10n.toastServiceLogged, icon: "checkmark", style: .success)
        onSaved?()
        appState.recordCompletedAction()
        dismiss()
    }

    private func saveSingleService(
        costDecimal: Decimal?,
        mileageInt: Int,
        trimmedNotes: String?
    ) {
        guard case .singleService(let service, _) = origin else { return }

        AnalyticsService.shared.capture(.serviceMarkedDone(
            hasCost: costDecimal != nil,
            hasNotes: trimmedNotes != nil,
            hasAttachments: !pendingAttachments.isEmpty,
            attachmentCount: pendingAttachments.count
        ))

        let log = ServiceLog(
            service: service,
            vehicle: vehicle,
            performedDate: performedDate,
            mileageAtService: mileageInt,
            cost: costDecimal,
            costCategory: costDecimal != nil ? costCategory : nil,
            notes: trimmedNotes
        )
        modelContext.insert(log)

        attachAttachments(to: log)
        service.recalculateDueDates(performedDate: performedDate, mileage: mileageInt)
    }

    private func saveCluster(
        costDecimal: Decimal?,
        mileageInt: Int,
        trimmedNotes: String?
    ) {
        guard case .cluster(let cluster) = origin else { return }

        AnalyticsService.shared.capture(.serviceClusterMarkAllDone)

        // One ServiceVisit holds the honest total. Per-service cost is nil
        // (un-itemized). Phase B turns on optional itemization.
        let visit = ServiceVisit(
            vehicle: vehicle,
            performedDate: performedDate,
            mileageAtVisit: mileageInt,
            totalCost: costDecimal,
            costCategory: costDecimal != nil ? costCategory : nil,
            isItemized: false,
            shopName: nil,
            notes: trimmedNotes
        )
        modelContext.insert(visit)

        // First child log carries any attachments. Phase D may move attachments
        // onto the visit directly.
        var firstLog: ServiceLog?
        for service in cluster.services {
            let log = ServiceLog(
                service: service,
                vehicle: vehicle,
                performedDate: performedDate,
                mileageAtService: mileageInt,
                cost: nil,
                costCategory: nil,
                notes: nil
            )
            log.visit = visit
            modelContext.insert(log)
            if firstLog == nil { firstLog = log }

            service.recalculateDueDates(performedDate: performedDate, mileage: mileageInt)
        }

        if let firstLog {
            attachAttachments(to: firstLog)
        }
    }

    private func attachAttachments(to log: ServiceLog) {
        for data in pendingAttachments {
            let thumbnailData = ServiceAttachment.generateThumbnailData(
                from: data.data,
                mimeType: data.mimeType
            )
            let attachment = ServiceAttachment(
                serviceLog: log,
                data: data.data,
                thumbnailData: thumbnailData,
                fileName: data.fileName,
                mimeType: data.mimeType,
                extractedText: data.extractedText
            )
            modelContext.insert(attachment)
        }
    }
}

#Preview("Single") {
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

    MarkServiceVisitDoneSheet(origin: .singleService(service, vehicle))
        .environment(AppState())
        .modelContainer(for: [Vehicle.self, Service.self, ServiceLog.self, ServiceVisit.self, VisitLineItem.self, MileageSnapshot.self, ServiceAttachment.self], inMemory: true)
        .preferredColorScheme(.dark)
}

#Preview("Cluster") {
    let vehicle = Vehicle.sampleVehicle
    let services = Service.sampleServices(for: vehicle)
    let cluster = ServiceCluster(
        services: Array(services.prefix(3)),
        anchorService: services[0],
        vehicle: vehicle,
        mileageWindow: 1000,
        daysWindow: 30
    )

    return MarkServiceVisitDoneSheet(origin: .cluster(cluster))
        .environment(AppState())
        .modelContainer(for: [Vehicle.self, Service.self, ServiceLog.self, ServiceVisit.self, VisitLineItem.self, MileageSnapshot.self, ServiceAttachment.self], inMemory: true)
        .preferredColorScheme(.dark)
}
