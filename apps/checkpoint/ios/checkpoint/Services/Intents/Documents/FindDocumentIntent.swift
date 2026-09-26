//
//  FindDocumentIntent.swift
//  checkpoint
//
//  "Show my insurance card in Checkpoint." The newest document of a type
//  (and/or containing some text — a policy number, a shop), shown in the
//  Siri card without opening the app: the moment this is for is a traffic
//  stop or a shop counter. It returns the document, which hands over its
//  file (`DocumentEntity+Transfer`), so "share my registration" and a
//  shortcut ending in Mail both work.
//
//  The vehicle Checkpoint is showing is searched first; when it has no
//  match, the other vehicles are.
//

import AppIntents
import SwiftData
import SwiftUI

struct FindDocumentIntent: AppIntent {
    static let title: LocalizedStringResource = "Find Document"
    static let description = IntentDescription("Find a vehicle document, such as the insurance card or registration, and show it")

    @Dependency var container: ModelContainer

    @Parameter(title: "Type", requestValueDialog: "Which document?")
    var type: DocumentType?

    @Parameter(title: "Containing", description: "Text the document contains, such as a policy number or a shop's name")
    var text: String?

    @Parameter(title: "Vehicle", description: "Leave empty for the vehicle Checkpoint is showing.")
    var vehicle: VehicleEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Find \(\.$type) of \(\.$vehicle)") {
            \.$text
        }
    }

    init() {}

    init(type: DocumentType?, vehicle: VehicleEntity? = nil) {
        self.type = type
        self.vehicle = vehicle
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<DocumentEntity> & ProvidesDialog & ShowsSnippetView {
        let context = container.mainContext
        var type = self.type
        if type == nil, (text ?? "").trimmingCharacters(in: .whitespaces).isEmpty {
            type = try await $type.requestValue()
        }
        let vehicle = try IntentStore.vehicle(for: self.vehicle, in: context)
        guard let document = try Self.find(type: type, text: text, preferring: vehicle, in: context) else {
            throw IntentError.noMatchingDocument
        }
        let owner = Self.owner(of: document, preferring: vehicle)
        return .result(
            value: DocumentEntity(model: document),
            dialog: IntentDialog(stringLiteral: L10n.siriDocumentFound(
                type: document.documentType.displayName,
                vehicle: owner.displayName
            )),
            view: DocumentSnippetView(
                image: DocumentSnippetView.preview(of: document),
                title: document.fileName,
                caption: L10n.siriSnippetDocumentCaption(type: document.documentType.displayName, vehicle: owner.displayName)
            )
        )
    }

    /// The newest document matching `type` and `text` — on `vehicle`
    /// first, else on any vehicle.
    @MainActor
    static func find(type: DocumentType?, text: String?, preferring vehicle: Vehicle, in context: ModelContext) throws -> Document? {
        let query = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let matches = try DocumentEntity.models(ids: nil, in: context).filter { document in
            (type == nil || document.documentType == type) && document.matches(query)
        }
        return matches.first { ($0.vehicles ?? []).contains { $0.id == vehicle.id } } ?? matches.first
    }

    /// The vehicle to name the document by: `vehicle` when it's one of its
    /// own, else its first.
    @MainActor
    static func owner(of document: Document, preferring vehicle: Vehicle) -> Vehicle {
        let vehicles = document.vehicles ?? []
        return vehicles.first { $0.id == vehicle.id } ?? vehicles.first ?? vehicle
    }
}
