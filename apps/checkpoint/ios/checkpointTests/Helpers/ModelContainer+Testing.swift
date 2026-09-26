//
//  ModelContainer+Testing.swift
//  checkpointTests
//
//  The one way tests build a SwiftData store.
//

import SwiftData
@testable import checkpoint

extension ModelContainer {
    /// An in-memory container over the app's full versioned schema, with
    /// CloudKit mirroring off.
    ///
    /// The app carries the iCloud entitlement, so a plain
    /// `ModelConfiguration(isStoredInMemoryOnly: true)` still mirrors to
    /// CloudKit by default. On a simulator with no iCloud account (every
    /// iOS 27 simulator) that store traps on its first save with
    /// "No eligible connection available".
    nonisolated static func inMemoryForTesting() -> ModelContainer {
        do {
            return try ModelContainer(
                for: Schema(versionedSchema: CheckpointSchemaV1.self),
                configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
            )
        } catch {
            fatalError("Could not create in-memory test ModelContainer: \(error)")
        }
    }
}
