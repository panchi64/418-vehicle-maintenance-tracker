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
        .sheet(isPresented: $showEditSheet) {
            EditServiceView(service: service, vehicle: vehicle)
        }
        .sheet(isPresented: $showMarkDoneSheet) {
            MarkServiceDoneSheet(service: service, vehicle: vehicle)
        }
    }

    // MARK: - Status Card

    private var statusCard: some View {
        VStack(spacing: Spacing.md) {
            // Status badge
            HStack {
                Circle()
                    .fill(status.color)
                    .frame(width: 12, height: 12)
                Text(status.label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(status.color)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(status.color.opacity(0.15))
            .clipShape(Capsule())

            // Main urgency display
            if let description = service.dueDescription {
                Text(description)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
            }

            // Mileage info
            if let mileageDesc = service.mileageDescription {
                Text(mileageDesc)
                    .font(.bodySecondary)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.xl)
        .cardStyle()
    }

    // MARK: - Due Info Section

    private var dueInfoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("SCHEDULE")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)
                .tracking(1.2)

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
            .background(Theme.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.bodyText)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            Text(value)
                .font(.bodyText)
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
            Text("HISTORY")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)
                .tracking(1.2)

            VStack(spacing: 0) {
                ForEach(service.logs.sorted(by: { $0.performedDate > $1.performedDate })) { log in
                    historyRow(log: log)

                    if log.id != service.logs.sorted(by: { $0.performedDate > $1.performedDate }).last?.id {
                        Divider()
                            .padding(.leading, Spacing.md)
                    }
                }
            }
            .background(Theme.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func historyRow(log: ServiceLog) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(formatDate(log.performedDate))
                    .font(.bodyText)
                    .foregroundStyle(Theme.textPrimary)

                Text("\(formatMileage(log.mileageAtService))")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer()

            if let cost = log.formattedCost {
                Text(cost)
                    .font(.bodyText)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(Spacing.md)
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

    let service: Service
    let vehicle: Vehicle

    @State private var performedDate: Date = Date()
    @State private var mileage: String = ""
    @State private var cost: String = ""
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Service Details") {
                    DatePicker("Date Performed", selection: $performedDate, displayedComponents: .date)

                    HStack {
                        Text("Mileage")
                        Spacer()
                        TextField("Required", text: $mileage)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                        Text("mi")
                            .foregroundStyle(Theme.textSecondary)
                    }
                }

                Section("Optional") {
                    HStack {
                        Text("Cost")
                        Spacer()
                        Text("$")
                            .foregroundStyle(Theme.textSecondary)
                        TextField("0.00", text: $cost)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }

                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Mark as Done")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { markAsDone() }
                        .disabled(mileage.isEmpty)
                }
            }
            .onAppear {
                mileage = String(vehicle.currentMileage)
            }
        }
    }

    private func markAsDone() {
        let mileageInt = Int(mileage) ?? vehicle.currentMileage

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
        }

        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Vehicle.self, Service.self, ServiceLog.self, configurations: config)

    let vehicle = Vehicle(name: "Test Car", make: "Toyota", model: "Camry", year: 2022, currentMileage: 32500)
    container.mainContext.insert(vehicle)

    let service = Service(
        name: "Oil Change",
        dueDate: Calendar.current.date(byAdding: .day, value: 12, to: .now),
        dueMileage: 33000,
        intervalMonths: 6,
        intervalMiles: 5000
    )
    service.vehicle = vehicle
    container.mainContext.insert(service)

    return NavigationStack {
        ServiceDetailView(service: service, vehicle: vehicle)
    }
    .modelContainer(container)
    .preferredColorScheme(.dark)
}
