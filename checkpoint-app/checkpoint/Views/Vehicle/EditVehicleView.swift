//
//  EditVehicleView.swift
//  checkpoint
//
//  Form to edit existing vehicles with delete option and instrument cluster aesthetic
//

import SwiftUI
import SwiftData

struct EditVehicleView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var services: [Service]

    @Bindable var vehicle: Vehicle

    @State private var showDeleteConfirmation = false

    // Form state (initialize from vehicle)
    @State private var name: String
    @State private var make: String
    @State private var model: String
    @State private var year: Int?
    @State private var currentMileage: Int?
    @State private var vin: String
    @State private var tireSize: String
    @State private var oilType: String
    @State private var notes: String

    // VIN lookup state
    @State private var isDecodingVIN = false
    @State private var vinLookupError: String?

    // VIN scan state
    @State private var showVINCamera = false
    @State private var isProcessingVINOCR = false
    @State private var vinOCRError: String?

    // Odometer scan state
    @State private var showOdometerCamera = false
    @State private var showOCRConfirmation = false
    @State private var ocrResult: OdometerOCRService.OCRResult?
    @State private var ocrDebugImage: UIImage?
    @State private var isProcessingOdometerOCR = false
    @State private var odometerOCRError: String?

    // Marbete state
    @State private var marbeteExpirationMonth: Int?
    @State private var marbeteExpirationYear: Int?

    init(vehicle: Vehicle) {
        self.vehicle = vehicle
        _name = State(initialValue: vehicle.name)
        _make = State(initialValue: vehicle.make)
        _model = State(initialValue: vehicle.model)
        _year = State(initialValue: vehicle.year)
        _currentMileage = State(initialValue: vehicle.currentMileage)
        _vin = State(initialValue: vehicle.vin ?? "")
        _tireSize = State(initialValue: vehicle.tireSize ?? "")
        _oilType = State(initialValue: vehicle.oilType ?? "")
        _notes = State(initialValue: vehicle.notes ?? "")
        _marbeteExpirationMonth = State(initialValue: vehicle.marbeteExpirationMonth)
        _marbeteExpirationYear = State(initialValue: vehicle.marbeteExpirationYear)
    }

    private var isFormValid: Bool {
        !make.isEmpty && !model.isEmpty && year != nil
    }

    private var isVINValid: Bool {
        let trimmed = vin.trimmingCharacters(in: .whitespaces)
        guard trimmed.count == 17 else { return false }
        let forbidden = CharacterSet(charactersIn: "IOQioq")
        return trimmed.unicodeScalars.allSatisfy { !forbidden.contains($0) && CharacterSet.alphanumerics.contains($0) }
    }

    /// Check if camera is available (requires physical device)
    private var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphericBackground()

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Vehicle Details Section
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            InstrumentSectionHeader(title: "Vehicle Details")

                            VStack(spacing: Spacing.md) {
                                InstrumentTextField(
                                    label: "Nickname",
                                    text: $name,
                                    placeholder: "Optional"
                                )

                                InstrumentTextField(
                                    label: "Make",
                                    text: $make,
                                    placeholder: "Toyota, Honda, Ford...",
                                    isRequired: true
                                )

                                InstrumentTextField(
                                    label: "Model",
                                    text: $model,
                                    placeholder: "Camry, Civic, F-150...",
                                    isRequired: true
                                )

                                InstrumentNumberField(
                                    label: "Year",
                                    value: $year,
                                    placeholder: "2024",
                                    isRequired: true
                                )
                            }
                        }

                        // Odometer Section
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            InstrumentSectionHeader(title: "Odometer")

                            InstrumentNumberField(
                                label: "Current Mileage",
                                value: $currentMileage,
                                placeholder: "0",
                                suffix: "mi",
                                showCameraButton: isCameraAvailable,
                                onCameraTap: {
                                    odometerOCRError = nil
                                    showOdometerCamera = true
                                }
                            )

                            // Odometer OCR processing indicator
                            if isProcessingOdometerOCR {
                                OCRProcessingIndicator(text: "Scanning odometer...")
                            }

                            // Odometer OCR error
                            if let error = odometerOCRError {
                                ErrorMessageRow(message: error) {
                                    odometerOCRError = nil
                                }
                            }
                        }

                        // VIN Section
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            InstrumentSectionHeader(title: "Identification")

                            VStack(alignment: .leading, spacing: 4) {
                                // VIN input with camera button
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("VIN")
                                        .font(.instrumentLabel)
                                        .foregroundStyle(Theme.textTertiary)
                                        .tracking(1.5)
                                        .textCase(.uppercase)

                                    HStack(spacing: 0) {
                                        TextField("Optional", text: $vin)
                                            .font(.instrumentBody)
                                            .foregroundStyle(Theme.textPrimary)
                                            .textInputAutocapitalization(.characters)
                                            .autocorrectionDisabled()
                                            .padding(16)
                                            .background(Theme.surfaceInstrument)
                                            .onChange(of: vin) {
                                                vinLookupError = nil
                                            }

                                        // Camera scan button
                                        if isCameraAvailable {
                                            Button {
                                                vinOCRError = nil
                                                showVINCamera = true
                                            } label: {
                                                Image(systemName: "camera.fill")
                                                    .font(.system(size: 18, weight: .medium))
                                                    .foregroundStyle(Theme.accent)
                                                    .frame(width: 52, height: 52)
                                                    .background(Theme.surfaceInstrument)
                                            }
                                            .overlay(
                                                Rectangle()
                                                    .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
                                            )
                                        }
                                    }
                                    .overlay(
                                        Rectangle()
                                            .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
                                    )
                                }

                                Text("17-character Vehicle Identification Number")
                                    .font(.caption)
                                    .foregroundStyle(Theme.textTertiary)
                                    .padding(.leading, 4)

                                // VIN OCR processing indicator
                                if isProcessingVINOCR {
                                    OCRProcessingIndicator(text: "Scanning VIN...")
                                }

                                // VIN OCR error
                                if let error = vinOCRError {
                                    ErrorMessageRow(message: error) {
                                        vinOCRError = nil
                                    }
                                }

                                // Look Up VIN button
                                if isVINValid {
                                    Button {
                                        lookUpVIN()
                                    } label: {
                                        HStack(spacing: Spacing.sm) {
                                            if isDecodingVIN {
                                                ProgressView()
                                                    .tint(Theme.surfaceInstrument)
                                            }
                                            Text(isDecodingVIN ? "Looking Up..." : "Look Up VIN")
                                        }
                                    }
                                    .buttonStyle(.secondary)
                                    .disabled(isDecodingVIN)
                                    .padding(.top, Spacing.xs)
                                }

                                // VIN lookup error
                                if let error = vinLookupError {
                                    ErrorMessageRow(message: error) {
                                        vinLookupError = nil
                                    }
                                }
                            }
                        }

                        // Specifications Section
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            InstrumentSectionHeader(title: "Specifications")

                            VStack(spacing: Spacing.md) {
                                InstrumentTextField(
                                    label: "Tire Size",
                                    text: $tireSize,
                                    placeholder: "225/45R17 (Optional)"
                                )

                                InstrumentTextField(
                                    label: "Oil Type",
                                    text: $oilType,
                                    placeholder: "0W-20 Synthetic (Optional)"
                                )
                            }
                        }

                        // Marbete Section (PR vehicle registration tag)
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            InstrumentSectionHeader(title: "Marbete")

                            MarbetePicker(
                                month: $marbeteExpirationMonth,
                                year: $marbeteExpirationYear
                            )

                            Text("Puerto Rico vehicle registration tag expiration (optional)")
                                .font(.caption)
                                .foregroundStyle(Theme.textTertiary)
                                .padding(.leading, 4)
                        }

                        // Notes Section
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            InstrumentSectionHeader(title: "Notes")

                            InstrumentTextEditor(
                                label: "Notes",
                                text: $notes,
                                placeholder: "Vehicle quirks, history, reminders..."
                            )
                        }

                        // Delete button
                        Button {
                            showDeleteConfirmation = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Vehicle")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.statusOverdue)
                            .frame(maxWidth: .infinity)
                            .frame(height: Theme.buttonHeight)
                            .background(Theme.statusOverdue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: Theme.buttonCornerRadius, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.buttonCornerRadius, style: .continuous)
                                    .strokeBorder(Theme.statusOverdue.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                    .padding(Spacing.screenHorizontal)
                    .padding(.bottom, Spacing.xxl)
                }
            }
            .navigationTitle("Edit Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.surfaceInstrument, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .toolbarButtonStyle()
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveChanges() }
                        .toolbarButtonStyle(isDisabled: !isFormValid)
                        .disabled(!isFormValid)
                }
            }
            .confirmationDialog(
                "Delete Vehicle?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) { deleteVehicle() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will also delete all services for this vehicle. This action cannot be undone.")
            }
            .fullScreenCover(isPresented: $showVINCamera) {
                OdometerCameraSheet(
                    onImageCaptured: { image in
                        processVINOCR(image: image)
                    },
                    guideText: "ALIGN VIN HERE",
                    viewfinderAspectRatio: 5.0
                )
            }
            .fullScreenCover(isPresented: $showOdometerCamera) {
                OdometerCameraSheet { image in
                    processOdometerOCR(image: image)
                }
            }
            .sheet(isPresented: $showOCRConfirmation) {
                if let result = ocrResult {
                    OCRConfirmationView(
                        extractedMileage: result.mileage,
                        confidence: result.confidence,
                        onConfirm: { mileage in
                            currentMileage = mileage
                        },
                        currentMileage: currentMileage ?? 0,
                        detectedUnit: result.detectedUnit,
                        rawText: result.rawText,
                        debugImage: ocrDebugImage
                    )
                    .presentationDetents([.medium])
                }
            }
        }
    }

    // MARK: - VIN Lookup

    private func lookUpVIN() {
        isDecodingVIN = true
        vinLookupError = nil

        Task {
            do {
                let result = try await NHTSAService.shared.decodeVIN(vin)

                await MainActor.run {
                    isDecodingVIN = false
                    // Auto-fill only empty fields
                    if make.isEmpty { make = result.make }
                    if model.isEmpty { model = result.model }
                    if year == nil { year = result.modelYear }
                }
            } catch {
                await MainActor.run {
                    isDecodingVIN = false
                    vinLookupError = error.localizedDescription
                }
            }
        }
    }

    // MARK: - VIN OCR

    private func processVINOCR(image: UIImage) {
        isProcessingVINOCR = true
        vinOCRError = nil

        Task {
            do {
                let result = try await VINOCRService.shared.recognizeVIN(from: image)

                await MainActor.run {
                    isProcessingVINOCR = false
                    vin = result.vin
                }
            } catch {
                await MainActor.run {
                    isProcessingVINOCR = false
                    vinOCRError = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Odometer OCR

    private func processOdometerOCR(image: UIImage) {
        isProcessingOdometerOCR = true
        odometerOCRError = nil
        ocrDebugImage = image

        Task {
            do {
                let result = try await OdometerOCRService.shared.recognizeMileage(
                    from: image,
                    currentMileage: currentMileage
                )

                await MainActor.run {
                    isProcessingOdometerOCR = false
                    ocrResult = result
                    showOCRConfirmation = true
                }
            } catch {
                await MainActor.run {
                    isProcessingOdometerOCR = false
                    odometerOCRError = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Save

    private func saveChanges() {
        vehicle.name = name
        vehicle.make = make
        vehicle.model = model
        vehicle.year = year ?? vehicle.year
        vehicle.currentMileage = currentMileage ?? vehicle.currentMileage
        vehicle.vin = vin.isEmpty ? nil : vin
        vehicle.tireSize = tireSize.isEmpty ? nil : tireSize
        vehicle.oilType = oilType.isEmpty ? nil : oilType
        vehicle.notes = notes.isEmpty ? nil : notes

        // Update marbete
        let oldHasMarbete = vehicle.hasMarbeteExpiration
        vehicle.marbeteExpirationMonth = marbeteExpirationMonth
        vehicle.marbeteExpirationYear = marbeteExpirationYear

        // Schedule/cancel marbete notifications
        if vehicle.hasMarbeteExpiration {
            NotificationService.shared.scheduleMarbeteNotifications(for: vehicle)
        } else if oldHasMarbete {
            NotificationService.shared.cancelMarbeteNotifications(for: vehicle)
        }

        updateAppIcon()
        updateWidgetData()
        dismiss()
    }

    private func deleteVehicle() {
        modelContext.delete(vehicle)
        updateAppIcon()
        WidgetDataService.shared.clearWidgetData()
        dismiss()
    }

    // MARK: - App Icon

    private func updateAppIcon() {
        AppIconService.shared.updateIcon(for: vehicle, services: services)
    }

    // MARK: - Widget Data

    private func updateWidgetData() {
        WidgetDataService.shared.updateWidget(for: vehicle)
    }
}

#Preview {
    @Previewable @State var vehicle = Vehicle(
        name: "Daily Driver",
        make: "Toyota",
        model: "Camry",
        year: 2022,
        currentMileage: 32500,
        vin: "1HGBH41JXMN109186",
        tireSize: "225/45R17",
        oilType: "0W-20 Synthetic"
    )

    EditVehicleView(vehicle: vehicle)
        .modelContainer(for: Vehicle.self, inMemory: true)
}
