//
//  AppRoute.swift
//  checkpoint
//
//  Detail screens pushed onto a tab's NavigationStack. Details are pushed,
//  tasks are sheets (`ActiveSheet`): anything the user reads and backs out of
//  lives here; anything they fill in and save or cancel does not.
//

import Foundation
import SwiftData

enum AppRoute: Hashable {
    case service(Service)
    case serviceLog(ServiceLog)
    case visit(ServiceVisit)
    case document(Document)
    case documents(Vehicle)
    /// The vehicle's notes, pinned first.
    case notes(Vehicle)
}

// MARK: - Regular-width columns

extension AppRoute {
    /// Whether this route opens a tab's detail column at regular width — the
    /// destinations the tab's list links to directly. Opening one from the
    /// list replaces the detail; anything else pushes on top of it.
    func isColumnRoot(for tab: Tab) -> Bool {
        switch (tab, self) {
        case (.services, .service), (.services, .serviceLog), (.services, .documents):
            return true
        case (.costs, .serviceLog), (.costs, .visit):
            return true
        default:
            return false
        }
    }

    /// A collection screen with its own Select and add (Documents, Notes).
    var isLibrary: Bool {
        switch self {
        case .documents, .notes: return true
        case .service, .serviceLog, .visit, .document: return false
        }
    }

    /// Whether the model this route shows has been deleted. Beside the list,
    /// a row can be deleted (swipe, Select) while its detail is showing — on
    /// a phone the detail covered the row, so this never came up.
    var isGone: Bool {
        switch self {
        case .service(let model): return model.isDeleted || model.modelContext == nil
        case .serviceLog(let model): return model.isDeleted || model.modelContext == nil
        case .visit(let model): return model.isDeleted || model.modelContext == nil
        case .document(let model): return model.isDeleted || model.modelContext == nil
        case .documents(let model), .notes(let model): return model.isDeleted || model.modelContext == nil
        }
    }
}

extension Array where Element == AppRoute {
    /// The path up to (not including) its first deleted route: everything
    /// after it was reached through a screen that no longer exists.
    func prefixBeforeGone() -> [AppRoute] {
        Array(prefix { !$0.isGone })
    }
}
