//
//  ServicesTab.swift
//  checkpoint
//
//  Services — Readout. "What's due, and what have I done?"
//
//  ONE LIST, NO MODE SWITCH. The tab used to keep a List/Timeline segmented
//  control plus a status filter — a row of chrome that hid half the tab behind
//  a mode, and a filter that re-derived what grouping by status gives for
//  free. Now it opens on what matters first and continues into history:
//
//    Overdue            1      status groups, most urgent first; the header
//    Due Soon           2      IS the status word, so rows show only the shape
//    On Track           2
//    July 2026                 history, by month
//    June 2026
//    Reference                 Document library › (a destination, not a mode)
//
//  An empty status group is omitted; the order of those that remain is fixed.
//  Search (`.searchable`) narrows the whole list. Row actions are swipes with
//  the same actions in the context menu (ServicesTab+Rows.swift). Select in
//  the toolbar enters edit mode, whose bottom bar carries the bulk actions
//  (ServicesTab+Selection.swift).
//

import SwiftUI
import SwiftData

struct ServicesTab: View {
    @Environment(AppState.self) var appState
    @Environment(\.modelContext) var modelContext
    let onboardingState: OnboardingState
    @Query private var services: [Service]
    @Query var serviceLogs: [ServiceLog]

    /// Tasks started from a row. Local, like Service Detail's: the root
    /// router has no case for editing a particular service or log.
    @State var sheet: ServicesTabSheet?
    /// A log whose edit form asked for it to be deleted, deleted once the form
    /// has dismissed (so the Undo toast isn't raised under a closing sheet).
    @State var logPendingDeletion: ServiceLog?
    @State var pendingDelete: ServicesPendingDelete?
    @State var exportPDFURL: URL?
    @State var isExporting = false

    /// Scopes the service + log fetches to `vehicle` at the database level, and
    /// lets the store return the history newest-first. Nothing downstream
    /// re-filters by vehicle: `$0.vehicle?.id` faults the relationship per row.
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

    var vehicle: Vehicle? {
        appState.selectedVehicle
    }

    private var searchText: String {
        appState.servicesTab.searchText
    }

    private func makeContent() -> ServicesTabContent {
        guard let vehicle else { return .empty }
        return .make(
            services: services,
            logs: serviceLogs,
            mileage: vehicle.mileageEstimate,
            searchText: searchText
        )
    }

