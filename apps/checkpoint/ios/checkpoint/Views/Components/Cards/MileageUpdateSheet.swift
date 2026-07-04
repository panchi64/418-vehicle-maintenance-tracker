//
//  MileageUpdateSheet.swift
//  checkpoint
//
//  Mileage update sheet with manual entry and camera-based OCR
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

    /// Delay before the "below previous reading" warning appears while typing.
    /// Why: the comparison fires per keystroke, so "32500" would flash the
    /// warning at "3" before the user finishes the number.
    private static let lowerWarningDebounce: Duration = .milliseconds(600)

    /// Check if camera is available (requires physical device)
    private var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    /// Whether to show estimates (from settings)
    private var showEstimates: Bool {
        MileageEstimateSettings.shared.showEstimates
    }

    /// Whether we have an estimate to show
    private var hasEstimate: Bool {
        showEstimates && vehicle.isUsingEstimatedMileage && vehicle.estimatedMileage != nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundPrimary
                    .ignoresSafeArea()

                VStack(spacing: Spacing.lg) {
                    // Context row: estimate + last confirmed
                    contextRow

                    // Mileage input with camera button
                    mileageInputSection

                    if let mileageWarning {
                        SanityWarningRow(message: mileageWarning)
                    }

                    // OCR error message
                    if let error = ocrError {
                        ocrErrorView(error)
                    }

                    // Processing indicator
                    if isProcessingOCR {
                        processingView
                    }

                    Spacer()
                }
                .padding(Spacing.screenHorizontal)
                .padding(.top, Spacing.lg)
            }
            .numberPadDoneButton()
            .navigationTitle(L10n.mileageUpdateTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.commonCancel) { dismiss() }
                        .toolbarButtonStyle()
                }
            }
            .safeAreaInset(edge: .bottom) {
                FormActionBar(
                    primaryTitle: L10n.commonUpdate,
                    isPrimaryEnabled: (newMileage ?? 0) > 0 && !isProcessingOCR,
                    onPrimary: { commit(newMileage ?? 0) }
                )
            }
        }
        .onAppear {
            // Use prefilled mileage from Siri if available, otherwise start empty
            if let prefilled = prefilledMileage {
                newMileage = prefilled
            }
            // Otherwise leave newMileage nil so user enters actual reading
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
                // Task cancelled because the user typed another digit — keep the warning hidden.
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

    // MARK: - Context Row

    @ViewBuilder
    private var contextRow: some View {
        if hasEstimate {
            // Show both estimate and last confirmed
            HStack(spacing: Spacing.sm) {
                // Current estimate card
                estimateContextCard

                // Last confirmed card
                lastConfirmedContextCard
            }
        } else if vehicle.mileageUpdatedAt != nil {
            // No estimate, just show last confirmed
            lastConfirmedOnlyCard
        } else {
            // No estimate and never updated - show hint
            noEstimateHint
        }
    }

    private var estimateContextCard: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(L10n.mileageCurrentEstimate)
                .textCase(.uppercase)
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1)

            if let estimate = vehicle.estimatedMileage {
                Text(Formatters.estimatedMileage(estimate) + " " + DistanceSettings.shared.unit.uppercaseAbbreviation)
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.accent)
            }

            if let confidence = vehicle.paceConfidence {
                HStack(spacing: Spacing.xs) {
                    CompactConfidenceBar(level: confidence)
                    Text(confidence.label)
                        .font(.brutalistLabel)
                        .foregroundStyle(confidence.color)
                        .tracking(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(Theme.surfaceInstrument)
        .brutalistBorder()
    }

    private var lastConfirmedContextCard: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(L10n.mileageLastConfirmed)
                .textCase(.uppercase)
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1)

            Text(Formatters.mileageNumber(vehicle.currentMileage) + " " + DistanceSettings.shared.unit.uppercaseAbbreviation)
                .font(.brutalistBody)
                .foregroundStyle(Theme.textPrimary)

            Text(vehicle.mileageUpdateDescription)
                .font(.brutalistSecondary)
                .foregroundStyle(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(Theme.surfaceInstrument)
        .brutalistBorder()
    }

    private var lastConfirmedOnlyCard: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(L10n.mileageLastConfirmed)
                .textCase(.uppercase)
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(Formatters.mileageNumber(vehicle.currentMileage))
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.textPrimary)

                Text(DistanceSettings.shared.unit.uppercaseAbbreviation)
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.textTertiary)
                    .tracking(1)
            }

            Text(vehicle.mileageUpdateDescription)
                .font(.brutalistSecondary)
                .foregroundStyle(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(Theme.surfaceInstrument)
        .brutalistBorder()
    }

    private var noEstimateHint: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(L10n.mileageNoEstimate)
                .textCase(.uppercase)
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1)

            Text(L10n.mileageNoEstimateHint)
                .font(.brutalistSecondary)
                .foregroundStyle(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(Theme.surfaceInstrument)
        .brutalistBorder()
    }

    // MARK: - Mileage Input Section

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
            } : nil
        )
    }

    // MARK: - OCR Error View

    private func ocrErrorView(_ error: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.statusOverdue)

            Text(error.uppercased())
                .font(.brutalistLabel)
                .foregroundStyle(Theme.statusOverdue)
                .tracking(1)

            Spacer()

            Button {
                ocrError = nil
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.textTertiary)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel(L10n.mileageDismissError)
        }
        .padding(Spacing.md)
        .background(Theme.statusOverdue.opacity(0.1))
        .overlay(
            Rectangle()
                .strokeBorder(Theme.statusOverdue.opacity(0.5), lineWidth: Theme.borderWidth)
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
