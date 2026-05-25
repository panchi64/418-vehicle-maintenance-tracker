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

    var displayName: String {
        switch self {
        case .maintenance: return "Maintenance"
        case .repair: return "Repair"
        case .upgrade: return "Upgrade"
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