    var body: some View {
        @Bindable var appState = appState
        let content = makeContent()

        Group {
            if let vehicle {
                if !content.isEmpty {
                    list(content, vehicle: vehicle)
                } else if !searchText.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    emptyState
                }
            } else {
                ContentUnavailableView(
                    L10n.emptyNoVehicleTitle,
                    systemImage: "car.side.fill",
                    description: Text(L10n.emptyNoVehicleMessage)
                )
            }
        }
        .searchable(text: $appState.servicesTab.searchText, prompt: L10n.servicesSearchPrompt)
        .onChange(of: appState.servicesTab.searchText) { oldValue, newValue in
            if oldValue.isEmpty && !newValue.isEmpty {
                AnalyticsService.shared.capture(.servicesSearchUsed)
            }
        }
        // Select only exists while there is something to select.
        .onChange(of: content.isEmpty, initial: true) { _, isEmpty in
            appState.servicesTab.hasSelectableContent = !isEmpty
            if isEmpty { appState.servicesTab.setSelecting(false) }
        }
        .onChange(of: vehicle?.id) {
            appState.servicesTab.setSelecting(false)
        }
        .toolbar { selectionToolbar(content) }
        .toolbar(appState.servicesTab.isSelecting ? .hidden : .automatic, for: .tabBar)
        .trackScreen(.services)
        .sheet(item: $sheet, onDismiss: sheetDismissed) { sheet in
            sheetContent(sheet)
        }
        .sheet(item: $exportPDFURL) { url in
            ShareSheet(items: [url])
        }
        // An alert, not a confirmation dialog: deletes start from swipes,
        // context menus, and the Select bar — no single control to anchor an
        // iOS 26 popover to, so a dialog here pointed at mid-screen.
        .alert(
            pendingDelete?.title ?? "",
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            ),
            presenting: pendingDelete
        ) { pending in
            Button(L10n.commonDelete, role: .destructive) {
                confirmDelete(pending, content: content)
            }
            Button(L10n.commonCancel, role: .cancel) {}
        } message: { pending in
            Text(pending.message)
        }
    }

    // MARK: - List

    private func list(_ content: ServicesTabContent, vehicle: Vehicle) -> some View {
        @Bindable var appState = appState

        return List(selection: $appState.servicesTab.selection) {
            ForEach(Array(content.statusGroups.enumerated()), id: \.element.id) { index, group in
                Section {
                    ForEach(group.services) { service in
                        serviceRow(service, mileage: content.mileage, vehicle: vehicle)
                    }
                } header: {
                    sectionHeader(
                        L10n.servicesGroupTitle(group.status),
                        count: group.services.count,
                        isTourTarget: index == 0 && onboardingState.currentPhase.isTour
                    )
                }
            }

            ForEach(content.months) { month in
                Section {
                    ForEach(month.logs) { log in
                        logRow(log, vehicle: vehicle)
                    }
                } header: {
                    sectionHeader(Self.monthTitle(month.month))
                }
            }

            // A destination, not a match — it would read as a search result.
            if searchText.isEmpty {
                referenceSection(vehicle: vehicle)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.editMode, Binding(
            get: { appState.servicesTab.isSelecting ? .active : .inactive },
            set: { appState.servicesTab.setSelecting($0.isEditing) }
        ))
        .animation(.default, value: appState.servicesTab.isSelecting)
    }

    /// "July 2026" — a header, so its first letter is capitalized even where
    /// the locale writes month names in lower case.
    static func monthTitle(_ month: Date) -> String {
        let title = month.formatted(.dateTime.month(.wide).year())
        return title.prefix(1).localizedUppercase + title.dropFirst()
    }

    /// The tour target goes inside `servicesListHeader()`: wrapped around it,
    /// its stateful modifier kept the header's row insets from reaching the
    /// List, and the first group's header sat off the others' leading edge.
    func sectionHeader(_ title: String, count: Int? = nil, isTourTarget: Bool = false) -> some View {
        InstrumentSectionHeader(title: title) {
            if let count {
                Text(verbatim: "\(count)")
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .tourTarget(.servicesStatusGroup, active: isTourTarget)
        .servicesListHeader()
    }

    // MARK: - Reference

    /// The documents library and the history export: destinations reachable
    /// from the bottom of the tab, which is what they always were.
    private func referenceSection(vehicle: Vehicle) -> some View {
        Section {
            NavigationLink(value: AppRoute.documents(vehicle)) {
                Label(L10n.servicesDocumentLibrary, systemImage: "doc.on.doc")
                    .font(.brutalistBodyEmphasis)
                    .foregroundStyle(Theme.textPrimary)
                    .frame(minHeight: TouchTarget.minimum, alignment: .leading)
            }
            .selectionDisabled()
            .servicesListRow()
        } header: {
            InstrumentSectionHeader(title: L10n.servicesReference) {
                if !serviceLogs.isEmpty {
                    ReadoutSectionAction(label: L10n.servicesExport, systemImage: "square.and.arrow.up") {
                        sheet = .export
                    }
                }
            }
            .servicesListHeader()
        }
    }

    // MARK: - Empty

    /// First run: one message, one action.
    private var emptyState: some View {
        ContentUnavailableView {
            Label(L10n.servicesEmptyTitle, systemImage: "wrench.and.screwdriver")
        } description: {
            Text(L10n.servicesEmptyMessage)
        } actions: {
            Button(L10n.servicesEmptyAdd) {
                appState.present(.addService())
            }
            .buttonStyle(.glassProminent)
            .tint(Theme.accent)
        }
    }

    // MARK: - Sheets

    /// Deleted from the edit-log form: delete now the form is gone, with Undo.
    /// (The edit forms refresh reminders, icon and widget on their own save.)
    private func sheetDismissed() {
        guard let log = logPendingDeletion else { return }
        logPendingDeletion = nil
        ServiceLogDeleteAction.perform(log, offerUndo: true)
    }
}

#Preview {
    let appState = AppState()
    appState.selectedVehicle = Vehicle.sampleVehicle

    return NavigationStack {
        ServicesTab(vehicle: appState.selectedVehicle, onboardingState: OnboardingState())
            .background { AtmosphericBackground() }
    }
    .environment(appState)
    .modelContainer(for: [Vehicle.self, Service.self, ServiceLog.self], inMemory: true)
    .preferredColorScheme(.dark)
}
