//
//  LanguageModelSessioning.swift
//  checkpoint
//
//  The seam between Checkpoint and Apple's on-device model. Everything that
//  uses the model asks through this protocol, so tests hand in a fake session
//  with canned answers and the pipeline around the model — validation,
//  merging with the rules, fallbacks — is tested without Apple Intelligence.
//
//  Answers come back as plain structs (`ModelReceiptReading`), not the
//  `@Generable` types the model fills: those are an implementation detail of
//  `OnDeviceLanguageModel`.
//

import CoreGraphics
import Foundation
import ImageIO

/// What the model is asked to read.
struct ReceiptModelRequest {
    var scan: ReceiptScan
    /// The vehicle's service names and the presets, for `ServiceNameTool`.
    var knownServiceNames: [String]
    /// The photo itself. Only used on iOS 27, where the model takes images.
    var image: CGImage?
    var imageOrientation: CGImagePropertyOrientation = .up
}

/// The model's reading of a receipt, before any checks.
nonisolated struct ModelReceiptReading: Equatable, Sendable {
    var shopName: String?
    var date: Date?
    var total: Decimal?
    var tax: Decimal?
    var odometer: Int?
    var lineItems: [ReceiptLineItem] = []
    var serviceNames: [String] = []
}

protocol LanguageModelSessioning {
    /// Read a receipt into fields. Throws when the model can't answer (not
    /// available, context exceeded, guardrail): the caller falls back to the
    /// rules.
    func readReceipt(_ request: ReceiptModelRequest) async throws -> ModelReceiptReading

    /// Which kind of vehicle document this text is, or nil when the model
    /// isn't sure.
    func classifyDocument(text: String) async throws -> DocumentType?
}
