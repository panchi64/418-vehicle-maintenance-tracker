//
//  Tab.swift
//  checkpoint
//
//  The root tabs, in tab-bar order. Home leads: it is the default selection
//  and the answer to "what needs doing".
//

import Foundation

enum Tab: String, CaseIterable, Hashable {
    case home
    case services
    case costs

    /// Localized label for the system tab bar and the tour's progress pill.
    var title: String {
        switch self {
        case .home: return L10n.tabHome
        case .services: return L10n.tabServices
        case .costs: return L10n.tabCosts
        }
    }

    /// Filled SF Symbol, per the tab bar convention.
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .services: return "wrench.and.screwdriver.fill"
        case .costs: return "dollarsign.circle.fill"
        }
    }
}
