//
//  ServiceVisitDetailView.swift
//  checkpoint
//
//  Detail view for a Service Visit — one shop visit, one honest total,
//  N child service logs.
//
//    - Header: the total (the one primary), then the date
//    - Details: total, category, odometer, shop
//    - Services performed: each drills into its own log
//    - Visit notes, combined attachments
//
//  Edit opens the log form on the visit's first service: a date or odometer
//  edit there moves the whole occasion, and its cost field edits the visit's
//  shared total (EditServiceLogView), so it already is the visit's editor.
//

import SwiftUI
import SwiftData

struct ServiceVisitDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    @Bindable var visit: ServiceVisit

    @State private var logToEdit: ServiceLog?
    @State private var logPendingDeletion: ServiceLog?
    @State private var deleteAfterPop: ServiceLog?

    private var sortedLogs: [ServiceLog] {
        (visit.logs ?? []).sorted { ($0.service?.name ?? "") < ($1.service?.name ?? "") }
    }

    var body: some View {
        let logs = sortedLogs
        let attachments = logs.flatMap { $0.attachments ?? [] }.sorted { $0.createdAt < $1.createdAt }

        ScrollView {
            VStack(spacing: Spacing.xl) {
                header
                detailsSection
                servicesSection(logs)

                if let notes = visit.notes, !notes.isEmpty {
                    notesSection(notes: notes)
                }

                if !attachments.isEmpty {
                    AttachmentSection(
                        attachments: attachments,
                        onSelect: { appState.push(.document($0)) }
                    )
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.vertical, Spacing.lg)
        }
        .background(Theme.backgroundPrimary)
        .navigationTitle(L10n.rowVisitTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let first = logs.first {
                ToolbarItem(placement: .primaryAction) {
                    Button(L10n.servicesActionEdit) {
                        logToEdit = first
                    }
                }
            }
        }
        .sheet(item: $logToEdit, onDismiss: deleteIfRequested) { log in
            EditServiceLogView(log: log, onDelete: { logPendingDeletion = log })
        }
        .onDisappear {
            guard let log = deleteAfterPop else { return }
            deleteAfterPop = nil
            ServiceLogDeleteAction.perform(log, offerUndo: true)
        }
    }

    /// Delete from the edit form, once it has dismissed, with Undo. When that
    /// was the visit's last service the visit goes too — leave its screen.
    private func deleteIfRequested() {
        guard let log = logPendingDeletion else { return }
        logPendingDeletion = nil
        if visit.serviceCount <= 1 {
            // Delete once popped, so nothing on its way out reads the visit.
            deleteAfterPop = log
            dismiss()
        } else {
            ServiceLogDeleteAction.perform(log, offerUndo: true)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: Spacing.sm) {
            ServiceCategoryIcon(category: visit.costCategory)

            if let formattedTotal = visit.formattedTotalCost {
                Text(formattedTotal)
                    .font(.brutalistTitle)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            } else {
                Text(L10n.rowNoCostRecorded)
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.textSecondary)
            }

            Text(Formatters.mediumDate.string(from: visit.performedDate))
                .font(.brutalistSecondary)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.xl)
        .glassCardStyle(intensity: .subtle, padding: 0)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Details

    private var detailsSection: some View {
        InstrumentSection(title: L10n.formDetails) {
            VStack(spacing: 0) {
                if let formattedTotal = visit.formattedTotalCost {
                    BrutalistDataRow(label: L10n.servicesVisitTotal, value: formattedTotal, padding: Spacing.md)
                    ListDivider()
                }

                if let category = visit.costCategory {
                    BrutalistDataRow(label: L10n.formCategory, value: category.displayName, padding: Spacing.md)
                    ListDivider()
                }

                BrutalistDataRow(
                    label: L10n.formMileage,
                    value: Formatters.mileage(visit.mileageAtVisit),
                    padding: Spacing.md
                )

                if let shopName = visit.shopName, !shopName.isEmpty {
                    ListDivider()
                    BrutalistDataRow(label: L10n.servicesVisitShop, value: shopName, padding: Spacing.md)
                }
            }
        }
    }

    // MARK: - Services performed

    private func servicesSection(_ logs: [ServiceLog]) -> some View {
        InstrumentSection(title: L10n.servicesVisitServicesPerformed) {
            VStack(spacing: 0) {
                ForEach(logs) { log in
                    serviceRow(log: log)
                        .padding(.horizontal, Spacing.md)

                    if log.id != logs.last?.id {
                        ListDivider()
                    }
                }
            }
        }
    }

    /// Itemized with a cost: the amount. Otherwise the cost lives in the
    /// visit's total, and the row says so instead of showing nothing.
    private func serviceRow(log: ServiceLog) -> some View {
        let name = log.service?.name ?? L10n.rowServiceFallback
        let itemizedCost = visit.isItemized
            ? log.cost.flatMap { Formatters.currency.string(from: $0 as NSDecimalNumber) }
            : nil
        var metadata: [ServiceEventRow.Metadatum] = []
        if itemizedCost == nil {
            let note = visit.isItemized ? L10n.servicesVisitIncluded : L10n.servicesVisitIncludedInTotal
            metadata.append(.tag(note.uppercased(), color: Theme.textTertiary))
        }
        if let notes = log.notes, !notes.isEmpty {
            metadata.append(.detail(notes))
        }

        return ServiceEventRow(
            indicator: .completed(),
            title: name,
            metadata: metadata,
            amount: itemizedCost.map { .init(text: $0, color: Theme.accent) },
            onTap: { appState.push(.serviceLog(log)) }
        )
    }

    // MARK: - Notes

    private func notesSection(notes: String) -> some View {
        InstrumentSection(title: L10n.formNotes) {
            Text(notes.brutalistMarkdownAttributed)
                .font(.brutalistBody)
                .foregroundStyle(Theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Spacing.md)
        }
    }
}

#Preview {
    let vehicle = Vehicle.sampleVehicle
    let services = Service.sampleServices(for: vehicle)
    let visit = ServiceVisit(
        vehicle: vehicle,
        performedDate: .now,
        mileageAtVisit: 32500,
        totalCost: 320,
        costCategory: .maintenance,
        isItemized: false,
        shopName: "Bob's Auto",
        notes: "Bundled oil change, tire rotation, and air filter replacement."
    )
    let logs: [ServiceLog] = services.prefix(3).map { service in
        let log = ServiceLog(
            service: service,
            vehicle: vehicle,
            performedDate: .now,
            mileageAtService: 32500,
            cost: nil,
            costCategory: nil,
            notes: nil
        )
        log.visit = visit
        return log
    }
    visit.logs = logs

    return NavigationStack {
        ServiceVisitDetailView(visit: visit)
    }
    .modelContainer(for: [Vehicle.self, Service.self, ServiceLog.self, ServiceVisit.self, VisitLineItem.self, ServiceAttachment.self], inMemory: true)
    .environment(AppState())
    .preferredColorScheme(.dark)
}
