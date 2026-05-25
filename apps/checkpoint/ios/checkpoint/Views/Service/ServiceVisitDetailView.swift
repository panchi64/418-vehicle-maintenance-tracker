//
//  ServiceVisitDetailView.swift
//  checkpoint
//
//  Detail view for a Service Visit — one shop visit, one honest total,
//  N child service logs.
//
//  Phase A renders:
//    - Header (date, odometer, total)
//    - Services performed list
//    - Visit notes (when present)
//    - Combined attachments from all child logs
//
//  Phases B/C add: per-service amounts when itemized, "Shop charge" residual
//  line, line items (parts/labor/tax/...), shop name. Phase D adds editing.
//

import SwiftUI
import SwiftData

struct ServiceVisitDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    @Bindable var visit: ServiceVisit

    @State private var attachmentForDetail: Document?

    private var sortedLogs: [ServiceLog] {
        (visit.logs ?? []).sorted { ($0.service?.name ?? "") < ($1.service?.name ?? "") }
    }

    private var allAttachments: [ServiceAttachment] {
        sortedLogs
            .flatMap { $0.attachments ?? [] }
            .sorted { $0.createdAt < $1.createdAt }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                header
                detailsSection
                servicesSection

                if let notes = visit.notes, !notes.isEmpty {
                    notesSection(notes: notes)
                }

                if !allAttachments.isEmpty {
                    AttachmentSection(
                        attachments: allAttachments,
                        onSelect: { attachmentForDetail = $0 }
                    )
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.vertical, Spacing.lg)
        }
        .background(Theme.backgroundPrimary)
        .navigationTitle("Service Visit")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                }
                .accessibilityLabel("Close")
            }
        }
        .sheet(item: $attachmentForDetail) { document in
            DocumentDetailView(document: document)
                .environment(appState)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: Spacing.sm) {
            if let category = visit.costCategory {
                Image(systemName: category.icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(category.color)
            } else {
                Image(systemName: "wrench.and.screwdriver")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(Theme.accent)
            }

            Text("SERVICE VISIT")
                .font(.brutalistLabel)
                .tracking(1)
                .foregroundStyle(Theme.textTertiary)

            if let formattedTotal = visit.formattedTotalCost {
                Text(formattedTotal)
                    .font(.brutalistTitle)
                    .foregroundStyle(Theme.textPrimary)
            } else {
                Text("No cost recorded")
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
        InstrumentSection(title: "Details") {
            VStack(spacing: 0) {
                if let formattedTotal = visit.formattedTotalCost {
                    BrutalistDataRow(label: "Total", value: formattedTotal, padding: Spacing.md)
                    ListDivider(leadingPadding: 0)
                }

                if let category = visit.costCategory {
                    BrutalistDataRow(label: "Category", value: category.displayName, padding: Spacing.md)
                    ListDivider(leadingPadding: 0)
                }

                BrutalistDataRow(
                    label: "Mileage",
                    value: Formatters.mileage(visit.mileageAtVisit),
                    padding: Spacing.md
                )

                if let shopName = visit.shopName, !shopName.isEmpty {
                    ListDivider(leadingPadding: 0)
                    BrutalistDataRow(label: "Shop", value: shopName, padding: Spacing.md)
                }
            }
        }
    }

    // MARK: - Services performed

    private var servicesSection: some View {
        InstrumentSection(title: "Services Performed (\(sortedLogs.count))") {
            VStack(spacing: 0) {
                ForEach(Array(sortedLogs.enumerated()), id: \.element.id) { index, log in
                    serviceRow(log: log)

                    if index < sortedLogs.count - 1 {
                        ListDivider(leadingPadding: 0)
                    }
                }
            }
        }
    }

    private func serviceRow(log: ServiceLog) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(log.service?.name.uppercased() ?? "—")
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.textPrimary)

                if let logNotes = log.notes, !logNotes.isEmpty {
                    Text(logNotes)
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer()

            Text(perServiceLabel(for: log))
                .font(.brutalistLabel)
                .tracking(1)
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(Spacing.md)
    }

    /// Per-service amount label.
    /// - Itemized + cost set → currency string
    /// - Itemized + cost nil → "INCLUDED"
    /// - Un-itemized → "INCLUDED IN VISIT"
    private func perServiceLabel(for log: ServiceLog) -> String {
        if visit.isItemized {
            if let cost = log.cost, let formatted = Formatters.currency.string(from: cost as NSDecimalNumber) {
                return formatted
            }
            return "INCLUDED"
        }
        return "INCLUDED IN VISIT"
    }

    // MARK: - Notes

    private func notesSection(notes: String) -> some View {
        InstrumentSection(title: "Notes") {
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
