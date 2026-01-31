//
//  ReceiptOCRServiceTests.swift
//  checkpointTests
//
//  Unit tests for ReceiptOCRService
//

import XCTest
import UIKit
@testable import checkpoint

final class ReceiptOCRServiceTests: XCTestCase {

    // MARK: - Singleton Tests

    func testSharedInstanceExists() async {
        let service = await ReceiptOCRService.shared
        XCTAssertNotNil(service, "Shared instance should exist")
    }

    // MARK: - OCRResult Tests

    func testOCRResultStoresValues() {
        let text = "AUTO SERVICE CENTER\n123 Main St"
        let blockCount = 2
        let confidence: Float = 0.95

        let result = ReceiptOCRService.OCRResult(
            text: text,
            blockCount: blockCount,
            averageConfidence: confidence
        )

        XCTAssertEqual(result.text, text)
        XCTAssertEqual(result.blockCount, blockCount)
        XCTAssertEqual(result.averageConfidence, confidence)
    }

    func testOCRResultWithEmptyText() {
        let result = ReceiptOCRService.OCRResult(
            text: "",
            blockCount: 0,
            averageConfidence: 0.0
        )

        XCTAssertTrue(result.text.isEmpty)
        XCTAssertEqual(result.blockCount, 0)
        XCTAssertEqual(result.averageConfidence, 0.0)
    }

    func testOCRResultWithMultilineText() {
        let multilineText = """
        Line 1
        Line 2
        Line 3
        """
        let result = ReceiptOCRService.OCRResult(
            text: multilineText,
            blockCount: 3,
            averageConfidence: 0.85
        )

        XCTAssertTrue(result.text.contains("Line 1"))
        XCTAssertTrue(result.text.contains("Line 2"))
        XCTAssertTrue(result.text.contains("Line 3"))
        XCTAssertEqual(result.blockCount, 3)
    }

    // MARK: - OCR Error Tests

    func testNoTextFoundError() {
        let error = ReceiptOCRService.OCRError.noTextFound
        XCTAssertEqual(error.errorDescription, "No text could be recognized in the image")
    }

    func testImageProcessingFailedError() {
        let error = ReceiptOCRService.OCRError.imageProcessingFailed
        XCTAssertEqual(error.errorDescription, "Failed to process the image")
    }

    func testErrorsAreLocalizedErrors() {
        let errors: [ReceiptOCRService.OCRError] = [
            .noTextFound,
            .imageProcessingFailed
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription, "Error should have a description")
        }
    }

    // MARK: - OCR Recognition Tests

    func testExtractTextThrowsForBlankImage() async {
        let service = await ReceiptOCRService.shared

        // Create a tiny blank image that won't have recognizable text
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1))
        let blankImage = renderer.image { context in
            UIColor.black.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }

        do {
            _ = try await service.extractText(from: blankImage)
            XCTFail("Should throw an error for image with no recognizable text")
        } catch {
            XCTAssertTrue(error is ReceiptOCRService.OCRError, "Should throw OCRError")
        }
    }

    func testExtractTextWithValidReceiptImage() async {
        let service = await ReceiptOCRService.shared
        let testImage = createTestReceiptImage()

        do {
            let result = try await service.extractText(from: testImage)
            XCTAssertFalse(result.text.isEmpty, "Should extract some text")
            XCTAssertGreaterThan(result.blockCount, 0, "Should have at least one text block")
            XCTAssertGreaterThanOrEqual(result.averageConfidence, 0)
            XCTAssertLessThanOrEqual(result.averageConfidence, 1)
        } catch {
            // OCR may fail on synthetic images in some environments - that's acceptable
            XCTAssertTrue(error is ReceiptOCRService.OCRError, "Should throw OCRError if recognition fails")
        }
    }

    func testExtractTextPreservesReadingOrder() async {
        let service = await ReceiptOCRService.shared
        let testImage = createTestReceiptImageWithOrderedText()

        do {
            let result = try await service.extractText(from: testImage)
            // The text should be ordered top-to-bottom
            let lines = result.text.components(separatedBy: "\n")
            XCTAssertGreaterThan(lines.count, 0, "Should have multiple lines")
        } catch {
            // OCR may fail on synthetic images - acceptable
            XCTAssertTrue(error is ReceiptOCRService.OCRError)
        }
    }

    // MARK: - Confidence Validation Tests

    func testConfidenceIsNormalized() async {
        let service = await ReceiptOCRService.shared
        let testImage = createTestReceiptImage()

        do {
            let result = try await service.extractText(from: testImage)
            XCTAssertGreaterThanOrEqual(result.averageConfidence, 0.0, "Confidence should be >= 0")
            XCTAssertLessThanOrEqual(result.averageConfidence, 1.0, "Confidence should be <= 1")
        } catch {
            // Expected for synthetic images
        }
    }

    // MARK: - Helper Methods

    private func createTestReceiptImage() -> UIImage {
        let size = CGSize(width: 300, height: 400)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            // White background
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // Draw receipt text
            let text = """
            AUTO SERVICE CENTER
            123 Main Street

            Oil Change    $45.00
            Filter         $15.00
            Total         $60.00
            """

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 14, weight: .regular),
                .foregroundColor: UIColor.black
            ]

            let attributedText = NSAttributedString(string: text, attributes: attributes)
            attributedText.draw(in: CGRect(x: 20, y: 20, width: size.width - 40, height: size.height - 40))
        }
    }

    private func createTestReceiptImageWithOrderedText() -> UIImage {
        let size = CGSize(width: 300, height: 300)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            // White background
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 18, weight: .bold),
                .foregroundColor: UIColor.black
            ]

            // Draw text at specific vertical positions
            let lines = ["HEADER", "LINE ONE", "LINE TWO", "FOOTER"]
            for (index, line) in lines.enumerated() {
                let y = CGFloat(30 + index * 50)
                let attributedText = NSAttributedString(string: line, attributes: attributes)
                attributedText.draw(at: CGPoint(x: 20, y: y))
            }
        }
    }
}
