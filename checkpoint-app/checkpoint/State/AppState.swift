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

    // MARK: - Recall State

    enum RecallFetchState {
        case notFetched
        case fetched([RecallInfo])
        case failed
    }

    var recallState: [UUID: RecallFetchState] = [:]

    /// Recalls for the currently selected vehicle
    var currentRecalls: [RecallInfo] {
        guard let id = selectedVehicle?.id,
              case .fetched(let results) = recallState[id] else { return [] }
        return results
    }

    /// Whether the recall fetch failed for the currently selected vehicle
    var currentRecallFetchFailed: Bool {
        guard let id = selectedVehicle?.id,
              case .failed = recallState[id] else { return false }
        return true
    }

    func fetchRecalls(for vehicle: Vehicle) async {
        guard !vehicle.make.isEmpty,
              !vehicle.model.isEmpty,
              vehicle.year > 0 else {
            recallState[vehicle.id] = .fetched([])
            return
        }

        do {
            let results = try await NHTSAService.shared.fetchRecalls(
                make: vehicle.make,
                model: vehicle.model,
                year: vehicle.year
            )
            recallState[vehicle.id] = .fetched(results)
            RecallCheckCache.shared.recordSuccess()
            if !results.isEmpty {
                AnalyticsService.shared.capture(.recallAlertShown(recallCount: results.count))
            }
        } catch {
            recallState[vehicle.id] = .failed
        }
    }

    // MARK: - Onboarding Pre-fill

    var onboardingMarbeteMonth: Int?
    var onboardingMarbeteYear: Int?

    // MARK: - Services Tab State (preserved across tab switches)

    var servicesSearchText = ""
    var servicesStatusFilter: ServicesStatusFilter = .all
    var servicesViewMode: ServicesViewMode = .list

    enum ServicesStatusFilter: String, CaseIterable {
        case all = "All"
        case overdue = "Overdue"
        case dueSoon = "Due Soon"
        case good = "Good"
    }

    enum ServicesViewMode: String, CaseIterable {
        case list = "List"
        case timeline = "Timeline"
    }

    // MARK: - Siri Integration

    /// Pending mileage update from Siri intent
    var pendingMileageUpdate: SiriMileageUpdate?

    /// Data for a pending mileage update from Siri
    struct SiriMileageUpdate {
        let vehicleID: String
        let mileage: Int
    }

    // MARK: - Tab Enum

    enum Tab: String, CaseIterable {
        case services
        case home
        case costs

        var title: String {
            switch self {
            case .home: return "HOME"
            case .services: return "SERVICES"
            case .costs: return "COSTS"
            }
        }

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .services: return "wrench.and.screwdriver.fill"
            case .costs: return "dollarsign.circle.fill"
            }
        }

        /// Returns the previous tab in order, or stays on current if at the start
        var previous: Tab {
            let allTabs = Tab.allCases
            guard let currentIndex = allTabs.firstIndex(of: self),
                  currentIndex > 0 else { return self }
            return allTabs[currentIndex - 1]
        }

        /// Returns the next tab in order, or stays on current if at the end
        var next: Tab {
            let allTabs = Tab.allCases
            guard let currentIndex = allTabs.firstIndex(of: self),
                  currentIndex < allTabs.count - 1 else { return self }
            return allTabs[currentIndex + 1]
        }
    }

    // MARK: - Navigation Methods

    func navigateToServices() {
        selectedTab = .services
    }

    func navigateToCosts() {
        selectedTab = .costs
    }

    func navigateToHome() {
        selectedTab = .home
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
        guard !StoreManager.shared.isPro,
              !PurchaseSettings.shared.hasShownTipModalThisSession else { return }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.5))
            showTipModal = true
            PurchaseSettings.shared.hasShownTipModalThisSession = true
            AnalyticsService.shared.capture(.tipModalShown)
        }
    }
}

