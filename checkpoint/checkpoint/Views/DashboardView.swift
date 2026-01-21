//
//  DashboardView.swift
//  checkpoint
//
//  Main dashboard showing vehicle status and upcoming services
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var vehicles: [Vehicle]
    @Query private var services: [Service]

    @State private var selectedVehicle: Vehicle?
    @State private var showVehiclePicker = false
    @State private var showAddVehicle = false

    private var currentVehicle: Vehicle? {
        selectedVehicle ?? vehicles.first
    }

    private var vehicleServices: [Service] {
        guard let vehicle = currentVehicle else { return [] }
        return services
            .filter { $0.vehicle?.id == vehicle.id }
            .sorted { $0.urgencyScore(currentMileage: vehicle.currentMileage) < $1.urgencyScore(currentMileage: vehicle.currentMileage) }
    }

    private var nextUpService: Service? {
        vehicleServices.first
    }

    private var remainingServices: [Service] {
        Array(vehicleServices.dropFirst())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Theme.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Header with vehicle info
                        headerSection
                            .padding(.top, Spacing.sm)

                        // Main content
                        VStack(spacing: Spacing.xl) {
                            // Next Up hero card
                            if let nextUp = nextUpService, let vehicle = currentVehicle {
                                VStack(alignment: .leading, spacing: Spacing.sm) {
                                    sectionHeader("Next Up")

                                    NextUpCard(
                                        service: nextUp,
                                        currentMileage: vehicle.currentMileage,
                                        vehicleName: vehicle.displayName
                                    ) {
                                        // TODO: Navigate to service detail
                                    }
                                }
                            }

                            // Upcoming services list
                            if !remainingServices.isEmpty, let vehicle = currentVehicle {
                                VStack(alignment: .leading, spacing: Spacing.sm) {
                                    sectionHeader("Upcoming")

                                    VStack(spacing: 0) {
                                        ForEach(remainingServices, id: \.name) { service in
                                            ServiceRow(
                                                service: service,
                                                currentMileage: vehicle.currentMileage
                                            ) {
                                                // TODO: Navigate to service detail
                                            }

                                            if service.name != remainingServices.last?.name {
                                                Divider()
                                                    .background(Theme.borderSubtle.opacity(0.3))
                                                    .padding(.leading, 56)
                                            }
                                        }
                                    }
                                    .background(Theme.backgroundElevated)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .strokeBorder(Theme.borderSubtle.opacity(0.2), lineWidth: 1)
                                    )
                                }
                            }

                            // Empty states
                            if vehicles.isEmpty {
                                emptyState
                            } else if vehicleServices.isEmpty && currentVehicle != nil {
                                noServicesState
                            }
                        }
                        .padding(.horizontal, Spacing.screenHorizontal)
                        .padding(.top, Spacing.lg)
                        .padding(.bottom, Spacing.xxl)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showVehiclePicker) {
            VehiclePickerSheet(
                selectedVehicle: $selectedVehicle,
                onAddVehicle: { showAddVehicle = true }
            )
        }
        .onAppear {
            seedSampleDataIfNeeded()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        Button {
            showVehiclePicker = true
        } label: {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    // Vehicle name
                    Text(currentVehicle?.displayName ?? "Select Vehicle")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                        .tracking(-0.5)

                    // Mileage + model info
                    if let vehicle = currentVehicle {
                        HStack(spacing: 6) {
                            Text(formatMileage(vehicle.currentMileage))
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Theme.textSecondary)

                            Text("•")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.textTertiary)

                            Text("\(String(vehicle.year)) \(vehicle.make) \(vehicle.model)")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
                    .padding(.trailing, 4)
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.vertical, Spacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Theme.textTertiary)
            .tracking(1.2)
    }

    // MARK: - Empty States

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            ZStack {
                Circle()
                    .fill(Theme.accent.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "car.side.fill")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(Theme.accent)
            }

            VStack(spacing: Spacing.xs) {
                Text("No vehicles yet")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)

                Text("Add your first vehicle to start\ntracking maintenance")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Button("Add Vehicle") {
                showAddVehicle = true
            }
            .buttonStyle(.primary)
            .frame(width: 160)
            .padding(.top, Spacing.sm)
        }
        .padding(Spacing.xxl)
    }

    private var noServicesState: some View {
        VStack(spacing: Spacing.lg) {
            ZStack {
                Circle()
                    .fill(Theme.statusGood.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "checkmark")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(Theme.statusGood)
            }

            VStack(spacing: Spacing.xs) {
                Text("All caught up")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)

                Text("No maintenance services scheduled\nfor this vehicle")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .padding(Spacing.xxl)
    }

    // MARK: - Helpers

    private func formatMileage(_ miles: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return (formatter.string(from: NSNumber(value: miles)) ?? "\(miles)") + " mi"
    }

    // MARK: - Sample Data

    private func seedSampleDataIfNeeded() {
        guard vehicles.isEmpty else { return }

        let vehicle = Vehicle(
            name: "Daily Driver",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 32500
        )
        modelContext.insert(vehicle)

        let sampleServices = Service.sampleServices(for: vehicle)
        for service in sampleServices {
            modelContext.insert(service)
        }

        selectedVehicle = vehicle
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [Vehicle.self, Service.self], inMemory: true)
        .preferredColorScheme(.dark)
}
