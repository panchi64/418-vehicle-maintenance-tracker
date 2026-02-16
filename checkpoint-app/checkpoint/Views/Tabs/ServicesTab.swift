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
        return services.forVehicle(vehicle)
    }

    private var filteredServices: [Service] {
        guard let vehicle = vehicle else { return [] }

        // Only show services that have due tracking (exclude log-only/neutral services)
        var filtered = vehicleServices.filter { $0.hasDueTracking }
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

                    // Active filter indicator
                    if appState.servicesStatusFilter != .all || !appState.servicesSearchText.isEmpty {
                        HStack {
                            Text(L10n.emptyFilterShowing(filteredServices.count, vehicleServices.count).uppercased())
                                .font(.brutalistLabel)
                                .foregroundStyle(Theme.accent)
                                .tracking(1.5)

                            Spacer()

                            Button {
                                appState.servicesStatusFilter = .all
                                appState.servicesSearchText = ""
                            } label: {
                                Text(L10n.emptyFilterClear.uppercased())
                                    .font(.brutalistLabel)
                                    .foregroundStyle(Theme.accent)
                                    .tracking(1.5)
                            }
                            .buttonStyle(.instrument)
                        }
                    }
                }

                // Content based on view mode
                if appState.servicesViewMode == .timeline, let vehicle = vehicle {
                    if vehicleServiceLogs.isEmpty {
                        EmptyStateView(
                            icon: "clock.arrow.circlepath",
                            title: L10n.emptyTimelineTitle,
                            message: L10n.emptyTimelineMessage
                        )
                        .revealAnimation(delay: 0.2)
                    } else {
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
                }

                // Upcoming services section (list mode)
                if appState.servicesViewMode == .list && !filteredServices.isEmpty, let vehicle = vehicle {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        InstrumentSectionHeader(title: "Upcoming")

                        VStack(spacing: 0) {
                            ForEach(Array(filteredServices.enumerated()), id: \.element.id) { index, service in
                                ServiceRow(
                                    service: service,
                                    currentMileage: vehicle.effectiveMileage,
                                    isEstimatedMileage: vehicle.isUsingEstimatedMileage
                                ) {
                                    appState.selectedService = service
                                }
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
                                .frame(minHeight: 44)
                                .contentShape(Rectangle())
                            }
                            .accessibilityLabel("Export service history")
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
            .padding(.bottom, Spacing.xxl + Spacing.tabBarOffset)
        }
        .trackScreen(.services)
        .onChange(of: appState.servicesViewMode) { _, newMode in
            AnalyticsService.shared.capture(.servicesViewModeChanged(mode: newMode.rawValue))
        }
        .onChange(of: appState.servicesStatusFilter) { _, newFilter in
            AnalyticsService.shared.capture(.servicesFilterChanged(filter: newFilter.rawValue))
        }
        .sheet(isPresented: $showExportOptions) {
            if let vehicle = vehicle {
                ExportOptionsSheet(
                    vehicle: vehicle,
                    serviceLogs: vehicleServiceLogs,
                    isExporting: $isExporting
                ) { url in
                    AnalyticsService.shared.capture(.serviceHistoryExported)
                    exportPDFURL = url
                    ToastService.shared.show(L10n.toastPDFReady, icon: "doc.text", style: .info)
                }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
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
                .onChange(of: appState.servicesSearchText) { oldValue, _ in
                    if oldValue.isEmpty {
                        AnalyticsService.shared.capture(.servicesSearchUsed)
                    }
                }

            if !appState.servicesSearchText.isEmpty {
                Button {
                    appState.servicesSearchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.textTertiary)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Clear search")
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
                .accessibilityHidden(true)

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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(log.service?.name ?? "Service"), \(Formatters.mediumDate.string(from: log.performedDate))")
        .accessibilityValue(log.formattedCost ?? "")
        .accessibilityHint("Double tap to view details")
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
