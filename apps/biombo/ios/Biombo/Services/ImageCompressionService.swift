import UIKit

enum ImageCompressionService {
    /// Resize + JPEG-encode on a background executor.
    /// `UIGraphicsImageRenderer` + `jpegData` do not carry EXIF/GPS from the
    /// source image (the renderer draws into a fresh bitmap), so no explicit
    /// metadata strip is needed.
    static func compress(_ image: UIImage, maxDimension: CGFloat = 400, quality: CGFloat = 0.5) async -> Data? {
        await Task.detached(priority: .userInitiated) {
            let scale = min(maxDimension / image.size.width, maxDimension / image.size.height, 1)
            let targetSize = CGSize(
                width: image.size.width * scale,
                height: image.size.height * scale
            )

            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            format.opaque = true
            let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
            let resized = renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: targetSize))
            }
            return resized.jpegData(compressionQuality: quality)
        }.value
    }
}
