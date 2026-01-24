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

    // MARK: - Tab Enum

    enum Tab: String, CaseIterable {
        case home
        case services
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

