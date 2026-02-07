//
//  VehicleFormState.swift
//  checkpoint
//
//  Shared state for the 2-step add vehicle wizard flow
//

import SwiftUI

@Observable
final class VehicleFormState {
    // MARK: - Step 1: Basics
    var name: String = ""
    var make: String = ""
    var model: String = ""
    var year: Int? = nil

    // MARK: - Step 2: Details
    var currentMileage: Int? = nil
    var vin: String = ""
    var tireSize: String = ""
    var oilType: String = ""
    var notes: String = ""

    // MARK: - Analytics Tracking
    var usedOdometerOCR = false
    var usedVINLookup = false

    // MARK: - VIN Lookup State
    var isDecodingVIN = false
    var vinLookupError: String?

    // MARK: - VIN OCR State
    var showVINCamera = false
    var isProcessingVINOCR = false
    var vinOCRError: String?
    var vinOCROriginal: String?

    // MARK: - Odometer OCR State
    var showOdometerCamera = false
    var showOCRConfirmation = false
    var ocrResult: OdometerOCRService.OCRResult?
    var ocrDebugImage: UIImage?
    var isProcessingOdometerOCR = false
    var odometerOCRError: String?

    // MARK: - Validation

    /// Step 1 is valid when Make, Model, and Year are all provided
    var isBasicsValid: Bool {
        !make.trimmingCharacters(in: .whitespaces).isEmpty &&
        !model.trimmingCharacters(in: .whitespaces).isEmpty &&
        year != nil
    }

    /// VIN is valid when it's 17 alphanumeric characters (excluding I, O, Q)
    var isVINValid: Bool {
        let trimmed = vin.trimmingCharacters(in: .whitespaces)
        guard trimmed.count == 17 else { return false }
        let forbidden = CharacterSet(charactersIn: "IOQioq")
        return trimmed.unicodeScalars.allSatisfy {
            !forbidden.contains($0) && CharacterSet.alphanumerics.contains($0)
        }
    }

    /// Check if camera is available (requires physical device)
    var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    // MARK: - Actions

    /// Clear VIN-related errors when VIN changes
    func clearVINErrors() {
        vinLookupError = nil
    }

    /// Clear odometer OCR error
    func clearOdometerError() {
        odometerOCRError = nil
    }

    /// Clear VIN OCR error
    func clearVINOCRError() {
        vinOCRError = nil
    }
}
