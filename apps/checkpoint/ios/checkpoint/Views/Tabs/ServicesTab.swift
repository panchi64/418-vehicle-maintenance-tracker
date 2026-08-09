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

    /// Scopes the service + log fetches to `vehicle` at the database level, and
    /// lets the store return the history newest-first. `appState` arrives through
    /// the environment.
    ///
    /// Because the predicate already scopes the fetch, nothing downstream
    /// re-filters by vehicle: `$0.vehicle?.id` faults the relationship for every
    /// row it touches, which is pure cost once the store has answered the same
    /// question.
    init(vehicle: Vehicle?, onboardingState: OnboardingState) {
        self.onboardingState = onboardingState
        if let vehicleID = vehicle?.id {
            _services = Query(filter: #Predicate<Service> { $0.vehicle?.id == vehicleID })
            _serviceLogs = Query(
                filter: #Predicate<ServiceLog> { $0.vehicle?.id == vehicleID },
                sort: \.performedDate,
                order: .reverse
            )
        } else {
            _services = Query(filter: #Predicate<Service> { _ in false })
            _serviceLogs = Query(filter: #Predicate<ServiceLog> { _ in false })
        }
    }

    private var vehicle: Vehicle? {
        appState.selectedVehicle
    }

    /// Everything this screen displays, derived in a single pass.
    ///
    /// These were computed properties, and SwiftUI reads each one several times
    /// per body evaluation — a count for the header, the array for the `ForEach`,
    /// the count again for the divider test. Every read re-ran the whole chain:
    /// urgency sort, status classification per row, search across notes and OCR
    /// text. Derived once and passed down, per the "derive a value once" rule.
    private struct Content {
        /// Every service, urgency-sorted — the timeline shows log-only ones too.
        let allServices: [Service]
        let filteredServices: [Service]
        let filteredLogs: [ServiceLog]
        let statusOptions: [PickerOption<StatusFilter>]
        let mileage: MileageEstimate
    }

    private func makeContent() -> Content {
        guard let vehicle else {
            return Content(
                allServices: [],
                filteredServices: [],
                filteredLogs: [],
                statusOptions: [],
                mileage: MileageEstimate(pace: nil, effective: 0, isEstimated: false)
            )
        }

        let mileage = vehicle.mileageEstimate
        let searchText = appState.servicesTab.searchText

        let allServices = services.sortedByUrgency(mileage)

        // Only services with due tracking have a status, so only they can be
        // status-filtered or counted.
        let tracked = allServices.filter { $0.hasDueTracking }

        // One status classification per service, reused by both the filter below
        // and the option counts. It used to be recomputed per row per pass.
        let statuses = tracked.map { $0.status(currentMileage: mileage.effective) }
        func count(_ status: ServiceStatus) -> Int {
            statuses.filter { $0 == status }.count
        }

        var filteredServices = tracked
        if let wanted = appState.servicesTab.statusFilter.serviceStatus {
            filteredServices = zip(tracked, statuses).filter { $0.1 == wanted }.map(\.0)
        }
        if !searchText.isEmpty {
            filteredServices = filteredServices.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }

        return Content(
            allServices: allServices,
            filteredServices: filteredServices,
            filteredLogs: Self.logs(serviceLogs, matching: searchText),
            statusOptions: [
                PickerOption(value: .all, label: StatusFilter.all.displayName, count: tracked.count),
                PickerOption(value: .overdue, label: StatusFilter.overdue.displayName, count: count(.overdue)),
                PickerOption(value: .dueSoon, label: StatusFilter.dueSoon.displayName, count: count(.dueSoon)),
                PickerOption(value: .good, label: StatusFilter.good.displayName, count: count(.good))
            ],
            mileage: mileage
        )
    }

    /// Search across service name, notes, and receipt OCR text. The logs arrive
    /// newest-first from the query, so there is no sort here.
    private static func logs(_ logs: [ServiceLog], matching searchText: String) -> [ServiceLog] {
        guard !searchText.isEmpty else { return logs }
        return logs.filter { log in
            // Search service name
            if log.service?.name.localizedCaseInsensitiveContains(searchText) ?? false {
                return true
            }
            // Search notes
            if log.notes?.localizedCaseInsensitiveContains(searchText) ?? false {
                return true
            }
            // Search extracted text from attachments (receipt OCR)
            if let attachments = log.attachments {
                for attachment in attachments {
                    if attachment.extractedText?.localizedCaseInsensitiveContains(searchText) ?? false {
                        return true
                    }
                }
            }
            return false
        }
    }

    var body: some View {
        @Bindable var appState = appState
        let content = makeContent()

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
                    options: content.statusOptions,
                    selection: $appState.servicesTab.statusFilter,
                    defaultValue: .all
                ) {
                    modeControl
                }
            } else {
                ControlRow { modeControl }
            }

            scrollContent(content)
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
                    // The whole history, not the search-narrowed list — and
                    // already newest-first from the query.
                    serviceLogs: serviceLogs,
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

    private func scrollContent(_ content: Content) -> some View {
        @Bindable var appState = appState
        return ScrollView {
            VStack(spacing: Spacing.xl) {
                BrutalistSearchField(
                    text: $appState.servicesTab.searchText,
                    onSearchStarted: {
                        AnalyticsService.shared.capture(.servicesSearchUsed)
                    }
                )
                .tourTarget(.servicesSearch, active: onboardingState.currentPhase.isTour)
                .revealAnimation(delay: 0.1)

                // Content based on view mode
                if appState.servicesTab.viewMode == .timeline, let vehicle = vehicle {
                    if serviceLogs.isEmpty {
                        EmptyStateView(
                            icon: "clock.arrow.circlepath",
                            title: L10n.emptyTimelineTitle,
                            message: L10n.emptyTimelineMessage
                        )
                        .revealAnimation(delay: 0.2)
                    } else {
                        MaintenanceTimeline(
                            services: content.allServices,
                            serviceLogs: serviceLogs,
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
                if appState.servicesTab.viewMode == .list && !content.filteredServices.isEmpty {
                    ReadoutSection(title: L10n.servicesScheduledCount(content.filteredServices.count)) {
                        VStack(spacing: 0) {
                            ForEach(Array(content.filteredServices.enumerated()), id: \.element.id) { index, service in
                                ServiceRow(
                                    service: service,
                                    // From the pass computed once above: reading
                                    // `vehicle.effectiveMileage` here re-derived
                                    // the driving pace on every row.
                                    currentMileage: content.mileage.effective,
                                    isEstimatedMileage: content.mileage.isEstimated
                                ) {
                                    appState.selectedService = service
                                }
                                .staggeredReveal(index: index, baseDelay: 0.2)

                                if index < content.filteredServices.count - 1 {
                                    ListDivider()
                                }
                            }
                        }
                    }
                }

                // Service History section (list mode only)
                if appState.servicesTab.viewMode == .list && !content.filteredLogs.isEmpty {
                    ReadoutSection(title: L10n.servicesHistoryCount(content.filteredLogs.count)) {
                        VStack(spacing: 0) {
                            ForEach(Array(content.filteredLogs.enumerated()), id: \.element.id) { index, log in
                                // ServiceEventRow owns its own tap target.
                                historyRow(log: log)
                                    .staggeredReveal(index: index, baseDelay: 0.3)

                                if index < content.filteredLogs.count - 1 {
                                    ListDivider()
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
                if appState.servicesTab.viewMode == .list && content.filteredServices.isEmpty && content.filteredLogs.isEmpty && vehicle != nil {
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
