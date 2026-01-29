//
//  HomeTab.swift
//  checkpoint
//
//  Home tab showing glanceable "what's next" overview
//

import SwiftUI
import SwiftData

struct HomeTab: View {
    @Bindable var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @Query private var services: [Service]
    @Query private var serviceLogs: [ServiceLog]

    // Recall alert state
    @State private var recalls: [RecallInfo] = []

    private var vehicle: Vehicle? {
        appState.selectedVehicle
    }

    private var vehicleServices: [Service] {
        guard let vehicle = vehicle else { return [] }
        let effectiveMileage = vehicle.effectiveMileage
        let pace = vehicle.dailyMilesPace
        return services
            .filter { $0.vehicle?.id == vehicle.id }
            .sorted { $0.urgencyScore(currentMileage: effectiveMileage, dailyPace: pace) < $1.urgencyScore(currentMileage: effectiveMileage, dailyPace: pace) }
    }

    private var nextUpService: Service? {
        vehicleServices.first
    }

    private var remainingServices: [Service] {
        Array(vehicleServices.dropFirst())
    }

    private var vehicleServiceLogs: [ServiceLog] {
        guard let vehicle = vehicle else { return [] }
        return serviceLogs.filter { $0.vehicle?.id == vehicle.id }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                // Recall Alert Card (safety-critical, shown above everything)
                if !recalls.isEmpty {
                    RecallAlertCard(recalls: recalls)
                        .revealAnimation(delay: 0.05)
                }

                // Quick Specs Card
                if let vehicle = vehicle {
                    QuickSpecsCard(vehicle: vehicle) {
                        appState.showEditVehicle = true
                    }
                    .revealAnimation(delay: 0.1)
                }

                // Quick Mileage Update Card (shown if never updated or 14+ days ago)
                if let vehicle = vehicle, vehicle.shouldPromptMileageUpdate {
                    QuickMileageUpdateCard(vehicle: vehicle) { newMileage in
                        updateMileage(newMileage, for: vehicle)
                    }
                    .revealAnimation(delay: 0.15)
                }

                // Next Up hero card
                if let nextUp = nextUpService, let vehicle = vehicle {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        InstrumentSectionHeader(title: "Next Up")

                        NextUpCard(
                            service: nextUp,
                            currentMileage: vehicle.effectiveMileage,
                            vehicleName: vehicle.displayName,
                            dailyMilesPace: vehicle.dailyMilesPace,
                            isEstimatedMileage: vehicle.isUsingEstimatedMileage
                        ) {
                            appState.selectedService = nextUp
                        }
                    }
                    .revealAnimation(delay: 0.2)
                }

