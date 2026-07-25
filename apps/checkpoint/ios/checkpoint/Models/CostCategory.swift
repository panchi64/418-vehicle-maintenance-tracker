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

    /// Canonical, localized category name. The Costs tab's category filter
    /// reuses this rather than defining its own labels — one concept, one name.
    var displayName: String {
        switch self {
        case .maintenance: return L10n.categoryMaintenance
        case .repair: return L10n.categoryRepair
        case .upgrade: return L10n.categoryUpgrade
        }
    }

    /// Abbreviated form for width-constrained controls (the four-option
    /// segmented filter). Only `maintenance` needs shortening.
    var shortDisplayName: String {
        switch self {
        case .maintenance: return L10n.categoryMaintenanceShort
        case .repair, .upgrade: return displayName
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
