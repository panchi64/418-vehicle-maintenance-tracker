//
//  PhotoIntents.swift
//  checkpoint
//
//  The iOS 27 Photos schema intents over image documents:
//
//    - Open a photo: `.system.open`, not `.photos.openAsset` — the SDK
//      deprecates `openAsset` in iOS 27 ("Use .system.open instead").
//    - "Save this photo to Checkpoint": `.photos.createAssets` imports the
//      images as documents on a vehicle, through the Documents library's
//      own constructor (`Document.fromImage`) plus the receipt scanner's
//      text recognition, so the new documents are searchable by what they
//      say.
//
//  No delete: deleting documents stays in-app (voice deletes cover services
//  and service logs only).
//

import AppIntents
import SwiftData
import UIKit

@available(iOS 27, *)
@AppIntent(schema: .system.open)
struct OpenDocumentPhotoIntent {
    @Dependency var container: ModelContainer

    var target: DocumentPhotoEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        EntityRoutes.open(try EntityRoutes.document(target.id, in: container.mainContext))
        return .result()
    }
}

@available(iOS 27, *)
@AppIntent(schema: .photos.createAssets)
struct SaveDocumentPhotosIntent {
    @Dependency var container: ModelContainer

    var files: [IntentFile]

    /// Shortcuts only (not in the schema): the vehicle the photos belong to.
    /// Empty means the vehicle Checkpoint is showing.
    @Parameter(title: "Vehicle")
    var album: VehicleAlbumEntity?

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<[DocumentPhotoEntity]> & ProvidesDialog {
        let context = container.mainContext
        let vehicle = try IntentStore.vehicle(id: album?.id, in: context)
        let documents = await PhotoImport.importImages(
            files.map { PhotoImport.File($0) },
            to: vehicle,
            in: context
        )
        guard !documents.isEmpty else { throw IntentError.noImages }
        try IntentStore.save(context)

        return .result(
            value: documents.map(DocumentPhotoEntity.init(model:)),
            dialog: IntentDialog(stringLiteral: L10n.siriPhotosSaved(count: documents.count, vehicle: vehicle.displayName))
        )
    }
}

/// Images handed to Checkpoint from outside (Siri, Shortcuts, the share
/// sheet) becoming documents in a vehicle's library.
@MainActor
enum PhotoImport {

    typealias File = DocumentImport.File

    /// Insert a document per file that decodes as an image, read, typed and
    /// saved as `DocumentImport` does (Add Document's path). Files that
    /// aren't images — PDFs included, which aren't photos — are skipped.
    static func importImages(
        _ files: [File],
        to vehicle: Vehicle,
        in context: ModelContext,
        now: Date = .now,
        recognizeText: DocumentImport.TextReader = DocumentImport.recognizeText(in:),
        classifier: DocumentClassifier? = nil
    ) async -> [Document] {
        let classifier = classifier ?? DocumentClassifier()
        var documents: [Document] = []
        for (index, file) in files.enumerated() where UIImage(data: file.data) != nil {
            guard let reading = await DocumentImport.read(file, recognizeText: recognizeText) else { continue }
            let type = await classifier.classify(text: reading.text, fileName: file.fileName)
            if let document = DocumentImport.insert(
                reading, fileName: file.fileName, type: type, on: vehicle, in: context, now: now, index: index + 1
            ) {
                documents.append(document)
            }
        }
        return documents
    }
}
