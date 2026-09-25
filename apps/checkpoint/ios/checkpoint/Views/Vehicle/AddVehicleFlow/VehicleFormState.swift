//
//  VehicleFormState.swift
//  checkpoint
//
//  State for the single-scroll add-vehicle form. The `Step 1` / `Step 2`
//  grouping below is gone with the wizard — the fields are one set.
//

import SwiftUI

@Observable
final class VehicleFormState {
    // MARK: - Identity
    var name: String = ""
    var make: String = ""
    var model: String = ""
    var year: Int? = nil

    // MARK: - Reference
    var currentMileage: Int? = nil
    var vin: String = ""
    var licensePlate: String = ""
    var tireSize: String = ""
    var oilType: String = ""
    var notes: String = ""

    // MARK: - Marbete (Registration Tag)
    var marbeteExpirationMonth: Int? = nil
    var marbeteExpirationYear: Int? = nil

    // MARK: - Analytics Tracking
    var usedOdometerOCR = false
    var usedVINLookup = false

    // MARK: - VIN Lookup State
    var isDecodingVIN = false
    var vinLookupError: String?
    var vinLookupSucceeded = false
    var autoFilledFields: Set<String> = []

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

    /// Year is valid when between 1900 and two years from now
    var isYearValid: Bool {
        guard let year else { return false }
        return Vehicle.isPlausibleModelYear(year)
    }

    /// Whether the vehicle is identified well enough to be useful. Year is
    /// deliberately not required: it is nice to have, but nothing in the app
    /// breaks without it, and a required field the user cannot answer from the
    /// driveway is a dead end.
    var hasIdentity: Bool {
        !make.trimmingCharacters(in: .whitespaces).isEmpty &&
        !model.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// Why this cannot be saved yet, phrased as the next thing to do. Nil means
    /// it can be saved.
    ///
    /// THE ODOMETER IS FIRST AND REQUIRED. The wizard's second step was
    /// unconditionally valid, so `currentMileage ?? 0` created vehicles at zero
    /// miles — and every mileage-based reminder computed from that is fiction.
    /// No VIN lookup can supply it, which is exactly why it cannot be optional.
    var blockingReason: String? {
        if currentMileage == nil {
            return L10n.vehicleOdometerRequired
        }
        if !hasIdentity {
            return L10n.vehicleIdentityRequired
        }
        if year != nil, !isYearValid {
            return L10n.vehicleYearOutOfRange
        }
        return nil
    }

    /// Whether anything has been entered — what Cancel would throw away.
    var isDirty: Bool {
        let texts = [name, make, model, vin, licensePlate, tireSize, oilType, notes]
        return texts.contains { !$0.isEmpty }
            || year != nil
            || currentMileage != nil
            || marbeteExpirationMonth != nil
            || marbeteExpirationYear != nil
    }

    /// VIN is valid when it's 17 alphanumeric characters (excluding I, O, Q)
    var isVINValid: Bool {
        Vehicle.isValidVIN(vin)
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

    /// Clear auto-fill feedback state
    func clearAutoFillFeedback() {
        vinLookupSucceeded = false
        autoFilledFields = []
    }
}
