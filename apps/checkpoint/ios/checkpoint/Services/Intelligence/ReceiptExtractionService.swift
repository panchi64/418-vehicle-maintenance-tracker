//
//  ReceiptExtractionService.swift
//  checkpoint
//
//  A receipt photo in, a `ServiceReceiptDraft` out:
//
//    1. Vision (`ReceiptOCRService.scan`): the smudge check turns away a
//       blurred capture, then `RecognizeDocumentsRequest` reads text, tables
//       and detected amounts and dates.
//    2. The rules (`ReceiptTextParser`) read the scan. Always — they are the
//       fallback and the cross-check.
//    3. When the on-device model is available, it reads the same scan (and,
//       on iOS 27, the photo), and its answer is scored against the rules'
//       (`ReceiptDraftValidator.merge`). If the model fails for any reason,
//       the rules' draft is used as is.
//    4. Code validation (`ReceiptDraftValidator.validate`) and per-field
//       confidence.
//
//  Free, and on-device only. Nothing here writes: consumers show the draft
//  and the user confirms (`ServiceLogForm`, `LogReceiptIntent`).
//

import Foundation
import os
import SwiftData
import UIKit

private let extractionLogger = Logger(category: "ReceiptExtraction")

final class ReceiptExtractionService {

    /// What a read produced: the draft, and the scan it came from (its
    /// transcript becomes the attachment's searchable text).
    struct Result {
        let draft: ServiceReceiptDraft
        let scan: ReceiptScan
    }

    typealias ImageReader = (CGImage, CGImagePropertyOrientation) async throws -> ReceiptScan

    private let session: LanguageModelSessioning?
    private let readImage: ImageReader

    /// - Parameters:
    ///   - session: the model; nil (the default without Apple Intelligence)
    ///     reads with the rules alone.
    ///   - readImage: Vision's reading; tests substitute a transcript.
    init(
        session: LanguageModelSessioning? = OnDeviceLanguageModel.ifAvailable(),
        readImage: @escaping ImageReader = { image, orientation in
            try await ReceiptOCRService.shared.scan(image, orientation: orientation)
        }
    ) {
        self.session = session
        self.readImage = readImage
    }

    /// Read a receipt photo. Throws `ReceiptOCRService.OCRError` when the
    /// photo is unreadable (blurred, no text) — the caller says so and the
    /// form stays as it was.
    func extract(from image: UIImage, context: ReceiptContext) async throws -> Result {
        guard let cgImage = image.cgImage else { throw ReceiptOCRService.OCRError.imageProcessingFailed }
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        let scan = try await readImage(cgImage, orientation)
        let draft = await draft(from: scan, image: cgImage, orientation: orientation, context: context)
        return Result(draft: draft, scan: scan)
    }

    /// Steps 2–4 over a scan already read.
    func draft(
        from scan: ReceiptScan,
        image: CGImage? = nil,
        orientation: CGImagePropertyOrientation = .up,
        context: ReceiptContext
    ) async -> ServiceReceiptDraft {
        let rules = ReceiptTextParser.parse(scan, context: context)
        guard let session else {
            return ReceiptDraftValidator.validate(rules, context: context)
        }
        do {
            let reading = try await session.readReceipt(ReceiptModelRequest(
                scan: scan,
                knownServiceNames: context.knownServiceNames,
                image: image,
                imageOrientation: orientation
            ))
            let model = Self.draft(from: reading, context: context)
            let merged = ReceiptDraftValidator.merge(model: model, rules: rules, calendar: context.calendar)
            return ReceiptDraftValidator.validate(merged, context: context)
        } catch {
            extractionLogger.info("On-device model couldn't read the receipt, using rules: \(error.localizedDescription)")
            return ReceiptDraftValidator.validate(rules, context: context)
        }
    }

    /// The model's reading as a draft, its service names mapped onto the
    /// vehicle's own where they match.
    static func draft(from reading: ModelReceiptReading, context: ReceiptContext) -> ServiceReceiptDraft {
        let matcher = ServiceNameMatcher(candidates: context.knownServiceNames)
        var seen = Set<String>()
        let services = reading.serviceNames.compactMap { name -> String? in
            let known = matcher.match(name) ?? name
            return seen.insert(known.lowercased()).inserted ? known : nil
        }
        return ServiceReceiptDraft(
            shopName: reading.shopName,
            date: reading.date,
            total: reading.total,
            tax: reading.tax,
            odometer: reading.odometer,
            lineItems: reading.lineItems,
            serviceNames: services,
            source: .onDeviceModel
        )
    }

    // MARK: - Context

    /// What the readers know about `vehicle`: its service names (active
    /// first), then the preset catalog; and its odometer on file.
    @MainActor
    static func context(for vehicle: Vehicle, presets: [PresetData]? = nil, now: Date = .now) -> ReceiptContext {
        let own = (vehicle.services ?? []).map(\.name)
        let catalog = (presets ?? PresetDataService.shared.loadPresets()).map(\.name)
        var seen = Set<String>()
        let names = (own + catalog).filter { seen.insert($0.lowercased()).inserted }
        return ReceiptContext(knownServiceNames: names, lastOdometer: vehicle.currentMileage, now: now)
    }
}
