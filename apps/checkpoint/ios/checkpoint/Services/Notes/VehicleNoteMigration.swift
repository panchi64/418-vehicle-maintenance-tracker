//
//  VehicleNoteMigration.swift
//  checkpoint
//
//  Keeps V1's single `Vehicle.notes` field and V2's notes in step.
//
//  V2 turns each vehicle's notes text into one pinned `VehicleNote` — the
//  "legacy note". The field itself stays, because older app versions sync the
//  same CloudKit container and only know the field: V2 mirrors the legacy
//  note's body back into it on every save and delete, so an older client
//  keeps showing the right text.
//
//  The legacy note's ID is derived from the vehicle's (`legacyNoteID`), so
//  every device that migrates creates the *same* note. Sync can still deliver
//  two copies (two devices migrated before either synced); `reconcile` keeps
//  the most recently changed one.
//
//  `reconcile` runs in the V1→V2 migration stage and again after every launch
//  (`ServiceMigrationService`), because an older client can write the field at
//  any time. Because V2 always mirrors, a field that differs from its legacy
//  note was changed by an older client, and the field wins.
//

import Foundation
import SwiftData
import os

private let noteMigrationLogger = Logger(category: "VehicleNoteMigration")

@MainActor
enum VehicleNoteMigration {

    /// The ID of the note migrated from `vehicleID`'s notes field: the
    /// vehicle's UUID with its version nibble set to 8 (RFC 9562 custom).
    /// Vehicle IDs are random (version 4) UUIDs, so this never equals one,
    /// and it is the same on every device.
    nonisolated static func legacyNoteID(for vehicleID: UUID) -> UUID {
        var bytes = vehicleID.uuid
        bytes.6 = (bytes.6 & 0x0F) | 0x80
        return UUID(uuid: bytes)
    }

    /// Whether `note` is the one migrated from its vehicle's notes field.
    static func isLegacyNote(_ note: VehicleNote) -> Bool {
        guard let vehicle = note.vehicle else { return false }
        return note.id == legacyNoteID(for: vehicle.id)
    }

    /// Bring every vehicle's legacy note in line with its notes field. Safe
    /// to repeat; saves only when something changed.
    static func reconcile(in context: ModelContext, now: Date = .now) throws {
        var changed = 0
        for vehicle in try context.fetch(FetchDescriptor<Vehicle>()) {
            if reconcile(vehicle, in: context, now: now) { changed += 1 }
        }
        if changed > 0 {
            try context.save()
            noteMigrationLogger.info("Reconciled legacy notes on \(changed) vehicle(s)")
        }
    }

    /// Reconcile one vehicle. Returns whether anything changed.
    @discardableResult
    static func reconcile(_ vehicle: Vehicle, in context: ModelContext, now: Date = .now) -> Bool {
        let legacyID = legacyNoteID(for: vehicle.id)
        let copies = (vehicle.vehicleNotes ?? [])
            .filter { $0.id == legacyID }
            .sorted { $0.modifiedAt > $1.modifiedAt }
        var changed = false

        // Two devices migrated the same field: keep the newest copy.
        for duplicate in copies.dropFirst() {
            context.delete(duplicate)
            changed = true
        }

        let text = normalized(vehicle.notes)
        switch (copies.first, text) {
        case (nil, nil):
            break
        case (nil, let text?):
            let note = VehicleNote(vehicle: vehicle, title: "", body: text, isPinned: true, createdAt: now)
            note.id = legacyID
            context.insert(note)
            changed = true
        case (let note?, let text?):
            if note.body != text {
                note.body = text
                note.modifiedAt = now
                changed = true
            }
        case (let note?, nil):
            // An older client cleared the field (or V2 saved an empty body).
            // Drop the note unless V2 gave it more than text — a title or
            // attachments; then keep it, emptied.
            let hasMore = !(note.attachments ?? []).isEmpty
                || !note.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            if !hasMore {
                context.delete(note)
            } else if !note.body.isEmpty {
                note.body = ""
                note.modifiedAt = now
            } else {
                break
            }
            changed = true
        }
        return changed
    }

    /// Mirror `note` into its vehicle's notes field when it is the legacy
    /// note, so older app versions show what V2 saved. Call after every
    /// save of a note.
    static func mirror(_ note: VehicleNote) {
        guard isLegacyNote(note), let vehicle = note.vehicle else { return }
        vehicle.notes = normalized(note.body)
    }

    /// Clear the field when its legacy note is deleted, so an older client
    /// doesn't bring the text back. Call before deleting a note.
    static func noteWillBeDeleted(_ note: VehicleNote) {
        guard isLegacyNote(note), let vehicle = note.vehicle else { return }
        vehicle.notes = nil
    }

    private static func normalized(_ text: String?) -> String? {
        guard let text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return text
    }
}
