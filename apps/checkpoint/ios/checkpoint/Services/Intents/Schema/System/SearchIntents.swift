//
//  SearchIntents.swift
//  checkpoint
//
//  "Search Checkpoint for brakes." Opens the app on the search that fits the
//  term: the Services tab when a service or its history matches, the
//  Documents library when only a document does, and the Services tab — the
//  broader list — when nothing matches yet.
//
//  Two schema intents, one behavior:
//    - `.system.search` (iOS 18) serves iOS 26. The SDK deprecates it in 27.
//    - `.system.searchInApp` (iOS 27) replaces it. It is `isAssistantOnly`,
//      so Shortcuts doesn't list Search twice on iOS 27; saved shortcuts keep
//      using the iOS 26 one.
//

import AppIntents
import SwiftData

@AppIntent(schema: .system.search)
struct SearchCheckpointIntent: ShowInAppSearchResultsIntent {
    static var searchScopes: [StringSearchScope] { [.general] }

    @Dependency var container: ModelContainer

    var criteria: StringSearchCriteria

    @MainActor
    func perform() async throws -> some IntentResult {
        EntityRoutes.open(try InAppSearch.route(for: criteria.term, in: container.mainContext))
        return .result()
    }
}

@available(iOS 27, *)
@AppIntent(schema: .system.searchInApp)
struct SearchInCheckpointIntent: ShowInAppSearchResultsIntent {
    static let isAssistantOnly = true
    static var searchScopes: [StringSearchScope] { [.general] }

    @Dependency var container: ModelContainer

    var criteria: StringSearchCriteria

    @MainActor
    func perform() async throws -> some IntentResult {
        EntityRoutes.open(try InAppSearch.route(for: criteria.term, in: container.mainContext))
        return .result()
    }
}

@MainActor
enum InAppSearch {

    /// Where a search for `term` opens, on the vehicle the app is showing.
    /// Matching is each screen's own: `ServicesTabContent.matches` and
    /// `Document.matches`.
    static func route(for term: String, in context: ModelContext) throws -> PendingRoute {
        let vehicle = try IntentStore.vehicle(id: nil, in: context)
        let term = term.trimmingCharacters(in: .whitespacesAndNewlines)
        let servicesMatch = (vehicle.services ?? []).contains { ServicesTabContent.matches($0, term) }
            || (vehicle.serviceLogs ?? []).contains { ServicesTabContent.matches($0, term) }
        let documentsMatch = (vehicle.documents ?? []).contains { $0.matches(term) }

        if documentsMatch && !servicesMatch {
            return .searchDocuments(vehicleID: vehicle.id, term: term)
        }
        return .searchServices(vehicleID: vehicle.id, term: term)
    }
}
