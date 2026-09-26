//
//  VisualCapture.swift
//  checkpoint
//
//  What Visual Intelligence showed Checkpoint, and what Checkpoint can do
//  with it: log a receipt, update the mileage from an odometer, add a vehicle
//  from a VIN.
//
//  Captures live in memory only (`VisualCaptureStore`), keyed by the ID the
//  result entity carries, for the few minutes between Visual Intelligence
//  listing a result and the user tapping it. The photo never reaches the
//  store on disk unless the user saves the form it opens.
//

import CoreGraphics
import CoreImage
import CoreVideo
import Foundation
import SwiftData
import UIKit

/// The actions a capture can offer.
nonisolated enum VisualCaptureKind: String, Sendable, CaseIterable {
    case receipt
    case odometer
    case vin
}

struct VisualCapture {
    let id: UUID
    let kind: VisualCaptureKind
    let vehicleID: UUID
    let image: CGImage
    /// Odometer: the reading, stored miles. Receipt: nothing (the form
    /// reads it).
    var reading: Int?
    /// VIN: the one read.
    var vin: String?
    var createdAt: Date = .now
}

@MainActor
final class VisualCaptureStore {
    static let shared = VisualCaptureStore()

    /// How long a result stays tappable.
    static let lifetime: TimeInterval = 30 * 60
    static let capacity = 12

    private var captures: [VisualCapture] = []

    func add(_ capture: VisualCapture, now: Date = .now) {
        captures.removeAll { now.timeIntervalSince($0.createdAt) > Self.lifetime }
        captures.append(capture)
        if captures.count > Self.capacity { captures.removeFirst(captures.count - Self.capacity) }
    }

    func capture(id: UUID, now: Date = .now) -> VisualCapture? {
        captures.first { $0.id == id && now.timeIntervalSince($0.createdAt) <= Self.lifetime }
    }

    func removeAll() { captures.removeAll() }
}

/// Which actions a capture supports, from Visual Intelligence's labels and
/// the text Vision reads in it.
@MainActor
enum VisualCaptureClassifier {

    /// Labels are general en_US terms (Apple: "might provide the labels tower
    /// or building"), never product names, so they only hint.
    static let receiptLabels = ["receipt", "invoice", "bill", "document", "paper", "text", "menu", "ticket"]
    static let odometerLabels = ["odometer", "speedometer", "dashboard", "gauge", "instrument", "car interior",
                                 "vehicle interior", "steering wheel", "meter"]

    /// The kinds on offer, most likely first. A VIN is offered only when a
    /// valid one is printed; a receipt when the text reads like one (or the
    /// labels say document and there's a total); an odometer when the
    /// labels say dashboard.
    static func kinds(labels: [String], transcript: String?, context: ReceiptContext) -> [VisualCaptureKind] {
        let lowered = labels.map { $0.lowercased() }
        func labelled(_ words: [String]) -> Bool {
            lowered.contains { label in words.contains { label.contains($0) } }
        }

        var kinds: [VisualCaptureKind] = []
        let text = transcript ?? ""
        if !text.isEmpty {
            let draft = ReceiptTextParser.parse(ReceiptScan(transcript: text), context: context)
            let readsLikeReceipt = draft.confidence.total == .high || (draft.total != nil && labelled(receiptLabels))
            if readsLikeReceipt { kinds.append(.receipt) }
        }
        if labelled(odometerLabels) { kinds.append(.odometer) }
        if vin(in: text) != nil { kinds.append(.vin) }
        return kinds
    }

    /// A valid VIN printed in `text`: 17 characters, no I, O or Q, with both
    /// letters and digits (a 17-digit number is a barcode, not a VIN).
    static func vin(in text: String) -> String? {
        let tokens = text.uppercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count == 17 }
        return tokens.first { token in
            Vehicle.isValidVIN(token)
                && token.contains(where: \.isLetter)
                && token.contains(where: \.isNumber)
        }
    }

    /// Visual Intelligence's frame as an image Vision and the form can read.
    nonisolated static func cgImage(from buffer: CVReadOnlyPixelBuffer) -> CGImage? {
        buffer.withUnsafeBuffer { pixelBuffer in
            let image = CIImage(cvPixelBuffer: pixelBuffer)
            return imageContext.createCGImage(image, from: image.extent)
        }
    }

    /// One Core Image context for every frame: a context is costly to make
    /// and safe to share (`CIContext` is Sendable).
    nonisolated private static let imageContext = CIContext()
}

