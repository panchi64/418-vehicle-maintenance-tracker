//
//  OdometerImagePreprocessor.swift
//  checkpoint
//
//  Image preprocessing for improved OCR accuracy on odometer displays
//  Uses Core Image filters to create multiple enhanced versions of the image
//

import CoreGraphics
import CoreImage

/// Preprocesses odometer images for improved OCR accuracy
/// Uses Core Image filters synchronously - safe for use from any actor
struct OdometerImagePreprocessor: Sendable {

    // MARK: - Types

    /// Result of preprocessing containing the enhanced image and method used
    struct PreprocessedImage: Sendable {
        let image: CGImage
        let method: PreprocessingMethod
    }

    /// Available preprocessing methods
    enum PreprocessingMethod: String, CaseIterable, Sendable {
        case original = "Original"
        case contrastEnhanced = "Contrast Enhanced"
    }

    // MARK: - Initialization

    nonisolated init() {}

    // MARK: - Public API

    /// Preprocesses an image using multiple enhancement methods
    /// - Parameter image: Original CGImage to process
    /// - Returns: Array of preprocessed images to try for OCR
    nonisolated func preprocess(_ image: CGImage) -> [PreprocessedImage] {
        var results: [PreprocessedImage] = []

        // Create context for rendering
        let context = CIContext(options: [.useSoftwareRenderer: false])

        // Always include original
        results.append(PreprocessedImage(image: image, method: .original))

        let ciImage = CIImage(cgImage: image)

        // Contrast enhancement
        if let enhanced = applyContrastEnhancement(to: ciImage),
           let cgResult = context.createCGImage(enhanced, from: enhanced.extent) {
            results.append(PreprocessedImage(image: cgResult, method: .contrastEnhanced))
        }

        return results
    }

    // MARK: - Private Methods

    /// Applies contrast enhancement with reduced saturation
    nonisolated private func applyContrastEnhancement(to image: CIImage) -> CIImage? {
        guard let filter = CIFilter(name: "CIColorControls") else { return nil }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(1.3, forKey: kCIInputContrastKey)      // Boost contrast
        filter.setValue(0.2, forKey: kCIInputSaturationKey)    // Reduce color noise
        filter.setValue(0.05, forKey: kCIInputBrightnessKey)   // Slight brightness boost
        return filter.outputImage
    }
}
