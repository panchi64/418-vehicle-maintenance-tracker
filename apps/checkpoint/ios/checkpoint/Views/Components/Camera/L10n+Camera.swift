//
//  L10n+Camera.swift
//  checkpoint
//
//  Strings for the camera/OCR capture views. Keys are prefixed `camera.`.
//
//  The OCR error accessors are `nonisolated` because the OCR services build
//  their error descriptions off the main actor.
//

import Foundation

extension L10n {
    nonisolated private static func camera(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    static var cameraAlignOdometer: String { camera("camera.guide.odometer") }

    static var cameraConfidenceHigh: String { camera("camera.confidence.high") }
    static var cameraConfidenceMedium: String { camera("camera.confidence.medium") }
    static var cameraConfidenceLow: String { camera("camera.confidence.low") }

    nonisolated static var cameraReceiptNoText: String { camera("camera.receipt.noText") }
    nonisolated static var cameraReceiptProcessingFailed: String { camera("camera.receipt.processingFailed") }
}
