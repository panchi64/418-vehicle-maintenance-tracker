//
//  CostCategory.swift
//  checkpoint
//
//  Cost categorization for service expenses
//

import Foundation
import SwiftUI

enum CostCategory: String, Codable, CaseIterable {
    case maintenance  // Scheduled/preventive maintenance
    case repair       // Unplanned fixes
    case upgrade      // Improvements/accessories

    /// Canonical, localized category name — one concept, one name, on rows,
    /// forms and the Costs tab's category chart alike.
    var displayName: String {
        switch self {
        case .maintenance: return L10n.categoryMaintenance
        case .repair: return L10n.categoryRepair
        case .upgrade: return L10n.categoryUpgrade
        }
    }

    var icon: String {
        switch self {
        case .maintenance: return "wrench.and.screwdriver"
        case .repair: return "exclamationmark.triangle"
        case .upgrade: return "arrow.up.circle"
        }
    }

    var color: Color {
        switch self {
        case .maintenance: return Theme.statusGood
        case .repair: return Theme.statusOverdue
        case .upgrade: return Theme.accent
        }
    }
}
