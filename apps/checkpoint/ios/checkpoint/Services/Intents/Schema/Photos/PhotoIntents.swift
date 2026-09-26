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
            files.map { PhotoImport.File(data: $0.data, fileName: $0.filename) },
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

    struct File {
        let data: Data
        let fileName: String
    }

    /// Insert a document per file that decodes as an image, typed from its
    /// name the way the Documents picker types one, with the text Vision
    /// reads from it. Files that aren't images are skipped.
    static func importImages(
        _ files: [File],
        to vehicle: Vehicle,
        in context: ModelContext,
        now: Date = .now,
        recognizeText: @MainActor (UIImage) async -> String? = PhotoImport.recognizeText(in:)
    ) async -> [Document] {
        var documents: [Document] = []
        for (index, file) in files.enumerated() {
            guard let image = UIImage(data: file.data) else { continue }
            let fileName = file.fileName.isEmpty
                ? "photo_\(Int(now.timeIntervalSince1970))_\(index + 1).jpg"
                : file.fileName
            guard let document = Document.fromImage(
                image,
                fileName: fileName,
                documentType: DocumentType.suggestedType(forFileName: fileName),
                vehicles: [vehicle]
            ) else { continue }
            document.extractedText = await recognizeText(image)
            context.insert(document)
            documents.append(document)
        }
        return documents
    }

    /// The receipt scanner's OCR. A photo with no readable text is still
    /// saved, just without any.
    static func recognizeText(in image: UIImage) async -> String? {
        try? await ReceiptOCRService.shared.extractText(from: image).text
    }
}
