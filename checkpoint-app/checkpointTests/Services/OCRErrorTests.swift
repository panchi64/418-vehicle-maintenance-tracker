@testable import checkpoint
import Foundation
import Testing

@Suite("OCR Error Message Tests")
struct OCRErrorTests {

    @Test("Odometer OCR errors have user-friendly descriptions")
    func odometerOCRErrorDescriptions() {
        let noText = OdometerOCRService.OCRError.noTextFound
        #expect(noText.localizedDescription == L10n.ocrErrorNoTextFound)

        let noMileage = OdometerOCRService.OCRError.noValidMileageFound
        #expect(noMileage.localizedDescription == L10n.ocrErrorNoValidMileage)

        let imageFailed = OdometerOCRService.OCRError.imageProcessingFailed
        #expect(imageFailed.localizedDescription == L10n.ocrErrorImageProcessingFailed)

        let invalid = OdometerOCRService.OCRError.invalidMileage(reason: "test")
        #expect(invalid.localizedDescription == L10n.ocrErrorInvalidMileage)
    }

    @Test("VIN OCR errors have user-friendly descriptions")
    func vinOCRErrorDescriptions() {
        let noText = VINOCRError.noTextFound
        #expect(noText.localizedDescription == L10n.ocrErrorNoTextFound)

        let imageFailed = VINOCRError.imageProcessingFailed
        #expect(imageFailed.localizedDescription == L10n.ocrErrorImageProcessingFailed)

        let noVIN = VINOCRError.noVINFound
        #expect(noVIN.localizedDescription == L10n.ocrErrorNoValidVIN)
    }

    @Test("OCR error messages are not technical")
    func ocrErrorMessagesAreNotTechnical() {
        // Verify messages don't contain technical jargon
        let errors: [any LocalizedError] = [
            OdometerOCRService.OCRError.noTextFound,
            OdometerOCRService.OCRError.noValidMileageFound,
            OdometerOCRService.OCRError.imageProcessingFailed,
            VINOCRError.noTextFound,
            VINOCRError.noVINFound,
        ]

        for error in errors {
            let desc = error.localizedDescription
            #expect(!desc.contains("Failed to"))
            #expect(!desc.contains("Error:"))
            #expect(!desc.contains("nil"))
        }
    }
}
