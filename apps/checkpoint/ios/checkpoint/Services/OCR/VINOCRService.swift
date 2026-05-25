//
//  VINOCRService.swift
//  checkpoint
//
//  On-device OCR for scanning VINs from photos using Vision framework
//  Preprocesses images for sticker/plate reading (sharpening, binarization)
//

import Foundation
import Vision
import UIKit
import CoreImage

actor VINOCRService {
    static let shared = VINOCRService()

    struct VINOCRResult: Sendable {
        let vin: String
        let confidence: Float
    }

    /// Valid VIN characters (no I, O, Q)
    private static let validVINPattern = "^[A-HJ-NPR-Z0-9]{17}$"

    func recognizeVIN(from image: UIImage) async throws -> VINOCRResult {
        guard let cgImage = image.cgImage else {
            throw VINOCRError.imageProcessingFailed
        }

        let orientation = Self.cgOrientation(from: image.imageOrientation)

        // Preprocess: create multiple enhanced versions for different VIN surfaces
        let variants = Self.preprocessForVIN(cgImage)

        var bestCandidate: VINOCRResult?

        for variant in variants {
            let handler = VNImageRequestHandler(cgImage: variant, orientation: orientation, options: [:])
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false
            request.recognitionLanguages = ["en-US"]

            do {
                try handler.perform([request])
            } catch {
                continue
            }

            guard let observations = request.results, !observations.isEmpty else {
                continue
            }

            for observation in observations {
                guard let topCandidate = observation.topCandidates(1).first else { continue }

                let text = topCandidate.string
                    .uppercased()
                    .replacingOccurrences(of: " ", with: "")
                    .replacingOccurrences(of: "-", with: "")

                // Apply OCR character corrections
                let corrected = Self.applyOCRCorrections(text)

                // Check if this is a valid 17-char VIN
                if Self.isValidVIN(corrected) {
                    let confidence = topCandidate.confidence
                    if confidence > (bestCandidate?.confidence ?? -1) {
                        bestCandidate = VINOCRResult(vin: corrected, confidence: confidence)
                    }
                }

                // Also try to find a VIN embedded in longer text
                if corrected.count > 17 {
                    if let extracted = Self.extractVINFromText(corrected) {
                        let confidence = topCandidate.confidence * 0.9
                        if confidence > (bestCandidate?.confidence ?? -1) {
                            bestCandidate = VINOCRResult(vin: extracted, confidence: confidence)
                        }
                    }
                }
            }
        }

        guard let result = bestCandidate else {
            throw VINOCRError.noVINFound
        }

        return result
    }

    // MARK: - Preprocessing

    /// Creates multiple enhanced versions of the image optimized for VIN reading.
    /// VINs appear on door jamb stickers, dashboard plates, and documents — each
    /// surface benefits from different preprocessing.
    private static func preprocessForVIN(_ image: CGImage) -> [CGImage] {
        var results: [CGImage] = [image]  // Always include original

        let context = CIContext(options: [.useSoftwareRenderer: false])
        let ciImage = CIImage(cgImage: image)

        // 1. Sharpen + contrast boost — helps with stamped/engraved VIN plates
        if let sharpened = applySharpenAndContrast(to: ciImage),
           let cg = context.createCGImage(sharpened, from: sharpened.extent) {
            results.append(cg)
        }

        // 2. Grayscale + high contrast — helps with sticker VINs and glare
        if let binarized = applyGrayscaleHighContrast(to: ciImage),
           let cg = context.createCGImage(binarized, from: binarized.extent) {
            results.append(cg)
        }

        return results
    }

    /// Sharpens and boosts contrast for stamped/engraved metal VIN plates
    private static func applySharpenAndContrast(to image: CIImage) -> CIImage? {
        // Sharpen
        guard let sharpen = CIFilter(name: "CISharpenLuminance") else { return nil }
        sharpen.setValue(image, forKey: kCIInputImageKey)
        sharpen.setValue(0.8, forKey: kCIInputSharpnessKey)

        guard let sharpened = sharpen.outputImage else { return nil }

        // Contrast boost
        guard let contrast = CIFilter(name: "CIColorControls") else { return nil }
        contrast.setValue(sharpened, forKey: kCIInputImageKey)
        contrast.setValue(1.5, forKey: kCIInputContrastKey)
        contrast.setValue(0.0, forKey: kCIInputSaturationKey)  // Full desaturation
        contrast.setValue(0.05, forKey: kCIInputBrightnessKey)

        return contrast.outputImage
    }

    /// Converts to grayscale with high contrast for sticker VINs
    private static func applyGrayscaleHighContrast(to image: CIImage) -> CIImage? {
        guard let filter = CIFilter(name: "CIColorControls") else { return nil }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(2.0, forKey: kCIInputContrastKey)       // Aggressive contrast
        filter.setValue(0.0, forKey: kCIInputSaturationKey)     // Full grayscale
        filter.setValue(-0.1, forKey: kCIInputBrightnessKey)    // Slight darken to crisp up text

        return filter.outputImage
    }

    // MARK: - VIN Validation

    private static func isValidVIN(_ text: String) -> Bool {
        text.range(of: validVINPattern, options: .regularExpression) != nil
    }

    private static func extractVINFromText(_ text: String) -> String? {
        guard text.count >= 17 else { return nil }
        for i in 0...(text.count - 17) {
            let start = text.index(text.startIndex, offsetBy: i)
            let end = text.index(start, offsetBy: 17)
            let candidate = String(text[start..<end])
            if isValidVIN(candidate) {
                return candidate
            }
        }
        return nil
    }

    // MARK: - OCR Corrections

    private static func applyOCRCorrections(_ text: String) -> String {
        var result = text
        // Common OCR misreads for VINs — these characters are invalid in VINs
        result = result.replacingOccurrences(of: "O", with: "0")
        result = result.replacingOccurrences(of: "I", with: "1")
        result = result.replacingOccurrences(of: "Q", with: "0")
        return result
    }

    // MARK: - Orientation

    private static func cgOrientation(from uiOrientation: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch uiOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}

// MARK: - Error Types

enum VINOCRError: LocalizedError {
    case imageProcessingFailed
    case noTextFound
    case noVINFound

    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed:
            return String(localized: "ocr.error.image_processing_failed")
        case .noTextFound:
            return String(localized: "ocr.error.no_text_found")
        case .noVINFound:
            return String(localized: "ocr.error.no_valid_vin")
        }
    }
}