                // Upcoming services list (max 3 for home tab)
                if !remainingServices.isEmpty, let vehicle = vehicle {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HStack {
                            InstrumentSectionHeader(title: "Upcoming")
                            Spacer()
                            if remainingServices.count > 3 {
                                Button {
                                    appState.navigateToServices()
                                } label: {
                                    Text("View All")
                                        .font(.brutalistLabel)
                                        .foregroundStyle(Theme.accent)
                                        .tracking(1)
                                }
                            }
                        }

                        VStack(spacing: 0) {
                            ForEach(Array(remainingServices.prefix(3).enumerated()), id: \.element.id) { index, service in
                                ServiceRow(
                                    service: service,
                                    currentMileage: vehicle.effectiveMileage,
                                    isEstimatedMileage: vehicle.isUsingEstimatedMileage
                                ) {
                                    appState.selectedService = service
                                }
                                .staggeredReveal(index: index, baseDelay: 0.25)

                                if index < min(remainingServices.count, 3) - 1 {
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

                // Recent Activity Feed (max 3, with VIEW_ALL)
                if !vehicleServiceLogs.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HStack {
                            InstrumentSectionHeader(title: "Recent Activity")
                            Spacer()
                            if vehicleServiceLogs.count > 3 {
                                Button {
                                    appState.navigateToServices()
                                } label: {
                                    Text("View All")
                                        .font(.brutalistLabel)
                                        .foregroundStyle(Theme.accent)
                                        .tracking(1)
                                }
                            }
                        }

                        VStack(spacing: 0) {
                            let recentLogs = vehicleServiceLogs
                                .sorted { $0.performedDate > $1.performedDate }
                                .prefix(3)

                            ForEach(Array(recentLogs.enumerated()), id: \.element.id) { index, log in
                                Button {
                                    appState.selectedServiceLog = log
                                } label: {
                                    activityRow(log: log)
                                }
                                .buttonStyle(.plain)

                                if index < recentLogs.count - 1 {
                                    Rectangle()
                                        .fill(Theme.gridLine)
                                        .frame(height: 1)
                                        .padding(.leading, 28)
                                }
                            }
                        }
                        .background(Theme.surfaceInstrument)
                        .overlay(
                            Rectangle()
                                .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
                        )
                    }
                    .revealAnimation(delay: 0.35)
                }

                // Quick Stats Bar
                if vehicle != nil {
                    QuickStatsBar(serviceLogs: vehicleServiceLogs)
                        .revealAnimation(delay: 0.4)
                }

                // Empty states
                if appState.selectedVehicle == nil {
                    emptyVehicleState
                        .revealAnimation(delay: 0.2)
                } else if vehicleServices.isEmpty && vehicle != nil {
                    noServicesState
                        .revealAnimation(delay: 0.2)
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.xxl + 56) // Extra padding for FAB and tab bar
        }
        .task(id: vehicle?.id) {
            await fetchRecalls()
        }
    }

    // MARK: - Activity Row

    private func activityRow(log: ServiceLog) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Theme.statusGood)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(log.service?.name ?? "Service")
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)

                Text(Formatters.shortDate.string(from: log.performedDate))
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textTertiary)
            }

            Spacer()

            if let cost = log.formattedCost {
                Text(cost)
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.accent)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(Spacing.md)
        .contentShape(Rectangle())
    }

    // MARK: - Empty States

    private var emptyVehicleState: some View {
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
                Text("No Vehicles")
                    .font(.brutalistHeading)
                    .foregroundStyle(Theme.textPrimary)

                Text("Add your first vehicle to start\ntracking maintenance")
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Button("Add Vehicle") {
                appState.showAddVehicle = true
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
                Text("All Clear")
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

    // MARK: - Recall Fetch

    private func fetchRecalls() async {
        guard let vehicle = vehicle,
              !vehicle.make.isEmpty,
              !vehicle.model.isEmpty,
              vehicle.year > 0 else {
            recalls = []
            return
        }

        do {
            recalls = try await NHTSAService.shared.fetchRecalls(
                make: vehicle.make,
                model: vehicle.model,
                year: vehicle.year
            )
        } catch {
            // Silently fail — recalls are supplementary info
            recalls = []
        }
    }

    // MARK: - Helpers

    private func updateMileage(_ newMileage: Int, for vehicle: Vehicle) {
        vehicle.currentMileage = newMileage
        vehicle.mileageUpdatedAt = .now

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

        // Force immediate save to trigger SwiftUI observation for dependent views
        try? modelContext.save()

        // Update app icon based on new mileage affecting service status
        AppIconService.shared.updateIcon(for: vehicle, services: services)

        // Reschedule mileage reminder for 14 days from now
        NotificationService.shared.scheduleMileageReminder(for: vehicle, lastUpdateDate: .now)

        // Reschedule service notifications with updated pace data
        NotificationService.shared.rescheduleNotifications(for: vehicle)
    }
}

#Preview {
    let appState = AppState()
    appState.selectedVehicle = Vehicle.sampleVehicle

    return ZStack {
        AtmosphericBackground()
        HomeTab(appState: appState)
    }
    .modelContainer(for: [Vehicle.self, Service.self, ServiceLog.self, MileageSnapshot.self], inMemory: true)
    .preferredColorScheme(.dark)
}
