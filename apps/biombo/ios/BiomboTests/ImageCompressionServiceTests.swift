import XCTest
import UIKit
@testable import Biombo

final class ImageCompressionServiceTests: XCTestCase {
    func testCompressProducesSmallerJPEG() async throws {
        let image = makeImage(size: CGSize(width: 2000, height: 2000), color: .red)
        let data = await ImageCompressionService.compress(image, maxDimension: 400, quality: 0.5)
        let compressed = try XCTUnwrap(data)
        XCTAssertLessThan(compressed.count, 80_000)
    }

    func testCompressShrinksTo400pxLongestEdge() async throws {
        let image = makeImage(size: CGSize(width: 2000, height: 1000), color: .blue)
        let data = await ImageCompressionService.compress(image, maxDimension: 400, quality: 0.7)
        let compressed = try XCTUnwrap(data)
        let decoded = try XCTUnwrap(UIImage(data: compressed))
        XCTAssertEqual(decoded.size.width, 400, accuracy: 1)
        XCTAssertEqual(decoded.size.height, 200, accuracy: 1)
    }

    private func makeImage(size: CGSize, color: UIColor) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }
}
