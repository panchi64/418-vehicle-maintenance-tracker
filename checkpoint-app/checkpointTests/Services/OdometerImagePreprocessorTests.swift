//
//  OdometerImagePreprocessorTests.swift
//  checkpointTests
//
//  Unit tests for OdometerImagePreprocessor
//

import XCTest
import UIKit
@testable import checkpoint

final class OdometerImagePreprocessorTests: XCTestCase {

    private let preprocessor = OdometerImagePreprocessor()

    // MARK: - Preprocessing Method Tests

    func testPreprocessReturnsMultipleImages() {
        let testImage = createTestImage()
        let results = preprocessor.preprocess(testImage)
        XCTAssertGreaterThanOrEqual(results.count, 2, "Should return multiple preprocessed images")
    }

    func testPreprocessIncludesOriginal() {
        let testImage = createTestImage()
        let results = preprocessor.preprocess(testImage)
        XCTAssertEqual(results.first?.method, .original, "First result should be the original image")
    }

    func testPreprocessIncludesContrastEnhanced() {
        let testImage = createTestImage()
        let results = preprocessor.preprocess(testImage)
        let hasContrastEnhanced = results.contains { $0.method == .contrastEnhanced }
        XCTAssertTrue(hasContrastEnhanced, "Should include contrast enhanced version")
    }

    func testPreprocessIncludesGrayscaleSharpened() {
        let testImage = createTestImage()
        let results = preprocessor.preprocess(testImage)
        let hasGrayscale = results.contains { $0.method == .grayscaleSharpened }
        XCTAssertTrue(hasGrayscale, "Should include grayscale sharpened version")
    }

    func testPreprocessIncludesDocumentEnhanced() {
        let testImage = createTestImage()
        let results = preprocessor.preprocess(testImage)
        let hasDocEnhanced = results.contains { $0.method == .documentEnhanced }
        XCTAssertTrue(hasDocEnhanced, "Should include document enhanced version")
    }

    func testPreprocessIncludesAdaptiveBinarized() {
        let testImage = createTestImage()
        let results = preprocessor.preprocess(testImage)
        let hasBinarized = results.contains { $0.method == .adaptiveBinarized }
        XCTAssertTrue(hasBinarized, "Should include adaptive binarized version")
    }

    func testPreprocessedImagesHaveValidDimensions() {
        let testImage = createTestImage()
        let results = preprocessor.preprocess(testImage)
        for result in results {
            XCTAssertGreaterThan(result.image.width, 0, "\(result.method) should have valid width")
            XCTAssertGreaterThan(result.image.height, 0, "\(result.method) should have valid height")
        }
    }

    func testPreprocessingMethodCasesAreComplete() {
        let allMethods = OdometerImagePreprocessor.PreprocessingMethod.allCases

        XCTAssertEqual(allMethods.count, 5, "Should have 5 preprocessing methods")

        XCTAssertTrue(allMethods.contains(.original))
        XCTAssertTrue(allMethods.contains(.contrastEnhanced))
        XCTAssertTrue(allMethods.contains(.grayscaleSharpened))
        XCTAssertTrue(allMethods.contains(.documentEnhanced))
        XCTAssertTrue(allMethods.contains(.adaptiveBinarized))
    }

    // MARK: - Helper Methods

    private func createTestImage() -> CGImage {
        let size = CGSize(width: 200, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)

        let uiImage = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            UIColor.black.setFill()
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 36, weight: .bold),
                .foregroundColor: UIColor.black
            ]

            let text = NSAttributedString(string: "123456", attributes: attributes)
            text.draw(at: CGPoint(x: 20, y: 30))
        }

        return uiImage.cgImage!
    }
}
