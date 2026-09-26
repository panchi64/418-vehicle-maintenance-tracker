//
//  DocumentPhotoEntity.swift
//  checkpoint
//
//  Image documents — receipts, insurance cards, registration photos — as
//  assets in the iOS 27 Photos schema, and vehicles as the albums they sit
//  in. PDFs are not photos; they reach Siri and Shortcuts as
//  `DocumentEntity` and `DocumentFileEntity`.
//
//  Wraps the same models as `DocumentEntity` (same UUID for the same
//  document). Photo properties Checkpoint doesn't keep — location,
//  favorites, hidden, suggested edits, the editing adjustments — are nil or
//  false. The metadata processor requires every one of them to be declared
//  ("Missing required property 'aperture'"…), so they are.
//

import AppIntents
import GeoToolbox
import SwiftData

@available(iOS 27, *)
@AppEnum(schema: .photos.assetType)
nonisolated enum DocumentAssetType: String {
    case photo

    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .photo: "Photo"
    ]
}

@available(iOS 27, *)
@AppEnum(schema: .photos.albumType)
nonisolated enum VehicleAlbumType: String {
    case custom

    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .custom: "Custom"
    ]
}

/// Required by the asset schema's `filter` property. Documents are never
/// filtered, so it is always nil.
@available(iOS 27, *)
@AppEnum(schema: .photos.filterType)
nonisolated enum DocumentPhotoFilter: String {
    case original

    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .original: "Original"
    ]
}

@available(iOS 27, *)
@AppEntity(schema: .photos.asset)
struct DocumentPhotoEntity: ModelSnapshotEntity {
    static let defaultQuery = DocumentPhotoEntityQuery()

    let id: UUID

    var creationDate: Date?
    var location: PlaceDescriptor?
    var assetType: DocumentAssetType?
    var isFavorite: Bool
    var isHidden: Bool
    var hasSuggestedEdits: Bool
    var aperture: Double?
    var exposure: Double?
    var saturation: Double?
    var warmth: Double?
    var filter: DocumentPhotoFilter?
    var isPortraitModeEnabled: Bool?

    let fileName: String
    let vehicleNames: [String]
    let extractedText: String?

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(fileName)",
            subtitle: "\(vehicleNames.joined(separator: ", "))",
            image: .init(systemName: "photo")
        )
    }

    var searchableText: [String] { [fileName, extractedText ?? ""] }

    @MainActor
    init(model document: Document) {
        // Plain stored properties first: assigning a schema property goes
        // through the wrapper the macro adds, which needs `self` complete.
        id = document.id
        fileName = document.fileName
        vehicleNames = (document.vehicles ?? []).map(\.displayName).sorted()
        extractedText = document.extractedText
        creationDate = document.createdAt
        location = nil
        assetType = .photo
        isFavorite = false
        isHidden = false
        hasSuggestedEdits = false
        aperture = nil
        exposure = nil
        saturation = nil
        warmth = nil
        filter = nil
        isPortraitModeEnabled = nil
    }

    /// Image documents only, newest first.
    @MainActor
    static func models(ids: [UUID]?, in context: ModelContext) throws -> [Document] {
        try DocumentEntity.models(ids: ids, in: context).filter(\.isImage)
    }
}

@available(iOS 27, *)
struct DocumentPhotoEntityQuery: EntityStringQuery {
    @Dependency var container: ModelContainer

    func entities(for identifiers: [UUID]) async throws -> [DocumentPhotoEntity] {
        try await EntityFetch.entities(DocumentPhotoEntity.self, ids: identifiers, in: container)
    }

    func entities(matching string: String) async throws -> [DocumentPhotoEntity] {
        try await EntityFetch.entities(DocumentPhotoEntity.self, matching: string, in: container)
    }

    func suggestedEntities() async throws -> [DocumentPhotoEntity] {
        try await EntityFetch.entities(DocumentPhotoEntity.self, in: container)
    }
}

@available(iOS 27, *)
@AppEntity(schema: .photos.album)
struct VehicleAlbumEntity: ModelSnapshotEntity {
    static let defaultQuery = VehicleAlbumEntityQuery()

    let id: UUID

    var name: String
    var creationDate: Date?
    var albumType: VehicleAlbumType

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", image: .init(systemName: "car.fill"))
    }

    var searchableText: [String] { [name] }

    @MainActor
    init(model vehicle: Vehicle) {
        id = vehicle.id
        name = vehicle.displayName
        creationDate = nil
        albumType = .custom
    }

    @MainActor
    static func models(ids: [UUID]?, in context: ModelContext) throws -> [Vehicle] {
        try VehicleEntity.models(ids: ids, in: context)
    }
}

@available(iOS 27, *)
struct VehicleAlbumEntityQuery: EntityStringQuery {
    @Dependency var container: ModelContainer

    func entities(for identifiers: [UUID]) async throws -> [VehicleAlbumEntity] {
        try await EntityFetch.entities(VehicleAlbumEntity.self, ids: identifiers, in: container)
    }

    func entities(matching string: String) async throws -> [VehicleAlbumEntity] {
        try await EntityFetch.entities(VehicleAlbumEntity.self, matching: string, in: container)
    }

    func suggestedEntities() async throws -> [VehicleAlbumEntity] {
        try await EntityFetch.entities(VehicleAlbumEntity.self, in: container)
    }
}
