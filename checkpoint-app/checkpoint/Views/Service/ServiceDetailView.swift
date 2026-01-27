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
                if !service.logs.isEmpty {
                    historySection
                }

                // Attachments from most recent log
                if let latestLog = service.logs.sorted(by: { $0.performedDate > $1.performedDate }).first,
                   !latestLog.attachments.isEmpty {
                    AttachmentSection(attachments: latestLog.attachments)
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
            }
        }
        .sheet(isPresented: $showEditSheet, onDismiss: { updateAppIcon(); updateWidgetData() }) {
            EditServiceView(service: service, vehicle: vehicle)
        }
        .sheet(isPresented: $showMarkDoneSheet, onDismiss: { updateAppIcon(); updateWidgetData() }) {
            MarkServiceDoneSheet(service: service, vehicle: vehicle)
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
                ForEach(service.logs.sorted(by: { $0.performedDate > $1.performedDate })) { log in
                    historyRow(log: log)

                    if log.id != service.logs.sorted(by: { $0.performedDate > $1.performedDate }).last?.id {
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
                Text(formatDate(log.performedDate))
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.textPrimary)

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
        }
        .padding(Spacing.md)
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
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return (formatter.string(from: NSNumber(value: miles)) ?? "\(miles)") + " mi"
    }
}

// MARK: - Mark Service Done Sheet

struct MarkServiceDoneSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var services: [Service]

    let service: Service
    let vehicle: Vehicle

    @State private var performedDate: Date = Date()
    @State private var mileage: Int? = nil
    @State private var cost: String = ""
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
                        .font(.brutalistBody)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { markAsDone() }
                        .font(.brutalistBody)
                        .disabled(mileage == nil)
                }
            }
            .onAppear {
                mileage = vehicle.currentMileage
            }
        }
    }

    private func markAsDone() {
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
                mimeType: attachmentData.mimeType
            )
            modelContext.insert(attachment)
        }

        // Update service with new due dates
        service.lastPerformed = performedDate
        service.lastMileage = mileageInt

        if let months = service.intervalMonths, months > 0 {
            service.dueDate = Calendar.current.date(byAdding: .month, value: months, to: performedDate)
        }
        if let miles = service.intervalMiles, miles > 0 {
            service.dueMileage = mileageInt + miles
        }

        // Update vehicle mileage if service mileage is higher
        if mileageInt > vehicle.currentMileage {
            vehicle.currentMileage = mileageInt
            vehicle.mileageUpdatedAt = performedDate
        }

        // Create mileage snapshot for pace calculation (throttled: max 1 per day)
        let shouldCreateSnapshot = !MileageSnapshot.hasSnapshotToday(
            snapshots: vehicle.mileageSnapshots
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

    NavigationStack {
        ServiceDetailView(service: service, vehicle: vehicle)
    }
    .modelContainer(for: [Vehicle.self, Service.self, ServiceLog.self, MileageSnapshot.self], inMemory: true)
    .preferredColorScheme(.dark)
}
