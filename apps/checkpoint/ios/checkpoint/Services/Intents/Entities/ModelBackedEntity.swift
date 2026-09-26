//
//  ModelBackedEntity.swift
//  checkpoint
//
//  The shared shape of every SwiftData-backed App Entity. An entity is a
//  Sendable snapshot of one model, built on the main actor from the container
//  the app registered (`IntentDependencies`). Queries, the Spotlight indexer
//  and tests all go through `entities(ids:in:)` / `entities(matching:in:)`,
//  so there is one fetch path per type.
//

import AppIntents
import SwiftData

nonisolated protocol ModelBackedEntity: IndexedEntity where ID == UUID {
    associatedtype Model: PersistentModel

    /// Snapshot `model`. Main actor: it reads SwiftData relationships.
    @MainActor init(model: Model)

    /// The models with these IDs, or every model when `ids` is nil, in the
    /// order suggestions should list them.
    @MainActor static func models(ids: [UUID]?, in context: ModelContext) throws -> [Model]

    /// The text a spoken or typed name is matched against.
    var searchableText: [String] { get }
}

extension ModelBackedEntity {
    @MainActor
    static func entities(ids: [UUID]? = nil, in context: ModelContext) throws -> [Self] {
        try models(ids: ids, in: context).map(Self.init(model:))
    }

    /// Entities whose searchable text contains `text`, ignoring case and
    /// diacritics ("aceite" finds "Aceité"). Filtering happens in memory on
    /// typed values; the fetch itself stays a compile-checked `#Predicate`.
    @MainActor
    static func entities(matching text: String, in context: ModelContext) throws -> [Self] {
        let needle = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return try entities(in: context) }
        return try entities(in: context).filter { entity in
            entity.searchableText.contains { $0.localizedStandardContains(needle) }
        }
    }
}

extension IntentCurrencyAmount {
    /// A stored cost as Siri should say it. Costs are stored in US dollars,
    /// the currency every in-app formatter uses (`Formatters.currency`).
    nonisolated static func stored(_ amount: Decimal) -> IntentCurrencyAmount {
        IntentCurrencyAmount(amount: amount, currencyCode: "USD")
    }

    nonisolated static func stored(_ amount: Decimal?) -> IntentCurrencyAmount? {
        amount.map { stored($0) }
    }
}

/// Main-actor hops for the entity queries, which App Intents calls off the
/// main actor. `ModelContainer` is `Sendable`, so it crosses; the context
/// never does.
@MainActor
enum EntityFetch {
    static func entities<Entity: ModelBackedEntity>(
        _ type: Entity.Type,
        ids: [UUID]? = nil,
        in container: ModelContainer
    ) throws -> [Entity] {
        try Entity.entities(ids: ids, in: container.mainContext)
    }

    static func entities<Entity: ModelBackedEntity>(
        _ type: Entity.Type,
        matching text: String,
        in container: ModelContainer
    ) throws -> [Entity] {
        try Entity.entities(matching: text, in: container.mainContext)
    }
}
