//
//  CheckpointSchema.swift
//  checkpoint
//
//  Versioned schema + migration plan for the SwiftData store.
//
//  The ModelContainer is built from `CheckpointMigrationPlan` rather than a
//  bare `Schema` so that future model changes can be introduced as explicit,
//  staged migrations (add `CheckpointSchemaV2`, then a `MigrationStage`
//  between V1 and V2) instead of relying on implicit lightweight migration.
//  V1 captures the current shipping schema; there are no stages yet.
//

import Foundation
import SwiftData

/// The current (initial) versioned schema. Lists every persistent model that
/// backs the store today. Keep this list in sync with the models actually
/// persisted; a new `@Model` type must be added here (and, once shipped, a new
/// version + migration stage created rather than editing V1 in place).
enum CheckpointSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [
            Vehicle.self,
            Service.self,
            ServiceLog.self,
            ServicePreset.self,
            MileageSnapshot.self,
            ServiceAttachment.self,
            RecallAcknowledgment.self,
            ServiceVisit.self,
            VisitLineItem.self,
        ]
    }
}

/// Migration plan for the Checkpoint store. Single V1 stage for now; when the
/// schema changes, add the new version to `schemas` and a `MigrationStage`
/// (lightweight or custom) to `stages`.
enum CheckpointMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [CheckpointSchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}
