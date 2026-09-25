//
//  AppState.swift
//  checkpoint
//
//  Shared application state: the selected vehicle and tab, each tab's
//  navigation path, and the one root sheet.
//

import SwiftUI
import SwiftData

@Observable
@MainActor
final class AppState {
    // MARK: - Navigation

    var selectedVehicle: Vehicle?
    var selectedTab: Tab = .home

    /// Each tab's NavigationStack path. Held here, not in the tabs, so a
    /// notification route can switch tab and push in one state change.
    var paths: [Tab: [AppRoute]] = [:]

    /// Switch vehicle from the UI. Every stack is popped to its root, since the
    /// details on them belong to the previous vehicle.
    func selectVehicle(_ vehicle: Vehicle?) {
        guard vehicle?.id != selectedVehicle?.id else { return }
        selectedVehicle = vehicle
        paths = [:]
    }

    /// Push a detail onto a tab's stack — the visible tab unless one is named.
    func push(_ route: AppRoute, on tab: Tab? = nil) {
        paths[tab ?? selectedTab, default: []].append(route)
    }

    /// Close whatever sheet is up and push a detail onto the visible tab. For a
    /// detail opened from inside a root sheet (a cluster's service row): the
    /// push lands on the stack underneath while the sheet animates away.
    func showDetail(_ route: AppRoute) {
        dismissSheet()
        push(route)
    }

    /// Replace a tab's stack with one destination and bring that tab forward.
    func navigate(to route: AppRoute, on tab: Tab) {
        dismissSheet()
        selectedTab = tab
        paths[tab] = [route]
    }

    // MARK: - Root Sheet

    /// The sheet the root is asked to show. Bound to ContentView's single
    /// `.sheet(item:)`; a swipe-down sets it back to nil.
    var activeSheet: ActiveSheet?

    /// The sheet that is actually on screen, from its content's first
    /// appearance until its `onDismiss`. Distinct from `activeSheet`, which goes
    /// nil the moment a dismissal *starts* — presenting in that window is what
    /// silently dropped sheets before.
    private(set) var presentedSheet: ActiveSheet?

    /// Waiting for the on-screen sheet to finish dismissing.
    private(set) var queuedSheet: ActiveSheet?

    /// Present `sheet`, replacing any sheet already up: that one dismisses
    /// first, and this one follows from its `onDismiss`.
    func present(_ sheet: ActiveSheet) {
        if presentedSheet == nil {
            queuedSheet = nil
            activeSheet = sheet
        } else {
            queuedSheet = sheet
            activeSheet = nil
        }
    }

    /// Present `sheet` once nothing is on screen, without closing what is.
    /// For app-initiated prompts (the tip modal) that must not interrupt a
    /// task the user is in the middle of.
    func presentWhenIdle(_ sheet: ActiveSheet) {
        if presentedSheet == nil && activeSheet == nil {
            activeSheet = sheet
        } else {
            queuedSheet = queuedSheet ?? sheet
        }
    }

    /// Close the root sheet and drop anything queued behind it.
    func dismissSheet() {
        queuedSheet = nil
        activeSheet = nil
    }

    /// Called from the sheet content's `onAppear`.
    func sheetDidAppear(_ sheet: ActiveSheet) {
        presentedSheet = sheet
    }

    /// Called from the root `.sheet`'s `onDismiss`. Presents whatever was
    /// queued, and returns the sheet that closed so the view layer can run its
    /// cleanup.
    @discardableResult
    func sheetDidDismiss() -> ActiveSheet? {
        let dismissed = presentedSheet
        presentedSheet = nil
        if let next = queuedSheet {
            queuedSheet = nil
            activeSheet = next
        }
        return dismissed
    }

    // MARK: - Cluster Refresh

    /// Bumped when a cluster is marked done from the root sheet, so Home
    /// re-detects clusters — completing them changes due dates, not the
    /// service count Home otherwise watches.
    var clusterRefreshToken = 0

    // MARK: - Domain State

    var recall = RecallState()
    var servicesTab = ServicesTabState()

    // MARK: - Container Lifecycle

    /// Release every SwiftData model reference this state retains before the
    /// app swaps its `ModelContainer` (onboarding completion enables CloudKit
    /// and rebuilds the container). Those objects belong to the outgoing
    /// container's context; holding them past the swap would render stale rows
    /// against a dead context. Must be called on the same event that triggers
    /// the swap (`.enableCloudSyncAfterOnboarding`).
    func prepareForContainerSwap() {
        selectedVehicle = nil
        paths = [:]
        if activeSheet?.retainsModels == true {
            activeSheet = nil
        }
        if queuedSheet?.retainsModels == true {
            queuedSheet = nil
        }
    }

    // MARK: - Recall Convenience

    /// Recalls for the currently selected vehicle
    var currentRecalls: [RecallInfo] {
        recall.recalls(for: selectedVehicle?.id)
    }

    /// Whether the recall fetch failed for the currently selected vehicle
    var currentRecallFetchFailed: Bool {
        recall.fetchFailed(for: selectedVehicle?.id)
    }

    /// Store the outcome of a successful recall fetch. Pure state mutation — the
    /// network call itself lives in the consuming layer (`ContentView.fetchRecalls`)
    /// so this store owns no side effects. An empty array records a
    /// "checked, nothing found" state for vehicles missing make/model/year.
    func setRecalls(_ recalls: [RecallInfo], for vehicleID: UUID) {
        recall.fetchStates[vehicleID] = .fetched(recalls.sortedNewestFirst())
    }

    /// Record that the recall fetch failed for a vehicle.
    func setRecallFetchFailed(for vehicleID: UUID) {
        recall.fetchStates[vehicleID] = .failed
    }

    // MARK: - Monetization

    func requestAddVehicle(vehicleCount: Int) {
        if vehicleCount >= 3 && !StoreManager.shared.isPro {
            present(.proPaywall)
            AnalyticsService.shared.capture(.vehicleLimitReached(vehicleCount: vehicleCount))
        } else {
            present(.addVehicle)
        }
    }

    /// Set when a completed action qualifies for the tip prompt. The delayed
    /// presentation effect lives in the view layer (ContentView observes this
    /// and shows the modal after a beat) so AppState stays a pure state store.
    var tipPromptQueued = false

    func recordCompletedAction() {
        guard !StoreManager.shared.isPro else { return }

        PurchaseSettings.shared.recordCompletedAction()

        guard PurchaseSettings.shared.shouldShowTipPrompt else { return }

        tipPromptQueued = true
    }
}

/// One or more services to complete together, from a notification's
/// "Mark as Done". One service completes on its own; several complete as a
/// Service Visit, the same as marking a suggested cluster done.
struct MarkDoneRequest: Identifiable {
    let id = UUID()
    let services: [Service]
    let vehicle: Vehicle
}
