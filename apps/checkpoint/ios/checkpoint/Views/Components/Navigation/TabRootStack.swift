//
//  TabRootStack.swift
//  checkpoint
//
//  One tab's navigation stack and the chrome every tab root shares. System
//  shell, brand content: the bar, title, menu and buttons are native, so they
//  sit where iOS users look for them (AESTHETIC.md: "Native placement wins"
//  for apps); the theme, JetBrains Mono and readout styling stay in the content
//  underneath.
//
//    ⚙  │        Daily Driver ⌄        │  [+]
//   Settings    title menu: switch,       add service — the one
//               add, manage vehicles      prominent action
//
//  The vehicle name is the title, and switching lives in its title menu. That
//  replaced `VehicleHeader`, a custom band above every tab that carried the
//  name, a [SELECT] control and a gear; its odometer/specs cells moved into
//  Home's content (`VehicleSummaryBand`).
//

import SwiftUI

struct TabRootStack<Root: View>: View {
    let tab: Tab
    let vehicles: [Vehicle]
    @ViewBuilder let root: () -> Root

    @Environment(AppState.self) private var appState

    private var syncError: SyncError? {
        SyncStatusService.shared.currentError
    }

    var body: some View {
        NavigationStack(path: Binding(
            get: { appState.paths[tab] ?? [] },
            set: { appState.paths[tab] = $0 }
        )) {
            root()
                .background { AtmosphericBackground() }
                .navigationTitle(appState.selectedVehicle?.displayName ?? L10n.headerSelectVehicleAccessibility)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarTitleMenu { vehicleMenu }
                .toolbar { rootToolbar }
                .navigationDestination(for: AppRoute.self) { route in
                    AppRouteDestination(route: route)
                }
        }
    }

    // MARK: - Title menu

    @ViewBuilder
    private var vehicleMenu: some View {
        if !vehicles.isEmpty {
            // An inline picker gives the current vehicle the system checkmark.
            Picker(selection: Binding(
                get: { appState.selectedVehicle?.id },
                set: { id in appState.selectVehicle(vehicles.first { $0.id == id }) }
            )) {
                ForEach(vehicles) { vehicle in
                    Text(vehicle.displayName).tag(Optional(vehicle.id))
                }
            } label: {
                EmptyView()
            }
            .pickerStyle(.inline)
        }

        Section {
            Button {
                appState.requestAddVehicle(vehicleCount: vehicles.count)
            } label: {
                Label(L10n.vehicleAdd, systemImage: "plus")
            }

            if !vehicles.isEmpty {
                Button {
                    appState.present(.vehiclePicker)
                } label: {
                    Label(L10n.navManageVehicles, systemImage: "car.2")
                }
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var rootToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                appState.present(.settings)
            } label: {
                // A sync problem shows on the way into Settings, where it is
                // explained, rather than as a second button beside it.
                Image(systemName: syncError?.systemImage ?? "gearshape")
                    .foregroundStyle(syncError?.iconColor ?? Theme.textSecondary)
            }
            .accessibilityLabel(L10n.settingsTitle)
            .accessibilityValue(syncError == nil ? "" : L10n.toastSyncError)
            .accessibilityIdentifier("toolbar.settings")
        }

        // ONE add action, going straight to the unified form: the form derives
        // record-vs-schedule from its date, so there is nothing to choose first.
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                HapticService.shared.lightImpact()
                appState.present(.addService())
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(.glassProminent)
            .tint(Theme.accent)
            .disabled(appState.selectedVehicle == nil)
            .accessibilityLabel(L10n.tabBarAddService)
            .accessibilityIdentifier("toolbar.addService")
        }
    }
}

// MARK: - Destinations

/// The screen for each pushed `AppRoute`.
struct AppRouteDestination: View {
    let route: AppRoute

    @Environment(AppState.self) private var appState

    var body: some View {
        switch route {
        case .service(let service):
            if let vehicle = service.vehicle ?? appState.selectedVehicle {
                ServiceDetailView(service: service, vehicle: vehicle)
            }
        case .serviceLog(let log):
            ServiceLogDestination(log: log)
        case .visit(let visit):
            ServiceVisitDetailView(visit: visit)
        case .document(let document):
            DocumentDetailView(document: document)
        case .documents(let vehicle):
            DocumentsView(vehicle: vehicle)
        }
    }
}

/// A pushed log detail that deletes its log only after it has popped: a model
/// deleted while its screen is still animating away can be read by a view that
/// no longer has it. Deletion offers Undo — the toast renders above everything.
private struct ServiceLogDestination: View {
    let log: ServiceLog

    @State private var pendingDeletion: ServiceLog?

    var body: some View {
        ServiceLogDetailView(log: log, onDelete: { pendingDeletion = $0 })
            .onDisappear {
                guard let log = pendingDeletion else { return }
                pendingDeletion = nil
                ServiceLogDeleteAction.perform(log, offerUndo: true)
            }
    }
}
