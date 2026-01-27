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
        // Given
        let testImage = createTestImage()

        // When
        let results = preprocessor.preprocess(testImage)

        // Then - should return at least 2 preprocessed images (original + at least one enhanced)
        XCTAssertGreaterThanOrEqual(
            results.count,
            2,
            "Should return multiple preprocessed images"
        )
    }

    func testPreprocessIncludesOriginal() {
        // Given
        let testImage = createTestImage()

        // When
        let results = preprocessor.preprocess(testImage)

        // Then - first result should be original
        XCTAssertEqual(
            results.first?.method,
            .original,
            "First result should be the original image"
        )
    }

    func testPreprocessIncludesContrastEnhanced() {
        // Given
        let testImage = createTestImage()

        // When
        let results = preprocessor.preprocess(testImage)

        // Then
        let hasContrastEnhanced = results.contains { $0.method == .contrastEnhanced }
        XCTAssertTrue(
            hasContrastEnhanced,
            "Should include contrast enhanced version"
        )
    }

    func testPreprocessIncludesGrayscaleSharpened() {
        // Given
        let testImage = createTestImage()

        // When
        let results = preprocessor.preprocess(testImage)

        // Then
        let hasGrayscale = results.contains { $0.method == .grayscaleSharpened }
        XCTAssertTrue(
            hasGrayscale,
            "Should include grayscale sharpened version"
        )
    }

    func testPreprocessIncludesDocumentEnhanced() {
        // Given
        let testImage = createTestImage()

        // When
        let results = preprocessor.preprocess(testImage)

        // Then
        let hasDocEnhanced = results.contains { $0.method == .documentEnhanced }
        XCTAssertTrue(
            hasDocEnhanced,
            "Should include document enhanced version"
        )
    }

    func testPreprocessedImagesHaveValidDimensions() {
        // Given
        let testImage = createTestImage()

        // When
        let results = preprocessor.preprocess(testImage)

        // Then - all images should have valid dimensions
        for result in results {
            XCTAssertGreaterThan(result.image.width, 0, "\(result.method) should have valid width")
            XCTAssertGreaterThan(result.image.height, 0, "\(result.method) should have valid height")
        }
    }

    func testPreprocessingMethodCasesAreComplete() {
        // Given
        let allMethods = OdometerImagePreprocessor.PreprocessingMethod.allCases

        // Then - should have 4 methods
        XCTAssertEqual(
            allMethods.count,
            4,
            "Should have 4 preprocessing methods"
        )

        // Verify all expected methods exist
        XCTAssertTrue(allMethods.contains(.original))
        XCTAssertTrue(allMethods.contains(.contrastEnhanced))
        XCTAssertTrue(allMethods.contains(.grayscaleSharpened))
        XCTAssertTrue(allMethods.contains(.documentEnhanced))
    }

    // MARK: - Helper Methods

    /// Creates a test CGImage for preprocessing tests
    private func createTestImage() -> CGImage {
        let size = CGSize(width: 200, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)

        let uiImage = renderer.image { context in
            // White background
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // Draw some black text-like shapes
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
