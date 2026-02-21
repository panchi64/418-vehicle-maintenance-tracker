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
    var showProPaywall = false
    var showTipModal = false
    var unlockedTheme: ThemeDefinition?
    var selectedService: Service?
    var selectedServiceLog: ServiceLog?

    // MARK: - Cluster States

    var selectedCluster: ServiceCluster?
    var clusterToMarkDone: ServiceCluster?

    // MARK: - Seasonal Reminder Pre-fill

    var seasonalPrefill: SeasonalPrefill?

    // MARK: - Add Service Mode

    var addServiceMode: ServiceMode?

    // MARK: - Domain State

    var recall = RecallState()
    var servicesTab = ServicesTabState()
    var onboarding = OnboardingPrefillState()
    var siri = SiriState()

    // MARK: - Recall Convenience

    /// Recalls for the currently selected vehicle
    var currentRecalls: [RecallInfo] {
        recall.recalls(for: selectedVehicle?.id)
    }

    /// Whether the recall fetch failed for the currently selected vehicle
    var currentRecallFetchFailed: Bool {
        recall.fetchFailed(for: selectedVehicle?.id)
    }

    func fetchRecalls(for vehicle: Vehicle) async {
        guard !vehicle.make.isEmpty,
              !vehicle.model.isEmpty,
              vehicle.year > 0 else {
            recall.fetchStates[vehicle.id] = .fetched([])
            return
        }

        do {
            let results = try await NHTSAService.shared.fetchRecalls(
                make: vehicle.make,
                model: vehicle.model,
                year: vehicle.year
            )
            recall.fetchStates[vehicle.id] = .fetched(results)
            RecallCheckCache.shared.recordSuccess()
            if !results.isEmpty {
                AnalyticsService.shared.capture(.recallAlertShown(recallCount: results.count))
            }
        } catch {
            recall.fetchStates[vehicle.id] = .failed
        }
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

    func recordCompletedAction() {
        guard !StoreManager.shared.isPro else { return }

        PurchaseSettings.shared.recordCompletedAction()

        guard PurchaseSettings.shared.shouldShowTipPrompt else { return }

        let actionCount = PurchaseSettings.shared.completedActionCount
        let dismissCount = PurchaseSettings.shared.tipPromptDismissCount
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.5))
            showTipModal = true
            PurchaseSettings.shared.hasShownTipModalThisSession = true
            AnalyticsService.shared.capture(.tipModalShown(
                actionCount: actionCount,
                dismissCount: dismissCount
            ))
        }
    }
}
