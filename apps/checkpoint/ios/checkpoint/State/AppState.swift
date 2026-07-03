//
//  AppState.swift
//  checkpoint
//
//  Shared application state for tab navigation and sheet management
//

import SwiftUI
import SwiftData

@Observable
@MainActor
final class AppState {
    // MARK: - Navigation

    var selectedVehicle: Vehicle?
    var selectedTab: Tab = .home

    // MARK: - Sheet States

    var showVehiclePicker = false
    var showAddVehicle = false
    var showAddService = false
    var showEditVehicle = false
    var showDocuments = false
    var showProPaywall = false
    var showTipModal = false
    var unlockedTheme: ThemeDefinition?
    var selectedService: Service?
    var selectedServiceLog: ServiceLog?
    var selectedServiceVisit: ServiceVisit?
    var selectedDocument: Document?
    var showMileageUpdate = false
    var showSettings = false

    /// Mileage value prefilled by a Siri intent, consumed by the mileage
    /// update sheet. A scalar (not a model reference), so it does not need
    /// clearing in `prepareForContainerSwap()`.
    var siriPrefilledMileage: Int?

    // MARK: - Cluster States

    var selectedCluster: ServiceCluster?
    var clusterToMarkDone: ServiceCluster?

    // MARK: - Seasonal Reminder Pre-fill

    var seasonalPrefill: SeasonalPrefill?

    /// Set by the "SCHEDULE NEXT" toast action after a record-mode save.
    /// Consumed by the next AddServiceView presentation to anchor the
    /// remind form on the just-recorded service's data.
    var postRecordPrefill: PostRecordPrefill?

    // MARK: - Add Service Mode

    var addServiceMode: ServiceMode?

    // MARK: - Domain State

    var recall = RecallState()
    var servicesTab = ServicesTabState()
    var onboarding = OnboardingPrefillState()

    // MARK: - Container Lifecycle

    /// Release every SwiftData model reference this state retains before the
    /// app swaps its `ModelContainer` (onboarding completion enables CloudKit
    /// and rebuilds the container). Those objects belong to the outgoing
    /// container's context; holding them past the swap would render stale rows
    /// against a dead context. Must be called on the same event that triggers
    /// the swap (`.enableCloudSyncAfterOnboarding`).
    func prepareForContainerSwap() {
        selectedVehicle = nil
        selectedService = nil
        selectedServiceLog = nil
        selectedServiceVisit = nil
        selectedDocument = nil
        selectedCluster = nil
        clusterToMarkDone = nil
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
            showProPaywall = true
            AnalyticsService.shared.capture(.vehicleLimitReached(vehicleCount: vehicleCount))
        } else {
            showAddVehicle = true
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
