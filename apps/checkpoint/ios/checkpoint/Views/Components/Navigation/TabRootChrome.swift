//
//  TabRootChrome.swift
//  checkpoint
//
//  The chrome every tab root shares, in a stack or in a split view's list
//  column. System shell, brand content: the bar, title, menu and buttons are
//  native, so they sit where iOS users look for them (AESTHETIC.md: "Native
//  placement wins" for apps); the theme, JetBrains Mono and readout styling
//  stay in the content underneath.
//
//    ⚙  │        Daily Driver ⌄        │  [+]
//   Settings    title menu: switch,       add service — the one
//     ⌘,        add, manage vehicles      prominent action, ⌘N
//
//  The vehicle name is the title, and switching lives in its title menu. That
//  replaced `VehicleHeader`, a custom band above every tab that carried the
//  name, a [SELECT] control and a gear; its odometer/specs cells moved into
//  Home's content (`VehicleSummaryBand`).
//

import SwiftUI

private struct TabRootChrome: ViewModifier {
    let tab: Tab
    let vehicles: [Vehicle]
    let includesActions: Bool

    @Environment(AppState.self) private var appState

    /// Only failures worth interrupting every tab for. Not being signed in to
    /// iCloud is a choice, and being offline passes on its own; both are
    /// explained in Settings' sync row, and flagging them here put a red alarm
    /// on every screen for users who simply don't use iCloud.
    private var syncError: SyncError? {
        guard let error = SyncStatusService.shared.currentError else { return nil }
        switch error {
        case .notSignedIn, .networkUnavailable: return nil
        case .quotaExceeded, .unknown: return error
        }
    }

    func body(content: Content) -> some View {
        content
            .background { AtmosphericBackground() }
            .navigationTitle(appState.selectedVehicle?.displayName ?? L10n.headerSelectVehicleAccessibility)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarTitleMenu { vehicleMenu }
            .toolbar { rootToolbar }
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
                // A titled Label, drawn icon-only: see `ToolbarTextButton`.
                Label(L10n.settingsTitle, systemImage: syncError?.systemImage ?? "gearshape")
                    .foregroundStyle(syncError?.iconColor ?? Theme.textSecondary)
            }
            .keyboardShortcut(",", modifiers: .command)
            .accessibilityValue(syncError == nil ? "" : L10n.toastSyncError)
            .accessibilityIdentifier("toolbar.settings")
        }

        if includesActions {
            TabRootActions(tab: tab, appState: appState)
        }
    }
}

/// The trailing actions: Select (Services) and the prominent add. In a stack
/// they end the root's bar. Beside a list they end the DETAIL column's bar
/// instead: on iPad the floating tab bar sits over the list column's trailing
/// edge, and the window's trailing edge is where iPad puts the primary action.
struct TabRootActions: ToolbarContent {
    let tab: Tab
    let appState: AppState

    var body: some ToolbarContent {
        // Services only: Select enters its list's edit mode, before [+].
        if tab == .services && appState.servicesTab.hasSelectableContent {
            ToolbarItem(placement: .topBarTrailing) {
                ServicesSelectButton()
            }
        }

        // ONE add action, going straight to the unified form: the form derives
        // record-vs-schedule from its date, so there is nothing to choose first.
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                HapticService.shared.lightImpact()
                appState.present(.addService())
            } label: {
                Label(L10n.tabBarAddService, systemImage: "plus")
            }
            .buttonStyle(.glassProminent)
            .tint(Theme.accent)
            .disabled(appState.selectedVehicle == nil)
            .keyboardShortcut("n", modifiers: .command)
            .accessibilityIdentifier("toolbar.addService")
        }
    }
}

extension View {
    /// A tab root's title, vehicle menu, toolbar and background. A split
    /// view's list column passes `includesActions: false` and puts
    /// `TabRootActions` on its detail column.
    func tabRootChrome(_ tab: Tab, vehicles: [Vehicle], includesActions: Bool = true) -> some View {
        modifier(TabRootChrome(tab: tab, vehicles: vehicles, includesActions: includesActions))
    }
}
