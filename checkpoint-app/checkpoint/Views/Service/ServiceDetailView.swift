//
//  ServiceDetailView.swift
//  checkpoint
//
//  Detailed view for a service showing status, actions, and history
//

import SwiftUI
import SwiftData

struct ServiceDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var services: [Service]

    @Bindable var service: Service
    let vehicle: Vehicle

    @State private var showEditSheet = false
    @State private var showMarkDoneSheet = false
    @State private var didCompleteMark = false
    @State private var selectedLog: ServiceLog?

    private var status: ServiceStatus {
        service.status(currentMileage: vehicle.currentMileage)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                // Status header card (hide for log-only/neutral services)
                if status != .neutral {
                    statusCard
                }

                // Due info section (hide for log-only services with no schedule data)
                if service.dueDate != nil || service.dueMileage != nil || service.intervalMonths != nil || service.intervalMiles != nil {
                    dueInfoSection
                }

                // Actions
                actionButtons

                // Service history
                if !(service.logs ?? []).isEmpty {
                    historySection
                }

                // Insights (only when there's history)
                if !(service.logs ?? []).isEmpty {
                    insightsSection
                }

                // Attachments from all logs
                let allAttachments = (service.logs ?? [])
                    .sorted(by: { $0.performedDate > $1.performedDate })
                    .flatMap { $0.attachments ?? [] }
                if !allAttachments.isEmpty {
                    AttachmentSection(attachments: allAttachments)
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.vertical, Spacing.lg)
        }
        .trackScreen(.serviceDetail)
        .background(Theme.backgroundPrimary)
        .navigationTitle(service.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showEditSheet = true
                } label: {
                    Image(systemName: "pencil")
                }
                .toolbarButtonStyle()
                .accessibilityLabel("Edit service")
            }
        }
        .sheet(isPresented: $showEditSheet, onDismiss: { updateAppIcon(); updateWidgetData() }) {
            EditServiceView(service: service, vehicle: vehicle)
        }
        .sheet(isPresented: $showMarkDoneSheet, onDismiss: {
            updateAppIcon()
            updateWidgetData()
            if didCompleteMark {
                didCompleteMark = false
                dismiss()
            }
        }) {
            MarkServiceDoneSheet(service: service, vehicle: vehicle, onSaved: {
                didCompleteMark = true
            })
        }
        .sheet(item: $selectedLog) { log in
            NavigationStack {
                ServiceLogDetailView(log: log)
            }
        }
    }

    // MARK: - Status Card

    private var statusCard: some View {
        VStack(spacing: Spacing.md) {
            // Status badge (brutalist: square indicator, rectangle background)
            HStack {
                Rectangle()
                    .fill(status.color)
                    .frame(width: 8, height: 8)
                    .statusGlow(color: status.color, isActive: status == .overdue || status == .dueSoon)
                Text(status.label)
                    .font(.brutalistLabel)
                    .foregroundStyle(status.color)
                    .textCase(.uppercase)
                    .tracking(1.5)
            }
            .padding(.horizontal, Spacing.listItem)
            .padding(.vertical, 6)
            .background(status.color.opacity(0.15))
            .clipShape(Rectangle())

            // Main urgency display - miles first
            if let description = service.primaryDescription {
                Text(description)
                    .font(.brutalistTitle)
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)
            }

            // Date info (secondary, only shown if mileage tracking exists)
            if service.dueMileage != nil, let dateDesc = service.dueDescription {
                Text(dateDesc)
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.xl)
        .glassCardStyle(intensity: .subtle, padding: 0)
        .padding(Spacing.xl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Status: \(status.label)")
        .accessibilityValue(service.primaryDescription ?? service.dueDescription ?? "")
    }

    // MARK: - Due Info Section

    private var dueInfoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            InstrumentSectionHeader(title: "Schedule")

            VStack(spacing: 0) {
                if let dueDate = service.dueDate {
                    infoRow(title: "Due Date", value: formatDate(dueDate))
                    ListDivider(leadingPadding: 0)
                }

                if let dueMileage = service.dueMileage {
                    infoRow(title: "Due Mileage", value: formatMileage(dueMileage))
                    ListDivider(leadingPadding: 0)
                }

                if let intervalMonths = service.intervalMonths {
                    infoRow(title: "Repeat Every", value: "\(intervalMonths) months")
                    ListDivider(leadingPadding: 0)
                }

                if let intervalMiles = service.intervalMiles {
                    infoRow(title: "Or Every", value: formatMileage(intervalMiles))
                }
            }
            .background(Theme.surfaceInstrument)
            .clipShape(Rectangle())
            .overlay(
                Rectangle()
                    .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
            )
        }
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title.uppercased())
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1)
            Spacer()
            Text(value)
                .font(.brutalistBody)
                .foregroundStyle(Theme.textPrimary)
        }
        .padding(Spacing.md)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: Spacing.sm) {
            if status == .neutral {
                Button {
                    showEditSheet = true
                } label: {
                    HStack {
                        Image(systemName: "bell.badge")
                        Text("Set Up Reminder")
                    }
                }
                .buttonStyle(.primary)
                .accessibilityLabel("Set up reminder")
                .accessibilityHint("Opens edit form to configure due dates")
            } else {
                Button {
                    showMarkDoneSheet = true
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Mark as Done")
                    }
                }
                .buttonStyle(.primary)
                .accessibilityLabel("Mark as done")
                .accessibilityHint("Opens service completion form")
            }
        }
    }

    // MARK: - History Section

    private var historySection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            InstrumentSectionHeader(title: "History")

            VStack(spacing: 0) {
                let sortedLogs = (service.logs ?? []).sorted(by: { $0.performedDate > $1.performedDate })
                ForEach(sortedLogs) { log in
                    Button {
                        selectedLog = log
                    } label: {
                        historyRow(log: log)
                    }
                    .buttonStyle(.plain)

                    if log.id != sortedLogs.last?.id {
                        ListDivider(leadingPadding: Spacing.md)
                    }
                }
            }
            .background(Theme.surfaceInstrument)
            .clipShape(Rectangle())
            .overlay(
                Rectangle()
                    .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
            )
        }
    }

    private func historyRow(log: ServiceLog) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Spacing.xs) {
                    Text(formatDate(log.performedDate))
                        .font(.brutalistBody)
                        .foregroundStyle(Theme.textPrimary)

                    if !(log.attachments ?? []).isEmpty {
                        Image(systemName: "paperclip")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }

                Text("\(formatMileage(log.mileageAtService))")
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.textTertiary)
            }

            Spacer()

            if let cost = log.formattedCost {
                Text(cost)
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.textSecondary)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(Spacing.md)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Service on \(formatDate(log.performedDate)), \(formatMileage(log.mileageAtService))")
        .accessibilityValue(log.formattedCost ?? "No cost")
        .accessibilityHint("Double tap to view details")
    }

    // MARK: - Insights Section

    private var insightsSection: some View {
        let sortedLogs = (service.logs ?? []).sorted(by: { $0.performedDate > $1.performedDate })

        return VStack(alignment: .leading, spacing: Spacing.md) {
            InstrumentSectionHeader(title: "Insights")

            VStack(spacing: 0) {
                // Time since last
                if let lastLog = sortedLogs.first {
                    infoRow(
                        title: "Time Since Last",
                        value: TimeSinceFormatter.full(from: lastLog.performedDate)
                    )
                    ListDivider(leadingPadding: 0)

                    // Miles since last
                    let milesSince = vehicle.currentMileage - lastLog.mileageAtService
                    if milesSince >= 0 {
                        infoRow(
                            title: "Miles Since Last",
                            value: Formatters.mileage(milesSince)
                        )
                        ListDivider(leadingPadding: 0)
                    }
                }

                // Average cost
                let logsWithCost = sortedLogs.filter { $0.cost != nil }
                if !logsWithCost.isEmpty {
                    let totalCost = logsWithCost.compactMap { $0.cost }.reduce(Decimal.zero, +)
                    let averageCost = totalCost / Decimal(logsWithCost.count)
                    infoRow(
                        title: "Average Cost",
                        value: Formatters.currency.string(from: averageCost as NSDecimalNumber) ?? "$0"
                    )
                    ListDivider(leadingPadding: 0)
                }

                // Times serviced
                infoRow(
                    title: "Times Serviced",
                    value: "\(sortedLogs.count)"
                )
            }
            .background(Theme.surfaceInstrument)
            .clipShape(Rectangle())
            .overlay(
                Rectangle()
                    .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
            )
        }
    }

    // MARK: - App Icon

    private func updateAppIcon() {
        AppIconService.shared.updateIcon(for: vehicle, services: services)
    }

    // MARK: - Widget Data

    private func updateWidgetData() {
        WidgetDataService.shared.updateWidget(for: vehicle)
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func formatMileage(_ miles: Int) -> String {
        Formatters.mileage(miles)
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

    NavigationStack {
        ServiceDetailView(service: service, vehicle: vehicle)
    }
    .modelContainer(for: [Vehicle.self, Service.self, ServiceLog.self, MileageSnapshot.self], inMemory: true)
    .preferredColorScheme(.dark)
}
