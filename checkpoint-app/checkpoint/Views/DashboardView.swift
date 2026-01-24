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
    @State private var showAddService = false
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
                            // Next Up hero card
                            if let nextUp = nextUpService, let vehicle = currentVehicle {
                                VStack(alignment: .leading, spacing: Spacing.sm) {
                                    InstrumentSectionHeader(title: "Next Up")

                                    NavigationLink(value: nextUp) {
                                        NextUpCard(
                                            service: nextUp,
                                            currentMileage: vehicle.currentMileage,
                                            vehicleName: vehicle.displayName
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
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .strokeBorder(Theme.gridLine, lineWidth: 1)
                                    )
                                }
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
                            .foregroundStyle(Color(red: 0.071, green: 0.071, blue: 0.071))
                            .frame(width: 56, height: 56)
                            .background(Theme.accent)
                            .clipShape(Circle())
                            .shadow(color: Theme.accent.opacity(0.4), radius: 12, x: 0, y: 4)
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
        .onAppear {
            seedSampleDataIfNeeded()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        Button {
            showVehiclePicker = true
        } label: {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 4) {
                        // Vehicle name - Barlow SemiBold, all caps
                        Text(currentVehicle?.displayName.uppercased() ?? "SELECT VEHICLE")
                            .font(.instrumentMedium)
                            .foregroundStyle(Theme.textPrimary)
                            .tracking(1)

                        // Mileage + model info
                        if let vehicle = currentVehicle {
                            HStack(spacing: 8) {
                                Text(formatMileage(vehicle.currentMileage))
                                    .font(.instrumentMono)
                                    .foregroundStyle(Theme.accent)

                                Text("•")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Theme.textTertiary)

                                Text("\(String(vehicle.year)) \(vehicle.make) \(vehicle.model)")
                                    .font(.instrumentBody)
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

                // Thin amber accent line
                Rectangle()
                    .fill(Theme.accent.opacity(0.4))
                    .frame(height: 1)
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.vertical, Spacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
        .modelContainer(for: [Vehicle.self, Service.self, ServiceLog.self, ServicePreset.self], inMemory: true)
        .preferredColorScheme(.dark)
}
