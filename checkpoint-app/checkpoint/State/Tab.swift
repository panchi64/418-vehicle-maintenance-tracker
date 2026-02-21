//
//  Tab.swift
//  checkpoint
//
//  Main tab bar navigation enum
//

import Foundation

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
