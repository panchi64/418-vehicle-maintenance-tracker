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
    var selectedService: Service?
    var selectedServiceLog: ServiceLog?

    // MARK: - Cluster States

    var selectedCluster: ServiceCluster?
    var clusterToMarkDone: ServiceCluster?

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
}

