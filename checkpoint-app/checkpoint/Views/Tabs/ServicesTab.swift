//
//  ServicesTab.swift
//  checkpoint
//
//  Services tab showing full timeline, search, and history
//

import SwiftUI
import SwiftData

struct ServicesTab: View {
    @Bindable var appState: AppState
    @Query private var services: [Service]
    @Query private var serviceLogs: [ServiceLog]

    @State private var showExportOptions = false
    @State private var exportPDFURL: URL?
    @State private var isExporting = false

    // Type aliases for cleaner code
    private typealias ViewMode = AppState.ServicesViewMode
    private typealias StatusFilter = AppState.ServicesStatusFilter

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

    private var filteredServices: [Service] {
        guard let vehicle = vehicle else { return [] }

        var filtered = vehicleServices
        let effectiveMileage = vehicle.effectiveMileage

        // Apply search filter
        if !appState.servicesSearchText.isEmpty {
            filtered = filtered.filter { $0.name.localizedCaseInsensitiveContains(appState.servicesSearchText) }
        }

        // Apply status filter
        switch appState.servicesStatusFilter {
        case .all:
            break
        case .overdue:
            filtered = filtered.filter { $0.status(currentMileage: effectiveMileage) == .overdue }
        case .dueSoon:
            filtered = filtered.filter { $0.status(currentMileage: effectiveMileage) == .dueSoon }
        case .good:
            filtered = filtered.filter { $0.status(currentMileage: effectiveMileage) == .good }
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
        if appState.servicesSearchText.isEmpty {
            return vehicleServiceLogs
        }
        return vehicleServiceLogs.filter { log in
            // Search service name
            if log.service?.name.localizedCaseInsensitiveContains(appState.servicesSearchText) ?? false {
                return true
            }
            // Search notes
            if log.notes?.localizedCaseInsensitiveContains(appState.servicesSearchText) ?? false {
                return true
            }
            // Search extracted text from attachments (receipt OCR)
            if let attachments = log.attachments {
                for attachment in attachments {
                    if attachment.extractedText?.localizedCaseInsensitiveContains(appState.servicesSearchText) ?? false {
                        return true
                    }
                }
            }
            return false
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Search field
                searchField
                    .revealAnimation(delay: 0.1)

                // View mode toggle
                InstrumentSegmentedControl(
                    options: ViewMode.allCases,
                    selection: $appState.servicesViewMode
                ) { mode in
                    mode.rawValue
                }
                .revealAnimation(delay: 0.12)

                // Status filter (only show in list mode)
                if appState.servicesViewMode == .list {
                    InstrumentSegmentedControl(
                        options: StatusFilter.allCases,
                        selection: $appState.servicesStatusFilter
                    ) { filter in
                        filter.rawValue
                    }
                    .revealAnimation(delay: 0.15)
                }

                // Content based on view mode
                if appState.servicesViewMode == .timeline, let vehicle = vehicle {
                    MaintenanceTimeline(
                        services: vehicleServices,
                        serviceLogs: vehicleServiceLogs,
                        vehicle: vehicle,
                        onServiceTap: { service in
                            appState.selectedService = service
                        },
                        onLogTap: { log in
                            appState.selectedServiceLog = log
                        }
                    )
                    .revealAnimation(delay: 0.2)
                }

                // Upcoming services section (list mode)
                if appState.servicesViewMode == .list && !filteredServices.isEmpty, let vehicle = vehicle {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        InstrumentSectionHeader(title: "Scheduled Services")

                        VStack(spacing: 0) {
                            ForEach(Array(filteredServices.enumerated()), id: \.element.id) { index, service in
                                Button {
                                    appState.selectedService = service
                                } label: {
                                    ServiceRow(
                                        service: service,
                                        currentMileage: vehicle.effectiveMileage,
                                        isEstimatedMileage: vehicle.isUsingEstimatedMileage
                                    ) {
                                        appState.selectedService = service
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .staggeredReveal(index: index, baseDelay: 0.2)

                                if index < filteredServices.count - 1 {
                                    ListDivider()
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

                // Service History section (list mode only)
                if appState.servicesViewMode == .list && !filteredLogs.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        InstrumentSectionHeader(title: "Service History") {
                            Button {
                                showExportOptions = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 11, weight: .medium))
                                    Text("EXPORT")
                                        .font(.brutalistLabel)
                                        .tracking(1)
                                }
                                .foregroundStyle(Theme.accent)
                            }
                        }

                        VStack(spacing: 0) {
                            ForEach(Array(filteredLogs.enumerated()), id: \.element.id) { index, log in
                                Button {
                                    appState.selectedServiceLog = log
                                } label: {
                                    historyRow(log: log)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .staggeredReveal(index: index, baseDelay: 0.3)

                                if index < filteredLogs.count - 1 {
                                    ListDivider(leadingPadding: 28)
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

                // Empty state (only in list mode when no content)
                if appState.servicesViewMode == .list && filteredServices.isEmpty && filteredLogs.isEmpty && vehicle != nil {
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
        .sheet(isPresented: $showExportOptions) {
            ExportOptionsSheet(
                vehicle: vehicle!,
                serviceLogs: vehicleServiceLogs,
                isExporting: $isExporting
            ) { url in
                exportPDFURL = url
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $exportPDFURL) { url in
            ShareSheet(items: [url])
        }
    }

    // MARK: - Search Field

    private var searchField: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Theme.textTertiary)

            TextField("Search services, notes, receipts...", text: $appState.servicesSearchText)
                .font(.brutalistBody)
                .foregroundStyle(Theme.textPrimary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if !appState.servicesSearchText.isEmpty {
                Button {
                    appState.servicesSearchText = ""
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
                    Text(Formatters.mediumDate.string(from: log.performedDate))
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.textTertiary)

                    Text("//")
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.gridLine)

                    Text(Formatters.mileage(log.mileageAtService))
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

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(Spacing.md)
    }

    // MARK: - Empty States

    private var emptyState: some View {
        EmptyStateView(
            icon: appState.servicesSearchText.isEmpty ? "wrench.and.screwdriver" : "magnifyingglass",
            title: appState.servicesSearchText.isEmpty ? "No Services" : "No Results",
            message: appState.servicesSearchText.isEmpty ? "Add your first service to\nstart tracking maintenance" : "Try a different search term\nor filter"
        )
    }

    private var noVehicleState: some View {
        EmptyStateView(
            icon: "car.side.fill",
            title: "No Vehicle",
            message: "Select or add a vehicle\nto view services"
        )
    }

}

#Preview {
    let appState = AppState()
    appState.selectedVehicle = Vehicle.sampleVehicle

    return ZStack {
        AtmosphericBackground()
        ServicesTab(appState: appState)
    }
    .modelContainer(for: [Vehicle.self, Service.self, ServiceLog.self], inMemory: true)
    .preferredColorScheme(.dark)
}
