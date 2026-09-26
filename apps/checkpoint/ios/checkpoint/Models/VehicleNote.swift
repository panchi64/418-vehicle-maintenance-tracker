//
//  VehicleNote.swift
//  checkpoint
//
//  One note about a vehicle — a paint code, a rattle being chased, what the
//  advisor recommended — with optional photos and PDFs. A vehicle has any
//  number; pinned ones list first. Replaces the single `Vehicle.notes` field,
//  which V2 keeps as a mirror for older app versions (`VehicleNoteMigration`).
//  Added in `CheckpointSchemaV2`.
//

import Foundation
import SwiftData

@Model
final class VehicleNote: Identifiable {
    var id: UUID = UUID()
    var vehicle: Vehicle?

    var title: String = ""
    var body: String = ""
    var isPinned: Bool = false
    var createdAt: Date = Date.now
    var modifiedAt: Date = Date.now

    /// Photos and PDFs. They are Documents: linked to the vehicle too, so they
    /// also show in its library. `.nullify`: deleting the note leaves them
    /// there, as deleting a log leaves its receipts.
    @Relationship(deleteRule: .nullify, inverse: \ServiceAttachment.vehicleNote)
    var attachments: [ServiceAttachment]? = []

    init(
        vehicle: Vehicle? = nil,
        title: String,
        body: String = "",
        isPinned: Bool = false,
        createdAt: Date = .now
    ) {
        self.vehicle = vehicle
        self.title = title
        self.body = body
        self.isPinned = isPinned
        self.createdAt = createdAt
        self.modifiedAt = createdAt
    }
}

extension VehicleNote {
    /// What a list shows as the note's name: the title, or the first line of
    /// the body when the title is empty.
    var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        return Self.firstLine(of: body) ?? ""
    }

    /// The line a list shows under the title: the body's first line, or its
    /// second when the first is already standing in for an empty title.
    var previewLine: String? {
        let lines = Self.lines(of: body)
        let hasTitle = !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return hasTitle ? lines.first : lines.dropFirst().first
    }

    /// The first non-empty line of `text`, trimmed.
    nonisolated static func firstLine(of text: String) -> String? {
        lines(of: text).first
    }

    nonisolated private static func lines(of text: String) -> [String] {
        text.split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    /// Pinned first, then most recently changed.
    static func listOrder(_ lhs: VehicleNote, _ rhs: VehicleNote) -> Bool {
        if lhs.isPinned != rhs.isPinned { return lhs.isPinned }
        return lhs.modifiedAt > rhs.modifiedAt
    }

    /// Whether a search for `query` finds this note: its title, body, or an
    /// attachment's name or scanned text. An empty query finds everything.
    @MainActor
    func matches(_ query: String) -> Bool {
        let query = query.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return true }
        return title.localizedStandardContains(query)
            || body.localizedStandardContains(query)
            || (attachments ?? []).contains { $0.matches(query) }
    }
}

extension Vehicle {
    /// This vehicle's notes, pinned first.
    var sortedNotes: [VehicleNote] {
        (vehicleNotes ?? []).sorted(by: VehicleNote.listOrder)
    }
}
