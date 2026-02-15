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
    @State private var licensePlate: String
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
    @State private var vinOCROriginal: String?

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
        _licensePlate = State(initialValue: vehicle.licensePlate ?? "")
        _tireSize = State(initialValue: vehicle.tireSize ?? "")
        _oilType = State(initialValue: vehicle.oilType ?? "")
        _notes = State(initialValue: vehicle.notes ?? "")
        _marbeteExpirationMonth = State(initialValue: vehicle.marbeteExpirationMonth)
        _marbeteExpirationYear = State(initialValue: vehicle.marbeteExpirationYear)
    }

    private var isFormValid: Bool {
        !make.isEmpty && !model.isEmpty && year != nil
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
                        EditVehicleOdometerSection(
                            currentMileage: $currentMileage,
                            showOdometerCamera: $showOdometerCamera,
                            isProcessingOdometerOCR: $isProcessingOdometerOCR,
                            odometerOCRError: $odometerOCRError,
                            isCameraAvailable: isCameraAvailable
                        )

                        // VIN Section
                        EditVehicleVINSection(
                            vin: $vin,
                            licensePlate: $licensePlate,
                            make: $make,
                            model: $model,
                            year: $year,
                            isDecodingVIN: $isDecodingVIN,
                            vinLookupError: $vinLookupError,
                            showVINCamera: $showVINCamera,
                            isProcessingVINOCR: $isProcessingVINOCR,
                            vinOCRError: $vinOCRError,
                            vinOCROriginal: $vinOCROriginal,
                            isCameraAvailable: isCameraAvailable
                        )

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
            .trackScreen(.editVehicle)
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

    // MARK: - VIN OCR

    private func processVINOCR(image: UIImage) {
        AnalyticsService.shared.capture(.ocrAttempted(ocrType: .vin))
        isProcessingVINOCR = true
        vinOCRError = nil

        Task {
            do {
                let result = try await VINOCRService.shared.recognizeVIN(from: image)

                await MainActor.run {
                    isProcessingVINOCR = false
                    vin = result.vin
                    vinOCROriginal = result.vin
                    AnalyticsService.shared.capture(.ocrSucceeded(ocrType: .vin))
                }
            } catch {
                await MainActor.run {
                    isProcessingVINOCR = false
                    vinOCRError = error.localizedDescription
                    AnalyticsService.shared.capture(.ocrFailed(ocrType: .vin))
                }
            }
        }
    }

    // MARK: - Odometer OCR

    private func processOdometerOCR(image: UIImage) {
        AnalyticsService.shared.capture(.ocrAttempted(ocrType: .odometer))
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
                    AnalyticsService.shared.capture(.ocrSucceeded(ocrType: .odometer))
                }
            } catch {
                await MainActor.run {
                    isProcessingOdometerOCR = false
                    odometerOCRError = error.localizedDescription
                    AnalyticsService.shared.capture(.ocrFailed(ocrType: .odometer))
                }
            }
        }
    }

    // MARK: - Save

    private func saveChanges() {
        HapticService.shared.success()
        // Analytics: track VIN OCR confirmation at save time (VIN has no separate confirmation dialog)
        if let vinOCROriginal {
            AnalyticsService.shared.capture(.ocrConfirmed(
                ocrType: .vin,
                valueEdited: vin != vinOCROriginal
            ))
        }

        AnalyticsService.shared.capture(.vehicleEdited)
        vehicle.name = name
        vehicle.make = make
        vehicle.model = model
        vehicle.year = year ?? vehicle.year
        vehicle.currentMileage = currentMileage ?? vehicle.currentMileage
        vehicle.vin = vin.isEmpty ? nil : vin
        vehicle.licensePlate = licensePlate.isEmpty ? nil : licensePlate
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
        ToastService.shared.show(L10n.toastVehicleUpdated, icon: "checkmark", style: .success)
        dismiss()
    }

    private func deleteVehicle() {
        HapticService.shared.warning()
        AnalyticsService.shared.capture(.vehicleDeleted)
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
