//
//  L10n+Navigation.swift
//  checkpoint
//
//  Strings for the navigation shell's regular-width columns. Keys are
//  prefixed `columns.`.
//

import Foundation

extension L10n {
    private static func columns(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    // MARK: - Empty detail column

    /// What the detail column shows before a row is chosen. Only the tabs with
    /// a split view have one.
    static func columnsPlaceholderTitle(_ tab: Tab) -> String {
        switch tab {
        case .costs: return columns("columns.placeholder.costs.title")
        case .home, .services: return columns("columns.placeholder.services.title")
        }
    }

    static func columnsPlaceholderMessage(_ tab: Tab) -> String {
        switch tab {
        case .costs: return columns("columns.placeholder.costs.message")
        case .home, .services: return columns("columns.placeholder.services.message")
        }
    }
}
