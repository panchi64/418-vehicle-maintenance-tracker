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
        XCTAssertEqual(results.count, 2, "Should return original + contrast enhanced")
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

        XCTAssertEqual(allMethods.count, 2, "Should have 2 preprocessing methods")

        XCTAssertTrue(allMethods.contains(.original))
        XCTAssertTrue(allMethods.contains(.contrastEnhanced))
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
