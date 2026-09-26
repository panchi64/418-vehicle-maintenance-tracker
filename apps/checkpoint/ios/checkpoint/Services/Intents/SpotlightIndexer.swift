//
//  SpotlightIndexer.swift
//  checkpoint
//
//  Keeps Spotlight's copy of the app's entities (vehicles, services, logs,
//  visits, documents) in step with the store. Runs wherever widget data is
//  refreshed after a change — `ContentView.updateWidgetData()` and the
//  CloudKit remote-change pass in `WidgetDataService` — so there is one
//  "data changed" moment, not a hook per write site.
//
//  Each pass replaces an entity type wholesale: delete the type, index what
//  the store holds now. That drops deleted records without tracking what was
//  indexed before, and the data is small enough (a few vehicles' history)
//  that the full pass is cheap. Passes are coalesced, since one save often
//  triggers several refreshes.
//

import AppIntents
import CoreSpotlight
import SwiftData
import os

private let spotlightLogger = Logger(category: "Spotlight")

/// The slice of `CSSearchableIndex` the indexer uses, so tests can record
/// calls instead of writing to the real index.
protocol AppEntityIndexing: AnyObject {
    func indexAppEntities<Entity: IndexedEntity>(_ entities: [Entity], priority: Int) async throws
    func deleteAppEntities<Entity: IndexedEntity>(ofType entityType: Entity.Type) async throws
}

/// `CSSearchableIndex.default()` is not `Sendable`; the indexer only ever
/// touches it from the main actor.
extension CSSearchableIndex: AppEntityIndexing {}

@MainActor
final class SpotlightIndexer {
    static let shared = SpotlightIndexer(index: CSSearchableIndex.default())

    private let index: any AppEntityIndexing
    private let debounce: Duration
    private var pendingPass: Task<Void, Never>?

    init(index: any AppEntityIndexing, debounce: Duration = .seconds(1)) {
        self.index = index
        self.debounce = debounce
    }

    /// Reindex after the current burst of changes settles. A later call
    /// replaces a pass that has not started yet.
    func scheduleReindex(from container: ModelContainer) {
        pendingPass?.cancel()
        pendingPass = Task { [weak self, debounce] in
            try? await Task.sleep(for: debounce)
            guard !Task.isCancelled else { return }
            await self?.reindex(from: container.mainContext)
        }
    }

    /// Replace every indexed entity type with what `context` holds now.
    func reindex(from context: ModelContext) async {
        do {
            try await replace(with: VehicleEntity.entities(in: context))
            try await replace(with: ServiceEntity.entities(in: context))
            try await replace(with: ServiceLogEntity.entities(in: context))
            try await replace(with: VisitEntity.entities(in: context))
            try await replace(with: DocumentEntity.entities(in: context))
        } catch {
            spotlightLogger.error("Spotlight reindex failed: \(error.localizedDescription)")
        }
    }

    private func replace<Entity: IndexedEntity>(with entities: [Entity]) async throws {
        try await index.deleteAppEntities(ofType: Entity.self)
        guard !entities.isEmpty else { return }
        try await index.indexAppEntities(entities, priority: 0)
    }
}
