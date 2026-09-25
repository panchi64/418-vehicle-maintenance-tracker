//
//  MileageUpdateSheet.swift
//  checkpoint
//
//  Mileage update sheet with manual entry and camera-based OCR.
//
//  The sheet's whole job is one number, so the field takes focus on appear and
//  Update lives in the toolbar (`formToolbar`) where it never competes with the
//  number pad. A scanned reading goes through `OCRConfirmationView`, whose own
//  toolbar confirm commits it.
//

import SwiftUI
import UIKit

struct MileageUpdateSheet: View {
    @Environment(\.dismiss) private var dismiss

    let vehicle: Vehicle
    let prefilledMileage: Int?
    let onSave: (Int) -> Void

    init(vehicle: Vehicle, prefilledMileage: Int? = nil, onSave: @escaping (Int) -> Void) {
        self.vehicle = vehicle
        self.prefilledMileage = prefilledMileage
        self.onSave = onSave
    }

    @State private var newMileage: Int?
    @State private var showCamera = false
    @State private var showOCRConfirmation = false
    @State private var ocrResult: OdometerOCRService.OCRResult?
    @State private var ocrDebugImage: UIImage?
    @State private var isProcessingOCR = false
    @State private var ocrError: String?
    @State private var mileageWarning: String?
    @State private var showBlocker = false

    /// Delay before the "below previous reading" warning appears while typing.
    /// Why: the comparison fires per keystroke, so "32500" would flash the
    /// warning at "3" before the user finishes the number.
    private static let lowerWarningDebounce: Duration = .milliseconds(600)

    /// Check if camera is available (requires physical device)
    private var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    private var hasReading: Bool { (newMileage ?? 0) > 0 }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        MileageContextRow(vehicle: vehicle)

                        mileageInputSection

                        // F2: at the field that resolves it.
                        if showBlocker, !hasReading {
                            FormAdvisory.blocking(L10n.formEnterReading)
                        }

                        if let mileageWarning {
                            FormAdvisory.caution(mileageWarning)
                        }

                        if let error = ocrError {
                            FormAdvisory.caution(error) { ocrError = nil }
                        }

                        if isProcessingOCR {
                            processingView
                        }
                    }
                    .padding(Spacing.screenHorizontal)
                    .padding(.top, Spacing.lg)
                }
            }
            .keyboardDismissToolbar()
            .formToolbar(
                title: L10n.mileageUpdateTitle,
                subtitle: vehicle.displayName,
                saveTitle: L10n.commonUpdate,
                canSave: hasReading && !isProcessingOCR,
                isDirty: newMileage != nil && newMileage != prefilledMileage,
                onSave: { commit(newMileage ?? 0) },
                onBlocked: { showBlocker = true }
            )
        }
        .onAppear {
            // A Siri reading prefills; otherwise the field starts empty so the
            // user enters the actual reading rather than accepting a guess.
            if let prefilled = prefilledMileage {
                newMileage = prefilled
            }
        }
        .task(id: newMileage) {
            let warning = ServiceFormValidation.mileageWarning(
                entered: newMileage,
                vehicleCurrentMileage: vehicle.currentMileage,
                maxLoggedMileage: vehicle.currentMileage,
                performedDate: .now
            )
            guard warning != nil else {
                mileageWarning = nil
                return
            }
            mileageWarning = nil
            do {
                try await Task.sleep(for: Self.lowerWarningDebounce)
                mileageWarning = warning
            } catch {
                // Cancelled because the user typed another digit — keep it hidden.
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            OdometerCameraSheet { image in
                processOCR(image: image)
            }
        }
        .sheet(isPresented: $showOCRConfirmation) {
            if let result = ocrResult {
                OCRConfirmationView(
                    extractedMileage: result.mileage,
                    confidence: result.confidence,
                    onConfirm: commit,
                    currentMileage: vehicle.currentMileage,
                    detectedUnit: result.detectedUnit,
                    rawText: result.rawText,
                    debugImage: ocrDebugImage
                )
                .presentationDetents([.medium])
            }
        }
    }

    // MARK: - Mileage Input

    private var mileageInputSection: some View {
        InstrumentNumberField(
            label: L10n.mileageEnterLabel,
            value: $newMileage,
            placeholder: vehicle.currentMileage > 0 ? Formatters.mileageNumber(vehicle.currentMileage) : L10n.mileageEnterPlaceholder,
            suffix: DistanceSettings.shared.unit.abbreviation,
            showCameraButton: isCameraAvailable,
            onCameraTap: isCameraAvailable ? {
                ocrError = nil
                showCamera = true
            } : nil,
            autoFocus: true
        )
    }

    // MARK: - Processing View

    private var processingView: some View {
        HStack(spacing: Spacing.sm) {
            ProgressView()
                .tint(Theme.accent)

            Text(L10n.addVehicleScanningOdometer)
                .textCase(.uppercase)
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textSecondary)
                .tracking(1)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity)
        .background(Theme.surfaceInstrument)
        .brutalistBorder()
    }

    // MARK: - Commit

    private func commit(_ mileage: Int) {
        guard mileage > 0 else { return }
        HapticService.shared.success()
        onSave(mileage)
        dismiss()
    }

    // MARK: - OCR Processing

    private func processOCR(image: UIImage) {
        isProcessingOCR = true
        ocrError = nil
        ocrDebugImage = image

        Task {
            do {
                let result = try await OdometerOCRService.shared.recognizeMileage(
                    from: image,
                    currentMileage: vehicle.currentMileage
                )

                isProcessingOCR = false
                ocrResult = result
                showOCRConfirmation = true
            } catch {
                isProcessingOCR = false
                ocrError = error.localizedDescription
            }
        }
    }
}
