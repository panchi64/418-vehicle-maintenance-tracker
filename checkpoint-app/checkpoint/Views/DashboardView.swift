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
    @Query private var serviceLogs: [ServiceLog]

    @State private var selectedVehicle: Vehicle?
    @State private var showVehiclePicker = false
    @State private var showAddVehicle = false
    @State private var showAddService = false
    @State private var showEditVehicle = false
    @State private var selectedService: Service?

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

    /// Service logs for the current vehicle
    private var vehicleServiceLogs: [ServiceLog] {
        guard let vehicle = currentVehicle else { return [] }
        return serviceLogs.filter { $0.vehicle?.id == vehicle.id }
    }

    /// Recent service logs (last 3) for the current vehicle
    private var recentLogs: [ServiceLog] {
        vehicleServiceLogs
            .sorted { $0.performedDate > $1.performedDate }
            .prefix(3)
            .map { $0 }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Atmospheric Background
                AtmosphericBackground()

                ScrollView {
                    VStack(spacing: 0) {
                        // Header with vehicle info
                        headerSection
                            .padding(.top, Spacing.sm)
                            .revealAnimation(delay: 0.1)

                        // Main content
                        VStack(spacing: Spacing.xl) {
                            // Quick Specs Card (reference data at top)
                            if let vehicle = currentVehicle {
                                QuickSpecsCard(vehicle: vehicle) {
                                    showEditVehicle = true
                                }
                                .revealAnimation(delay: 0.15)
                            }

                            // Quick Mileage Update Card
                            if let vehicle = currentVehicle {
                                QuickMileageUpdateCard(vehicle: vehicle) { newMileage in
                                    updateMileage(newMileage, for: vehicle)
                                }
                                .revealAnimation(delay: 0.18)
                            }

                            // Next Up hero card
                            if let nextUp = nextUpService, let vehicle = currentVehicle {
                                VStack(alignment: .leading, spacing: Spacing.sm) {
                                    InstrumentSectionHeader(title: "Next Up")

                                    NavigationLink(value: nextUp) {
                                        NextUpCard(
                                            service: nextUp,
                                            currentMileage: vehicle.currentMileage,
                                            vehicleName: vehicle.displayName,
                                            dailyMilesPace: vehicle.dailyMilesPace
                                        ) {
                                            selectedService = nextUp
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                                .revealAnimation(delay: 0.2)
                            }

                            // Upcoming services list
                            if !remainingServices.isEmpty, let vehicle = currentVehicle {
                                VStack(alignment: .leading, spacing: Spacing.sm) {
                                    InstrumentSectionHeader(title: "Upcoming")

                                    VStack(spacing: 0) {
                                        ForEach(Array(remainingServices.enumerated()), id: \.element.name) { index, service in
                                            ServiceRow(
                                                service: service,
                                                currentMileage: vehicle.currentMileage
                                            ) {
                                                selectedService = service
                                            }
                                            .staggeredReveal(index: index, baseDelay: 0.3)

                                            if service.name != remainingServices.last?.name {
                                                Rectangle()
                                                    .fill(Theme.gridLine)
                                                    .frame(height: 1)
                                                    .padding(.leading, 56)
                                            }
                                        }
                                    }
                                    .background(Theme.surfaceInstrument)
                                    .overlay(
                                        Rectangle()
                                            .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
                                    )
                                }
                            }

                            // Recent Activity Feed
                            if !recentLogs.isEmpty {
                                RecentActivityFeed(serviceLogs: vehicleServiceLogs)
                                    .revealAnimation(delay: 0.4)
                            }

                            // Quick Stats Bar (YTD insights at bottom)
                            if currentVehicle != nil {
                                QuickStatsBar(serviceLogs: vehicleServiceLogs)
                                    .revealAnimation(delay: 0.45)
                            }

                            // Empty states
                            if vehicles.isEmpty {
                                emptyState
                                    .revealAnimation(delay: 0.2)
                            } else if vehicleServices.isEmpty && currentVehicle != nil {
                                noServicesState
                                    .revealAnimation(delay: 0.2)
                            }
                        }
                        .padding(.horizontal, Spacing.screenHorizontal)
                        .padding(.top, Spacing.lg)
                        .padding(.bottom, Spacing.xxl)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Service.self) { service in
                if let vehicle = currentVehicle {
                    ServiceDetailView(service: service, vehicle: vehicle)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                // Quick-add floating button
                if currentVehicle != nil {
                    Button {
                        showAddService = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Theme.backgroundPrimary)
                            .frame(width: 56, height: 56)
                            .background(Theme.accent)
                    }
                    .revealAnimation(delay: 0.5)
                    .padding(.trailing, Spacing.screenHorizontal)
                    .padding(.bottom, Spacing.lg)
                }
            }
        }
        .sheet(isPresented: $showVehiclePicker) {
            VehiclePickerSheet(
                selectedVehicle: $selectedVehicle,
                onAddVehicle: { showAddVehicle = true }
            )
        }
        .sheet(isPresented: $showAddVehicle) {
            AddVehicleView()
        }
        .sheet(isPresented: $showAddService) {
            if let vehicle = currentVehicle {
                AddServiceView(vehicle: vehicle)
            }
        }
        .sheet(item: $selectedService) { service in
            if let vehicle = currentVehicle {
                NavigationStack {
                    ServiceDetailView(service: service, vehicle: vehicle)
                }
            }
        }
        .sheet(isPresented: $showEditVehicle) {
            if let vehicle = currentVehicle {
                EditVehicleView(vehicle: vehicle)
            }
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
            VStack(alignment: .leading, spacing: 0) {
                // Vehicle name - brutalist monospace
                Text(currentVehicle?.displayName.uppercased() ?? "SELECT_VEHICLE")
                    .font(.brutalistTitle)
                    .foregroundStyle(Theme.textPrimary)

                // Mileage + model info
                if let vehicle = currentVehicle {
                    HStack(spacing: 0) {
                        Text(formatMileage(vehicle.currentMileage))
                            .font(.brutalistBody)
                            .foregroundStyle(Theme.accent)

                        Text(" // ")
                            .font(.brutalistSecondary)
                            .foregroundStyle(Theme.textTertiary)

                        Text("\(String(vehicle.year))_\(vehicle.make)_\(vehicle.model)".uppercased())
                            .font(.brutalistSecondary)
                            .foregroundStyle(Theme.textTertiary)

                        Spacer()

                        Text("[SELECT]")
                            .font(.brutalistLabel)
                            .foregroundStyle(Theme.accent)
                            .tracking(1)
                    }
                    .padding(.top, 4)
                }

                // Border
                Rectangle()
                    .fill(Theme.gridLine)
                    .frame(height: Theme.borderWidth)
                    .padding(.top, 12)
            }
            .padding(.horizontal, Theme.screenHorizontalPadding)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty States

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            ZStack {
                Rectangle()
                    .fill(Theme.accent.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "car.side.fill")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(Theme.accent)
            }

            VStack(spacing: Spacing.xs) {
                Text("NO_VEHICLES")
                    .font(.brutalistHeading)
                    .foregroundStyle(Theme.textPrimary)

                Text("Add your first vehicle to start\ntracking maintenance")
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Button("ADD_VEHICLE") {
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
                Rectangle()
                    .fill(Theme.accent.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "checkmark")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(Theme.accent)
            }

            VStack(spacing: Spacing.xs) {
                Text("ALL_CLEAR")
                    .font(.brutalistHeading)
                    .foregroundStyle(Theme.textPrimary)

                Text("No maintenance services scheduled\nfor this vehicle")
                    .font(.brutalistSecondary)
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

    /// Update mileage and create a snapshot (throttled to max 1 per day)
    private func updateMileage(_ newMileage: Int, for vehicle: Vehicle) {
        vehicle.currentMileage = newMileage
        vehicle.mileageUpdatedAt = .now

        // Create mileage snapshot (throttled: max 1 per day)
        let shouldCreateSnapshot = !MileageSnapshot.hasSnapshotToday(
            snapshots: vehicle.mileageSnapshots
        )

        if shouldCreateSnapshot {
            let snapshot = MileageSnapshot(
                vehicle: vehicle,
                mileage: newMileage,
                recordedAt: .now,
                source: .manual
            )
            modelContext.insert(snapshot)
        }
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
        .modelContainer(for: [Vehicle.self, Service.self, ServiceLog.self, ServicePreset.self, MileageSnapshot.self], inMemory: true)
        .preferredColorScheme(.dark)
}
