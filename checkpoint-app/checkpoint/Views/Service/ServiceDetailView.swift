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
                // Status header card
                statusCard

                // Due info section
                dueInfoSection

                // Actions
                actionButtons

                // Service history
                if !(service.logs ?? []).isEmpty {
                    historySection
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
                .buttonStyle(.borderedProminent)
                .tint(Theme.textPrimary)
                .buttonBorderShape(.roundedRectangle(radius: 6))
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
            .padding(.horizontal, 12)
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
    }

    // MARK: - Due Info Section

    private var dueInfoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            InstrumentSectionHeader(title: "Schedule")

            VStack(spacing: 0) {
                if let dueDate = service.dueDate {
                    infoRow(title: "Due Date", value: formatDate(dueDate))
                    Divider()
                }

                if let dueMileage = service.dueMileage {
                    infoRow(title: "Due Mileage", value: formatMileage(dueMileage))
                    Divider()
                }

                if let intervalMonths = service.intervalMonths {
                    infoRow(title: "Repeat Every", value: "\(intervalMonths) months")
                    Divider()
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
            Button {
                showMarkDoneSheet = true
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Mark as Done")
                }
            }
            .buttonStyle(.primary)
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
                        Divider()
                            .padding(.leading, Spacing.md)
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
