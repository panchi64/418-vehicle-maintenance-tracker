//
//  CheckpointSchema.swift
//  checkpoint
//
//  Versioned schema + migration plan for the SwiftData store.
//
//  The ModelContainer is built from `CheckpointMigrationPlan` rather than a
//  bare `Schema`, so model changes ship as explicit, staged migrations.
//
//  RULES FOR A NEW VERSION (the store syncs through CloudKit):
//  - Freeze the previous version first: copy its models into nested classes
//    of its `VersionedSchema` (see `CheckpointSchemaV1`). Two versions that
//    list the same live classes hash alike and the plan can't tell them apart.
//  - Changes are additive only. CloudKit schemas can't delete or change a
//    record type or field once in production, and older app versions keep
//    syncing the same container — never remove or rename a stored property,
//    even one the app stops using (`Vehicle.notes`).
//  - Every attribute optional or defaulted, relationships optional with an
//    inverse, no `.unique`, no `.deny` (SwiftData's CloudKit limitations).
//  - A stage's data work must be idempotent and safe to repeat after sync:
//    each device migrates its own store, and an older client can write the
//    old shape at any time. Pair it with a post-launch reconcile.
//  - Deploy the new record types to the CloudKit production schema (CloudKit
//    Console → Deploy Schema Changes) before the release ships.
//

import Foundation
import SwiftData

/// V2 (Sep 2026): shop appointments and vehicle notes.
/// - New `Appointment` (vehicle, linked services) and `VehicleNote` (vehicle,
///   attachments).
/// - New relationships: `Vehicle.appointments`, `Vehicle.vehicleNotes`,
///   `Service.appointments`, `ServiceAttachment.vehicleNote`.
/// - `Vehicle.notes` stays, as the mirror older app versions read
///   (`VehicleNoteMigration`).
enum CheckpointSchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(2, 0, 0) }

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
            Appointment.self,
            VehicleNote.self,
        ]
    }
}

/// The version the app opens its store with. Tests and previews use it too.
typealias CheckpointSchemaCurrent = CheckpointSchemaV2

enum CheckpointMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [CheckpointSchemaV1.self, CheckpointSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }

    /// The schema change is additive (lightweight). After it, each vehicle's
    /// single notes field becomes its pinned note. The same reconcile runs
    /// after every launch, for notes an older client syncs in later.
    ///
    /// SwiftData runs the stage inside `ModelContainer.init`, on the thread
    /// that opens the store — the main thread, in the app and in tests — and
    /// the models are main-actor types.
    static var migrateV1toV2: MigrationStage {
        .custom(
            fromVersion: CheckpointSchemaV1.self,
            toVersion: CheckpointSchemaV2.self,
            willMigrate: nil,
            didMigrate: { context in
                try MainActor.assumeIsolated {
                    try VehicleNoteMigration.reconcile(in: context)
                }
            }
        )
    }
}
