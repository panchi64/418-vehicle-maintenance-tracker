import Foundation
import ImageIO
import UniformTypeIdentifiers

/// A price-sign photo as it leaves the device (PRODUCT.md §4.2, §13): EXIF
/// and GPS stripped, orientation baked in, at most `maxPixels` on its long
/// side. Photos stay private until the price is confirmed (§5).
nonisolated enum PriceSignPhoto {
    nonisolated static let maxPixels = 2_048

    /// A JPEG with no metadata, or nil when `data` isn't an image. Decoding
    /// a large photo is slow, so it runs off the main actor.
    @concurrent
    static func stripped(_ data: Data) async -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixels,
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, UTType.jpeg.identifier as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: 0.8] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return output as Data
    }
}

/// Reads prices off a sign photo so the user only confirms them (§6.1
/// "OCR fills the price, the user confirms"). Brand comes from the station
/// directory, never from here. Until on-device text recognition lands the
/// app injects no reader: the user types the price and the photo travels
/// as evidence, with no note about reading the sign.
nonisolated protocol PriceSignReading: Sendable {
    func prices(in photo: Data) async -> [FuelGrade: Double]
}
