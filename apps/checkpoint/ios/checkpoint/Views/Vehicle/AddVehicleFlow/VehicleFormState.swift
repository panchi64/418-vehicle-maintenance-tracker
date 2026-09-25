//
//  VehicleFormState.swift
//  checkpoint
//
//  State for the vehicle forms — Add and Edit share it, so the two cannot
//  drift into different validation, VIN, or OCR behavior. Pure state: the
//  network lookup and the camera live in the view layer
//  (`VehicleVINLookup`, `VehicleCaptureModifier`).
//

import SwiftUI

@Observable
final class VehicleFormState {
    /// Every value the form writes to the vehicle. Compared against the
    /// baseline it was opened with to decide what Cancel would discard.
    struct Fields: Equatable {
        var name = ""
        var make = ""
        var model = ""
        var year: Int?
        var currentMileage: Int?
        var vin = ""
        var licensePlate = ""
        var tireSize = ""
        var oilType = ""
        var notes = ""
        var marbeteExpirationMonth: Int?
        var marbeteExpirationYear: Int?
    }

    /// What the last VIN lookup did to the form. Stays until the VIN changes:
    /// the confirmation is information the user may want to reread, not a
    /// flash that dismisses itself on a timer.
    enum VINLookupOutcome: Equatable {
        /// These fields were empty and the lookup filled them.
        case filled(Set<Field>)
        /// The VIN decoded, but every field it could fill already had a value.
        case nothingNew
    }

    enum Field: Hashable {
        case make, model, year
    }

    var fields: Fields
    private let baseline: Fields

    // MARK: - Field accessors

    var name: String {
        get { fields.name }
        set { fields.name = newValue }
    }
    var make: String {
        get { fields.make }
        set { fields.make = newValue }
    }
    var model: String {
        get { fields.model }
        set { fields.model = newValue }
    }
    var year: Int? {
        get { fields.year }
        set { fields.year = newValue }
    }
    var currentMileage: Int? {
        get { fields.currentMileage }
        set { fields.currentMileage = newValue }
    }
    var vin: String {
        get { fields.vin }
        set { fields.vin = newValue }
    }
    var licensePlate: String {
        get { fields.licensePlate }
        set { fields.licensePlate = newValue }
    }
    var tireSize: String {
        get { fields.tireSize }
        set { fields.tireSize = newValue }
    }
    var oilType: String {
        get { fields.oilType }
        set { fields.oilType = newValue }
    }
    var notes: String {
        get { fields.notes }
        set { fields.notes = newValue }
    }
    var marbeteExpirationMonth: Int? {
        get { fields.marbeteExpirationMonth }
        set { fields.marbeteExpirationMonth = newValue }
    }
    var marbeteExpirationYear: Int? {
        get { fields.marbeteExpirationYear }
        set { fields.marbeteExpirationYear = newValue }
    }

    // MARK: - Analytics Tracking

    var usedOdometerOCR = false
    var usedVINLookup = false

    // MARK: - VIN Lookup State

    var isDecodingVIN = false
    var vinLookupError: String?
    var vinLookupOutcome: VINLookupOutcome?
    /// The VIN the form last decoded (or opened with), so auto-decode runs
    /// once per new VIN rather than on every appearance.
    private(set) var lastDecodedVIN: String?

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

    // MARK: - Init

    /// A blank form (Add Vehicle).
    init() {
        fields = Fields()
        baseline = Fields()
    }

    /// A form opened on an existing vehicle (Edit Vehicle).
    init(vehicle: Vehicle) {
        let loaded = Fields(
            name: vehicle.name,
            make: vehicle.make,
            model: vehicle.model,
            year: vehicle.hasModelYear ? vehicle.year : nil,
            currentMileage: vehicle.currentMileage,
            vin: vehicle.vin ?? "",
            licensePlate: vehicle.licensePlate ?? "",
            tireSize: vehicle.tireSize ?? "",
            oilType: vehicle.oilType ?? "",
            notes: vehicle.notes ?? "",
            marbeteExpirationMonth: vehicle.marbeteExpirationMonth,
            marbeteExpirationYear: vehicle.marbeteExpirationYear
        )
        fields = loaded
        baseline = loaded
        // The stored VIN already produced the stored make/model/year; opening
        // the form must not look it up again.
        lastDecodedVIN = Self.normalized(loaded.vin)
    }

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

    /// Whether anything differs from what the form opened with — what Cancel
    /// would throw away.
    var isDirty: Bool {
        fields != baseline
    }

    /// VIN is valid when it's 17 alphanumeric characters (excluding I, O, Q)
    var isVINValid: Bool {
        Vehicle.isValidVIN(vin)
    }

    /// A valid VIN the form hasn't decoded yet — the auto-decode trigger.
    var shouldAutoDecodeVIN: Bool {
        isVINValid && !isDecodingVIN && Self.normalized(vin) != lastDecodedVIN
    }

    /// Check if camera is available (requires physical device)
    var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    // MARK: - VIN lookup transitions

    /// The VIN field changed: whatever the last lookup said no longer applies.
    func vinDidChange() {
        vinLookupError = nil
        vinLookupOutcome = nil
    }

    func beginVINLookup() {
        isDecodingVIN = true
        vinLookupError = nil
    }

    /// Fill only the fields the user left empty — a lookup never overwrites
    /// what they typed — and record what it did.
    func applyVINLookup(_ result: VINDecodeResult, for decodedVIN: String) {
        isDecodingVIN = false
        lastDecodedVIN = Self.normalized(decodedVIN)
        usedVINLookup = true

        var filled: Set<Field> = []
        if make.trimmingCharacters(in: .whitespaces).isEmpty, !result.make.isEmpty {
            make = result.make
            filled.insert(.make)
        }
        if model.trimmingCharacters(in: .whitespaces).isEmpty, !result.model.isEmpty {
            model = result.model
            filled.insert(.model)
        }
        if year == nil, let decodedYear = result.modelYear {
            year = decodedYear
            filled.insert(.year)
        }
        vinLookupOutcome = filled.isEmpty ? .nothingNew : .filled(filled)
    }

    func failVINLookup(_ message: String, for decodedVIN: String) {
        isDecodingVIN = false
        // Remember the failure's VIN so auto-decode doesn't retry it in a
        // loop; the manual button stays for a deliberate retry.
        lastDecodedVIN = Self.normalized(decodedVIN)
        vinLookupError = message
    }

    /// A lookup whose VIN was edited away before it returned.
    func abandonVINLookup() {
        isDecodingVIN = false
    }

    func isAutoFilled(_ field: Field) -> Bool {
        if case .filled(let fields) = vinLookupOutcome { return fields.contains(field) }
        return false
    }

    // MARK: - Actions

    /// Clear odometer OCR error
    func clearOdometerError() {
        odometerOCRError = nil
    }

    /// Clear VIN OCR error
    func clearVINOCRError() {
        vinOCRError = nil
    }

    static func normalized(_ vin: String) -> String {
        vin.trimmingCharacters(in: .whitespaces).uppercased()
    }
}
