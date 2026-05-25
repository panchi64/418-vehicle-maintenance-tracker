import Foundation
import Vision
import UIKit
import ImageIO

private extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}

struct PriceCandidate: Equatable {
    let value: Double
    let confidence: Float
}

struct FuelOCRResult: Equatable {
    let rawText: String
    let candidates: [PriceCandidate]
}

actor FuelOCRService {
    static let shared = FuelOCRService()

    func extract(from image: UIImage) async throws -> FuelOCRResult {
        guard let cgImage = image.cgImage else {
            return FuelOCRResult(rawText: "", candidates: [])
        }
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        return try await Task.detached(priority: .userInitiated) {
            try Self.performRecognition(cgImage: cgImage, orientation: orientation)
        }.value
    }

    private static func performRecognition(cgImage: CGImage, orientation: CGImagePropertyOrientation) throws -> FuelOCRResult {
        let request = VNRecognizeTextRequest()
        request.recognitionLanguages = ["en-US", "es-ES"]
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false

        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
        try handler.perform([request])

        guard let observations = request.results else {
            return FuelOCRResult(rawText: "", candidates: [])
        }

        var lines: [String] = []
        var candidates: [PriceCandidate] = []

        for observation in observations {
            guard let top = observation.topCandidates(1).first else { continue }
            lines.append(top.string)
            candidates.append(contentsOf: parsePrices(from: top.string, confidence: top.confidence))
        }

        candidates.sort { $0.confidence > $1.confidence }
        return FuelOCRResult(rawText: lines.joined(separator: "\n"), candidates: candidates)
    }

    static func parsePrices(from text: String, confidence: Float) -> [PriceCandidate] {
        var results: [PriceCandidate] = []
        let pattern = #"\$?\s*([0-9]+(?:[.,][0-9]{1,3}))"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return results }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        regex.enumerateMatches(in: text, range: range) { match, _, _ in
            guard let match, let r = Range(match.range(at: 1), in: text) else { return }
            let normalized = text[r].replacingOccurrences(of: ",", with: ".")
            if let value = Double(normalized), (0.10...20.0).contains(value) {
                results.append(PriceCandidate(value: value, confidence: confidence))
            }
        }
        return results
    }
}
