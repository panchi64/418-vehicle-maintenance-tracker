//
//  ServicesTab.swift
//  checkpoint
//
//  Services tab showing full timeline, search, and history
//

import SwiftUI
import SwiftData

struct ServicesTab: View {
    @Environment(AppState.self) var appState
    let onboardingState: OnboardingState
    @Query private var services: [Service]
    @Query private var serviceLogs: [ServiceLog]

    @State private var showExportOptions = false
    @State private var exportPDFURL: URL? = nil
    @State private var isExporting = false

    // Type aliases for cleaner code
    private typealias ViewMode = ServicesTabState.ViewMode
    private typealias StatusFilter = ServicesTabState.StatusFilter

    /// Scopes the service + log fetches to `vehicle` at the database level.
    /// `appState` arrives through the environment.
    init(vehicle: Vehicle?, onboardingState: OnboardingState) {
        self.onboardingState = onboardingState
        if let vehicleID = vehicle?.id {
            _services = Query(filter: #Predicate<Service> { $0.vehicle?.id == vehicleID })
            _serviceLogs = Query(filter: #Predicate<ServiceLog> { $0.vehicle?.id == vehicleID })
        } else {
            _services = Query(filter: #Predicate<Service> { _ in false })
            _serviceLogs = Query(filter: #Predicate<ServiceLog> { _ in false })
        }
    }

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
        if !appState.servicesTab.searchText.isEmpty {
            filtered = filtered.filter { $0.name.localizedCaseInsensitiveContains(appState.servicesTab.searchText) }
        }

        // Apply status filter
        switch appState.servicesTab.statusFilter {
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
        if appState.servicesTab.searchText.isEmpty {
            return vehicleServiceLogs
        }
        return vehicleServiceLogs.filter { log in
            // Search service name
            if log.service?.name.localizedCaseInsensitiveContains(appState.servicesTab.searchText) ?? false {
                return true
            }
            // Search notes
            if log.notes?.localizedCaseInsensitiveContains(appState.servicesTab.searchText) ?? false {
                return true
            }
            // Search extracted text from attachments (receipt OCR)
            if let attachments = log.attachments {
                for attachment in attachments {
                    if attachment.extractedText?.localizedCaseInsensitiveContains(appState.servicesTab.searchText) ?? false {
                        return true
                    }
                }
            }
            return false
        }
    }

    /// Status options with live counts, so choosing a filter is informed rather
    /// than a guess followed by an empty list.
    private var statusOptions: [PickerOption<StatusFilter>] {
        let effectiveMileage = vehicle?.effectiveMileage ?? 0
        let tracked = vehicleServices.filter { $0.hasDueTracking }
        func count(_ status: ServiceStatus) -> Int {
            tracked.filter { $0.status(currentMileage: effectiveMileage) == status }.count
        }
        return [
            PickerOption(value: .all, label: StatusFilter.all.displayName, count: tracked.count),
            PickerOption(value: .overdue, label: StatusFilter.overdue.displayName, count: count(.overdue)),
            PickerOption(value: .dueSoon, label: StatusFilter.dueSoon.displayName, count: count(.dueSoon)),
            PickerOption(value: .good, label: StatusFilter.good.displayName, count: count(.good))
        ]
    }

    var body: some View {
        @Bindable var appState = appState

        // ONE row of pinned chrome, not four. Mode is the segmented control
        // because it changes what the screen *is*; status is a FilterControl
        // because filtering is refinement and does not deserve permanent real
        // estate. Search scrolls with the content rather than pinning a second
        // row above it — it is reached deliberately, not glanced at.
        VStack(spacing: 0) {
            // Status only exists for scheduled items, so the filter only exists
            // there too. A no-op control in Timeline mode costs a target and
            // answers nothing.
            if appState.servicesTab.viewMode == .list {
                FilterControlRow(
                    name: L10n.servicesStatusDimension,
                    options: statusOptions,
                    selection: $appState.servicesTab.statusFilter,
                    defaultValue: .all
                ) {
                    modeControl
                }
            } else {
                ControlRow { modeControl }
            }

            scrollContent
        }
        .trackScreen(.services)
        .onChange(of: appState.servicesTab.viewMode) { _, newMode in
            AnalyticsService.shared.capture(.servicesViewModeChanged(mode: newMode.rawValue))
        }
        .onChange(of: appState.servicesTab.statusFilter) { _, newFilter in
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

    private var modeControl: some View {
        @Bindable var appState = appState
        return InstrumentSegmentedControl(
            options: ViewMode.allCases,
            selection: $appState.servicesTab.viewMode
        ) { mode in
            mode.displayName
        }
    }

    private var scrollContent: some View {
        @Bindable var appState = appState
        return ScrollView {
            VStack(spacing: Spacing.xl) {
                ServiceSearchField(
                    text: $appState.servicesTab.searchText,
                    onSearchStarted: {
                        AnalyticsService.shared.capture(.servicesSearchUsed)
                    }
                )
                .tourTarget(.servicesSearch, active: onboardingState.currentPhase.isTour)
                .revealAnimation(delay: 0.1)

                // Content based on view mode
                if appState.servicesTab.viewMode == .timeline, let vehicle = vehicle {
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

                // Upcoming services (list mode). The bordered container is gone:
                // rows separated by dividers inside a titled section already
                // read as one group, and the box was one more enclosure
                // competing with the cards above it.
                if appState.servicesTab.viewMode == .list && !filteredServices.isEmpty, let vehicle = vehicle {
                    ReadoutSection(title: L10n.servicesScheduledCount(filteredServices.count)) {
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
                    }
                }

                // Service History section (list mode only)
                if appState.servicesTab.viewMode == .list && !filteredLogs.isEmpty {
                    ReadoutSection(title: L10n.servicesHistoryCount(filteredLogs.count)) {
                        VStack(spacing: 0) {
                            ForEach(Array(filteredLogs.enumerated()), id: \.element.id) { index, log in
                                // ServiceEventRow owns its own tap target.
                                historyRow(log: log)
                                    .staggeredReveal(index: index, baseDelay: 0.3)

                                if index < filteredLogs.count - 1 {
                                    ListDivider(leadingPadding: 28)
                                }
                            }
                        }
                    } action: {
                        ReadoutSectionAction(
                            label: L10n.servicesExport,
                            systemImage: "square.and.arrow.up"
                        ) {
                            showExportOptions = true
                        }
                    }
                }

                // Empty state (only in list mode when no content)
                if appState.servicesTab.viewMode == .list && filteredServices.isEmpty && filteredLogs.isEmpty && vehicle != nil {
                    emptyState
                        .revealAnimation(delay: 0.2)
                }

                // No vehicle state
                if vehicle == nil {
                    noVehicleState
                        .revealAnimation(delay: 0.2)
                }

                if vehicle != nil {
                    referenceSection
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.xxl + Spacing.tabBarOffset)
        }
    }

    // MARK: - Reference

    /// The documents library, as a destination rather than a view mode. It was a
    /// third segment of the mode control that, once selected, offered "OPEN
    /// LIBRARY" to leave for the real screen — so the mode existed only to host
    /// a link.
    private var referenceSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(L10n.servicesReference.uppercased())
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1.5)

            Button {
                appState.showDocuments = true
            } label: {
                Text("[\(L10n.servicesDocumentLibrary.uppercased())]")
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.accent)
                    .tracking(1)
                    .frame(minHeight: TouchTarget.minimum, alignment: .leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.servicesDocumentLibrary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - History Row

    /// Uses the shared `ServiceEventRow`. This was previously a hand-built
    /// HStack that had drifted from the otherwise-identical rows on Home and in
    /// Costs — different cost styling, different date format, hardcoded strings.
    private func historyRow(log: ServiceLog) -> some View {
        let name = log.service?.name ?? L10n.rowServiceFallback
        let date = Formatters.mediumDate.string(from: log.performedDate)

        return ServiceEventRow(
            indicator: .completed(),
            title: name,
            metadata: [
                .detail(date),
                .detail(Formatters.mileage(log.mileageAtService))
            ],
            amount: log.formattedCost.map { .init(text: $0, color: Theme.accent) },
            accessibilityLabelText: "\(name), \(date)",
            onTap: { appState.selectedServiceLog = log }
        )
    }

    // MARK: - Empty States

    /// "No services" and "nothing matches" are different facts, and saying the
    /// first when the second is true tells the user their data is gone. A status
    /// filter counts as narrowing just as much as a search term does — before
    /// filtering took one tap this was rarely wrong, and now it would be.
    private var isNarrowed: Bool {
        !appState.servicesTab.searchText.isEmpty || appState.servicesTab.statusFilter != .all
    }

    private var emptyState: some View {
        EmptyStateView(
            icon: isNarrowed ? "magnifyingglass" : "wrench.and.screwdriver",
            title: isNarrowed ? L10n.emptyNoResultsTitle : L10n.emptyNoServicesTitle,
            message: isNarrowed ? L10n.emptyNoResultsMessage : L10n.emptyNoServicesMessage
        )
    }

    private var noVehicleState: some View {
        EmptyStateView(
            icon: "car.side.fill",
            title: L10n.emptyNoVehicleTitle,
            message: L10n.emptyNoVehicleMessage
        )
    }

}

#Preview {
    let appState = AppState()
    appState.selectedVehicle = Vehicle.sampleVehicle

    return ZStack {
        AtmosphericBackground()
        ServicesTab(vehicle: appState.selectedVehicle, onboardingState: OnboardingState())
    }
    .environment(appState)
    .modelContainer(for: [Vehicle.self, Service.self, ServiceLog.self], inMemory: true)
    .preferredColorScheme(.dark)
}