// MARK: - Search

/// What Visual Intelligence's query and the open intent run: classify a
/// frame, keep a capture per action, list them, and route a tapped one.
@MainActor
enum VisualSearch {

    /// Reads a frame: the text in it and, for a dashboard, the odometer.
    struct Readers {
        var text: (CGImage) async -> String?
        /// The reading in stored miles, given the one on file.
        var odometer: (CGImage, Int) async -> Int?

        static let live = Readers(
            text: { image in try? await ReceiptOCRService.shared.scan(image).transcript },
            odometer: { image, current in
                guard let result = try? await OdometerOCRService.shared.recognizeMileage(
                    from: UIImage(cgImage: image),
                    currentMileage: current
                ) else { return nil }
                let unit = result.detectedUnit ?? DistanceSettings.shared.unit
                return unit.toMiles(result.mileage)
            }
        )
    }

    static func results(
        labels: [String],
        pixelBuffer: CVReadOnlyPixelBuffer?,
        in container: ModelContainer
    ) async throws -> [VisualCaptureEntity] {
        guard let pixelBuffer, let image = VisualCaptureClassifier.cgImage(from: pixelBuffer) else { return [] }
        return await results(labels: labels, image: image, in: container.mainContext)
    }

    /// Classify the frame, keep a capture per action, and list them.
    static func results(
        labels: [String],
        image: CGImage,
        in context: ModelContext,
        readers: Readers? = nil
    ) async -> [VisualCaptureEntity] {
        let readers = readers ?? .live
        let store = VisualCaptureStore.shared
        // Every action lands on a vehicle, and needs one to exist.
        guard let vehicle = try? IntentStore.vehicle(for: nil, in: context) else { return [] }
        let transcript = await readers.text(image)
        let kinds = VisualCaptureClassifier.kinds(
            labels: labels,
            transcript: transcript,
            context: ReceiptExtractionService.context(for: vehicle)
        )

        var entities: [VisualCaptureEntity] = []
        for kind in kinds {
            var capture = VisualCapture(id: UUID(), kind: kind, vehicleID: vehicle.id, image: image)
            switch kind {
            case .receipt:
                break
            case .odometer:
                guard let reading = await readers.odometer(image, vehicle.currentMileage) else { continue }
                capture.reading = reading
            case .vin:
                capture.vin = VisualCaptureClassifier.vin(in: transcript ?? "")
            }
            store.add(capture)
            entities.append(VisualCaptureEntity(capture: capture, vehicleName: vehicle.displayName))
        }
        return entities
    }

    static func entities(
        ids: [UUID],
        in container: ModelContainer
    ) throws -> [VisualCaptureEntity] {
        let context = container.mainContext
        let store = VisualCaptureStore.shared
        return ids.compactMap { id in
            guard let capture = store.capture(id: id),
                  let vehicle = try? IntentStore.vehicle(id: capture.vehicleID, in: context)
            else { return nil }
            return VisualCaptureEntity(capture: capture, vehicleName: vehicle.displayName)
        }
    }

    /// Where tapping a capture lands.
    static func route(for id: UUID) throws -> PendingRoute {
        guard let capture = VisualCaptureStore.shared.capture(id: id) else { throw IntentError.captureExpired }
        switch capture.kind {
        case .receipt:
            return .logReceipt(vehicleID: capture.vehicleID, captureID: capture.id)
        case .odometer:
            guard let reading = capture.reading else { throw IntentError.captureExpired }
            return .mileageReading(vehicleID: capture.vehicleID, reading: reading)
        case .vin:
            guard let vin = capture.vin else { throw IntentError.captureExpired }
            return .addVehicle(vehicleID: capture.vehicleID, vin: vin)
        }
    }

    static func open(_ id: UUID) throws {
        EntityRoutes.open(try route(for: id))
    }
}
