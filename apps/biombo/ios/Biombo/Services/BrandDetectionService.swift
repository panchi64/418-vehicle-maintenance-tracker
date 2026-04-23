import Foundation
import SwiftData

struct BrandMatch: Equatable {
    let brand: String
    let confidence: Double
}

enum BrandDetectionService {
    static func detect(in ocrText: String, knownBrands: [String]) -> BrandMatch? {
        let haystack = ocrText.lowercased()
        let sortedByLengthDesc = knownBrands.sorted { $0.count > $1.count }
        for brand in sortedByLengthDesc {
            let needle = brand.lowercased()
            guard haystack.contains(needle) else { continue }
            let confidence = Double(needle.count) / Double(max(haystack.count, 1))
            return BrandMatch(brand: brand, confidence: min(confidence * 2, 1.0))
        }
        return nil
    }

    @MainActor
    static func detect(in ocrText: String, context: ModelContext) -> BrandMatch? {
        let descriptor = FetchDescriptor<CachedBrand>()
        guard let brands = try? context.fetch(descriptor) else { return nil }
        return detect(in: ocrText, knownBrands: brands.map(\.name))
    }
}
