//
//  OdometerCaptureViewTests.swift
//  checkpointTests
//
//  Unit tests for OdometerCaptureView crop calculation
//

import XCTest
import UIKit
@testable import checkpoint

final class OdometerCaptureViewTests: XCTestCase {

    // MARK: - Viewfinder Crop Calculation Tests

    func testViewfinderCropCalculation() {
        // Create a test image (1000x2000 simulating a portrait photo)
        let imageSize = CGSize(width: 1000, height: 2000)
        let renderer = UIGraphicsImageRenderer(size: imageSize)
        let testImage = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: imageSize))
        }

        // Simulate a preview layer size (375x812, typical iPhone screen)
        let previewSize = CGSize(width: 375, height: 812)

        // Viewfinder rect: centered, 80% width, 3:1 aspect
        let vfWidth: CGFloat = 375 * 0.80
        let vfHeight = vfWidth / 3.0
        let vfX = (375 - vfWidth) / 2
        let vfY: CGFloat = 400

        let viewfinderRect = CGRect(x: vfX, y: vfY, width: vfWidth, height: vfHeight)

        let croppedImage = OdometerCaptureViewController.cropToViewfinder(
            image: testImage,
            viewfinderRect: viewfinderRect,
            previewLayerSize: previewSize
        )

        // The cropped image should be smaller than the original
        guard let cgCropped = croppedImage.cgImage else {
            XCTFail("Cropped image should have a cgImage")
            return
        }

        XCTAssertLessThanOrEqual(
            CGFloat(cgCropped.width),
            CGFloat(testImage.cgImage!.width),
            "Cropped width should be less than or equal to original"
        )
        XCTAssertLessThanOrEqual(
            CGFloat(cgCropped.height),
            CGFloat(testImage.cgImage!.height),
            "Cropped height should be less than or equal to original"
        )
        XCTAssertGreaterThan(cgCropped.width, 0, "Cropped image should have non-zero width")
        XCTAssertGreaterThan(cgCropped.height, 0, "Cropped image should have non-zero height")
    }

    func testCropReturnsOriginalOnFailure() {
        // Create a very small image that would make crop rect out of bounds
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1))
        let tinyImage = renderer.image { context in
            UIColor.black.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }

        // Huge viewfinder rect relative to image
        let viewfinderRect = CGRect(x: 500, y: 500, width: 300, height: 100)
        let previewSize = CGSize(width: 375, height: 812)

        let result = OdometerCaptureViewController.cropToViewfinder(
            image: tinyImage,
            viewfinderRect: viewfinderRect,
            previewLayerSize: previewSize
        )

        // Should return something (either cropped or original fallback) without crashing
        XCTAssertNotNil(result.cgImage, "Should return a valid image")
    }
}
