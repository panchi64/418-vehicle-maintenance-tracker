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
        case grayscaleSharpened = "Grayscale Sharpened"
        case documentEnhanced = "Document Enhanced"
        case adaptiveBinarized = "Adaptive Binarized"
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

        // Grayscale + sharpen
        if let sharpened = applyGrayscaleAndSharpen(to: ciImage),
           let cgResult = context.createCGImage(sharpened, from: sharpened.extent) {
            results.append(PreprocessedImage(image: cgResult, method: .grayscaleSharpened))
        }

        // Document enhancement (good for LCD displays)
        if let docEnhanced = applyDocumentEnhancement(to: ciImage),
           let cgResult = context.createCGImage(docEnhanced, from: docEnhanced.extent) {
            results.append(PreprocessedImage(image: cgResult, method: .documentEnhanced))
        }

        // Adaptive binarization (Phase 5: good for LCD/mechanical in mixed lighting)
        if let binarized = applyAdaptiveBinarization(to: ciImage),
           let cgResult = context.createCGImage(binarized, from: binarized.extent) {
            results.append(PreprocessedImage(image: cgResult, method: .adaptiveBinarized))
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

    /// Applies grayscale conversion and edge sharpening
    nonisolated private func applyGrayscaleAndSharpen(to image: CIImage) -> CIImage? {
        // Convert to grayscale
        guard let grayscaleFilter = CIFilter(name: "CIColorMonochrome") else { return nil }
        grayscaleFilter.setValue(image, forKey: kCIInputImageKey)
        grayscaleFilter.setValue(CIColor(red: 0.7, green: 0.7, blue: 0.7), forKey: kCIInputColorKey)
        grayscaleFilter.setValue(1.0, forKey: kCIInputIntensityKey)

        guard let grayscale = grayscaleFilter.outputImage else { return nil }

        // Sharpen edges for better digit recognition
        guard let sharpenFilter = CIFilter(name: "CISharpenLuminance") else { return nil }
        sharpenFilter.setValue(grayscale, forKey: kCIInputImageKey)
        sharpenFilter.setValue(0.7, forKey: kCIInputSharpnessKey)

        return sharpenFilter.outputImage
    }

    /// Applies document enhancement filter (good for LCD/digital displays)
    nonisolated private func applyDocumentEnhancement(to image: CIImage) -> CIImage? {
        // Use unsharp mask for edge enhancement
        guard let unsharpMask = CIFilter(name: "CIUnsharpMask") else { return nil }
        unsharpMask.setValue(image, forKey: kCIInputImageKey)
        unsharpMask.setValue(2.5, forKey: kCIInputRadiusKey)
        unsharpMask.setValue(0.5, forKey: kCIInputIntensityKey)

        guard let unsharpened = unsharpMask.outputImage else { return nil }

        // Apply exposure adjustment for better contrast
        guard let exposureFilter = CIFilter(name: "CIExposureAdjust") else { return nil }
        exposureFilter.setValue(unsharpened, forKey: kCIInputImageKey)
        exposureFilter.setValue(0.3, forKey: kCIInputEVKey)

        guard let exposed = exposureFilter.outputImage else { return nil }

        // High contrast for LCD readability
        guard let contrastFilter = CIFilter(name: "CIColorControls") else { return nil }
        contrastFilter.setValue(exposed, forKey: kCIInputImageKey)
        contrastFilter.setValue(1.2, forKey: kCIInputContrastKey)
        contrastFilter.setValue(0.0, forKey: kCIInputSaturationKey)  // Full grayscale

        return contrastFilter.outputImage
    }

    /// Applies adaptive binarization for LCD displays and mechanical odometers in mixed lighting
    /// Converts to grayscale, applies very high contrast, then uses color matrix to threshold mid-grays
    nonisolated private func applyAdaptiveBinarization(to image: CIImage) -> CIImage? {
        // Step 1: Grayscale conversion
        guard let grayscaleFilter = CIFilter(name: "CIColorMonochrome") else { return nil }
        grayscaleFilter.setValue(image, forKey: kCIInputImageKey)
        grayscaleFilter.setValue(CIColor(red: 0.7, green: 0.7, blue: 0.7), forKey: kCIInputColorKey)
        grayscaleFilter.setValue(1.0, forKey: kCIInputIntensityKey)

        guard let grayscale = grayscaleFilter.outputImage else { return nil }

        // Step 2: Very high contrast to push pixels toward black/white
        guard let contrastFilter = CIFilter(name: "CIColorControls") else { return nil }
        contrastFilter.setValue(grayscale, forKey: kCIInputImageKey)
        contrastFilter.setValue(3.0, forKey: kCIInputContrastKey)
        contrastFilter.setValue(0.0, forKey: kCIInputSaturationKey)

        guard let highContrast = contrastFilter.outputImage else { return nil }

        // Step 3: Color matrix to amplify channels and threshold mid-grays
        guard let matrixFilter = CIFilter(name: "CIColorMatrix") else { return nil }
        matrixFilter.setValue(highContrast, forKey: kCIInputImageKey)
        matrixFilter.setValue(CIVector(x: 1.5, y: 0, z: 0, w: 0), forKey: "inputRVector")
        matrixFilter.setValue(CIVector(x: 0, y: 1.5, z: 0, w: 0), forKey: "inputGVector")
        matrixFilter.setValue(CIVector(x: 0, y: 0, z: 1.5, w: 0), forKey: "inputBVector")
        matrixFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
        matrixFilter.setValue(CIVector(x: -0.3, y: -0.3, z: -0.3, w: 0), forKey: "inputBiasVector")

        return matrixFilter.outputImage
    }
}
