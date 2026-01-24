//
//  ServicesTab.swift
//  checkpoint
//
//  Services tab showing full timeline, search, and history
//

import SwiftUI
import SwiftData

struct ServicesTab: View {
    @Environment(\.appState) private var appState
    @Query private var services: [Service]
    @Query private var serviceLogs: [ServiceLog]

    @State private var searchText = ""
    @State private var statusFilter: StatusFilter = .all

    enum StatusFilter: String, CaseIterable {
        case all = "All"
        case overdue = "Overdue"
        case dueSoon = "Due Soon"
        case good = "Good"
    }

    private var vehicle: Vehicle? {
        appState?.selectedVehicle
    }

    private var vehicleServices: [Service] {
        guard let vehicle = vehicle else { return [] }
        return services
            .filter { $0.vehicle?.id == vehicle.id }
            .sorted { $0.urgencyScore(currentMileage: vehicle.currentMileage) < $1.urgencyScore(currentMileage: vehicle.currentMileage) }
    }

    private var filteredServices: [Service] {
        guard let vehicle = vehicle else { return [] }

        var filtered = vehicleServices

        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }

        // Apply status filter
        switch statusFilter {
        case .all:
            break
        case .overdue:
            filtered = filtered.filter { $0.status(currentMileage: vehicle.currentMileage) == .overdue }
        case .dueSoon:
            filtered = filtered.filter { $0.status(currentMileage: vehicle.currentMileage) == .dueSoon }
        case .good:
            filtered = filtered.filter { $0.status(currentMileage: vehicle.currentMileage) == .good }
        }

        return filtered
    }

    private var vehicleServiceLogs: [ServiceLog] {
        guard let vehicle = vehicle else { return [] }
        return serviceLogs
            .filter { $0.vehicle?.id == vehicle.id }
            .sorted { $0.performedDate > $1.performedDate }
    }

    private var filteredLogs: [ServiceLog] {
        if searchText.isEmpty {
            return vehicleServiceLogs
        }
        return vehicleServiceLogs.filter { log in
            log.service?.name.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Search field
                    searchField
                        .revealAnimation(delay: 0.1)

                    // Status filter
                    InstrumentSegmentedControl(
                        options: StatusFilter.allCases,
                        selection: $statusFilter
                    ) { filter in
                        filter.rawValue
                    }
                    .revealAnimation(delay: 0.15)

                    // Upcoming services section
                    if !filteredServices.isEmpty, let vehicle = vehicle {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            InstrumentSectionHeader(title: "Scheduled Services")

                            VStack(spacing: 0) {
                                ForEach(Array(filteredServices.enumerated()), id: \.element.id) { index, service in
                                    NavigationLink(value: service) {
                                        ServiceRow(
                                            service: service,
                                            currentMileage: vehicle.currentMileage
                                        ) {
                                            // Empty - navigation handled by NavigationLink
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .staggeredReveal(index: index, baseDelay: 0.2)

                                    if index < filteredServices.count - 1 {
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

                    // Service History section
                    if !filteredLogs.isEmpty {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            InstrumentSectionHeader(title: "Service History")

                            VStack(spacing: 0) {
                                ForEach(Array(filteredLogs.enumerated()), id: \.element.id) { index, log in
                                    historyRow(log: log)
                                        .staggeredReveal(index: index, baseDelay: 0.3)

                                    if index < filteredLogs.count - 1 {
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
                    }

                    // Empty state
                    if filteredServices.isEmpty && filteredLogs.isEmpty && vehicle != nil {
                        emptyState
                            .revealAnimation(delay: 0.2)
                    }

                    // No vehicle state
                    if vehicle == nil {
                        noVehicleState
                            .revealAnimation(delay: 0.2)
                    }
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xxl + 56)
            }
            .navigationDestination(for: Service.self) { service in
                if let vehicle = vehicle {
                    ServiceDetailView(service: service, vehicle: vehicle)
                }
            }
        }
    }

    // MARK: - Search Field

    private var searchField: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Theme.textTertiary)

            TextField("Search services...", text: $searchText)
                .font(.brutalistBody)
                .foregroundStyle(Theme.textPrimary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
        }
        .padding(Spacing.md)
        .background(Theme.surfaceInstrument)
        .overlay(
            Rectangle()
                .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
        )
    }

    // MARK: - History Row

    private func historyRow(log: ServiceLog) -> some View {
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

                HStack(spacing: Spacing.xs) {
                    Text(formatDate(log.performedDate))
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.textTertiary)

                    Text("//")
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.gridLine)

                    Text(formatMileage(log.mileageAtService))
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.textTertiary)
                }
            }

            Spacer()

            if let cost = log.formattedCost {
                Text(cost)
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.accent)
            }
        }
        .padding(Spacing.md)
    }

    // MARK: - Empty States

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            ZStack {
                Rectangle()
                    .fill(Theme.accent.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: searchText.isEmpty ? "wrench.and.screwdriver" : "magnifyingglass")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(Theme.accent)
            }

            VStack(spacing: Spacing.xs) {
                Text(searchText.isEmpty ? "NO_SERVICES" : "NO_RESULTS")
                    .font(.brutalistHeading)
                    .foregroundStyle(Theme.textPrimary)

                Text(searchText.isEmpty ? "Add your first service to\nstart tracking maintenance" : "Try a different search term\nor filter")
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .padding(Spacing.xxl)
    }

    private var noVehicleState: some View {
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
                Text("NO_VEHICLE_SELECTED")
                    .font(.brutalistHeading)
                    .foregroundStyle(Theme.textPrimary)

                Text("Select or add a vehicle\nto view services")
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .padding(Spacing.xxl)
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    private func formatMileage(_ miles: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return (formatter.string(from: NSNumber(value: miles)) ?? "\(miles)") + " mi"
    }
}

#Preview {
    let appState = AppState()
    appState.selectedVehicle = Vehicle.sampleVehicle

    return ZStack {
        AtmosphericBackground()
        ServicesTab()
    }
    .environment(\.appState, appState)
    .modelContainer(for: [Vehicle.self, Service.self, ServiceLog.self], inMemory: true)
    .preferredColorScheme(.dark)
}
