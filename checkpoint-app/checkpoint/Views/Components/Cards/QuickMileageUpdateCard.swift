//
//  QuickMileageUpdateCard.swift
//  checkpoint
//
//  Large odometer display with UPDATE button and last updated tracking
//  Includes camera-based OCR for mileage capture
//

import SwiftUI
import UIKit

struct QuickMileageUpdateCard: View {
    let vehicle: Vehicle
    var mileageTrackedServiceCount: Int = 0
    let onUpdate: (Int) -> Void

    @State private var showMileageSheet = false

    /// Whether to show estimates (from settings)
    private var showEstimates: Bool {
        MileageEstimateSettings.shared.showEstimates
    }

    /// Whether we're displaying an estimated value
    private var isShowingEstimate: Bool {
        showEstimates && vehicle.isUsingEstimatedMileage
    }

    /// Display mileage: use estimated if available and enabled, otherwise actual
    private var displayMileage: Int {
        isShowingEstimate ? (vehicle.estimatedMileage ?? vehicle.currentMileage) : vehicle.currentMileage
    }

    private var formattedMileage: String {
        let unit = DistanceSettings.shared.unit
        let displayValue = unit.fromMiles(displayMileage)
        let number = Formatters.mileageNumber(displayValue)

        // Add tilda prefix for estimates
        if isShowingEstimate {
            return "~" + number
        }
        return number
    }

    private var unitAbbreviation: String {
        DistanceSettings.shared.unit.uppercaseAbbreviation
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            InstrumentSectionHeader(title: "Odometer")

            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(alignment: .center) {
                    // Mileage display
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(formattedMileage)
                                .font(.brutalistTitle)
                                .foregroundStyle(Theme.accent)

                            Text(unitAbbreviation)
                                .font(.brutalistLabel)
                                .foregroundStyle(Theme.textTertiary)
                                .tracking(1)
                        }

                        // Inline confidence indicator when showing estimate
                        if isShowingEstimate, let confidence = vehicle.paceConfidence {
                            HStack(spacing: Spacing.xs) {
                                CompactConfidenceBar(level: confidence)
                                Text(confidence.label)
                                    .font(.brutalistLabel)
                                    .foregroundStyle(confidence.color)
                                    .tracking(1)
                            }
                        }

                        Text(vehicle.mileageUpdateDescription)
                            .font(.brutalistSecondary)
                            .foregroundStyle(Theme.textTertiary)

                        if mileageTrackedServiceCount > 0 {
                            Text("KEEPS \(mileageTrackedServiceCount) SERVICE REMINDERS ACCURATE")
                                .font(.brutalistLabel)
                                .foregroundStyle(Theme.textTertiary)
                                .tracking(1)
                        }
                    }

                    Spacer()

                    // Update button
                    Button {
                        showMileageSheet = true
                    } label: {
                        Text("UPDATE")
                            .font(.brutalistLabel)
                            .foregroundStyle(Theme.surfaceInstrument)
                            .tracking(1.5)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .background(Theme.accent)
                    }
                }
            }
            .padding(Spacing.md)
            .background(Theme.surfaceInstrument)
            .overlay(
                Rectangle()
                    .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
            )
        }
        .sheet(isPresented: $showMileageSheet) {
            MileageUpdateSheet(
                vehicle: vehicle,
                onSave: { newMileage in
                    onUpdate(newMileage)
                }
            )
            .presentationDetents([.height(450)])
        }
    }
}

// MARK: - Mileage Update Sheet

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
            .navigationTitle("Update Mileage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .toolbarButtonStyle()
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let mileage = newMileage, mileage > 0 {
                            HapticService.shared.success()
                            onSave(mileage)
                            dismiss()
                        }
                    }
                    .toolbarButtonStyle(isDisabled: (newMileage ?? 0) <= 0 || isProcessingOCR)
                    .disabled((newMileage ?? 0) <= 0 || isProcessingOCR)
                }
            }
        }
        .onAppear {
            // Use prefilled mileage from Siri if available, otherwise start empty
            if let prefilled = prefilledMileage {
                newMileage = prefilled
            }
            // Otherwise leave newMileage nil so user enters actual reading
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
                    onConfirm: { mileage in
                        newMileage = mileage
                    },
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
            Text("CURRENT ESTIMATE")
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
        .overlay(
            Rectangle()
                .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
        )
    }

    private var lastConfirmedContextCard: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("LAST CONFIRMED")
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
        .overlay(
            Rectangle()
                .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
        )
    }

    private var lastConfirmedOnlyCard: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("LAST CONFIRMED")
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
        .overlay(
            Rectangle()
                .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
        )
    }

    private var noEstimateHint: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("NO ESTIMATE AVAILABLE")
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1)

            Text("Update a few more times to enable driving pace estimates")
                .font(.brutalistSecondary)
                .foregroundStyle(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(Theme.surfaceInstrument)
        .overlay(
            Rectangle()
                .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
        )
    }

    // MARK: - Mileage Input Section

    private var mileageInputSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Label
            Text("ENTER MILEAGE")
                .font(.instrumentLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1.5)

            // Input with camera button
            HStack(spacing: 0) {
                // Number input
                HStack(spacing: 8) {
                    TextField("", text: mileageBinding)
                        .font(.instrumentBody)
                        .foregroundStyle(Theme.textPrimary)
                        .keyboardType(.numberPad)

                    Text(DistanceSettings.shared.unit.abbreviation)
                        .font(.instrumentLabel)
                        .foregroundStyle(Theme.textTertiary)
                }
                .padding(16)
                .background(Theme.surfaceInstrument)

                // Camera button
                if isCameraAvailable {
                    Button {
                        ocrError = nil
                        showCamera = true
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
    }

    // MARK: - Mileage Binding

    private var mileageBinding: Binding<String> {
        Binding(
            get: {
                if let mileage = newMileage {
                    return String(mileage)
                }
                return ""
            },
            set: { newValue in
                let filtered = newValue.filter { $0.isNumber }
                newMileage = Int(filtered)
            }
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
            }
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

            Text("SCANNING ODOMETER...")
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textSecondary)
                .tracking(1)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity)
        .background(Theme.surfaceInstrument)
        .overlay(
            Rectangle()
                .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
        )
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

                await MainActor.run {
                    isProcessingOCR = false
                    ocrResult = result
                    showOCRConfirmation = true
                }
            } catch {
                await MainActor.run {
                    isProcessingOCR = false
                    ocrError = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    ZStack {
        AtmosphericBackground()

        VStack(spacing: Spacing.lg) {
            QuickMileageUpdateCard(
                vehicle: Vehicle(
                    name: "Daily Driver",
                    make: "Toyota",
                    model: "Camry",
                    year: 2022,
                    currentMileage: 32500,
                    mileageUpdatedAt: Calendar.current.date(byAdding: .day, value: -3, to: .now)
                )
            ) { newMileage in
                print("Updated to \(newMileage)")
            }

            QuickMileageUpdateCard(
                vehicle: Vehicle(
                    name: "New Car",
                    make: "Honda",
                    model: "Civic",
                    year: 2024,
                    currentMileage: 1500
                )
            ) { newMileage in
                print("Updated to \(newMileage)")
            }
        }
        .padding(Spacing.screenHorizontal)
    }
    .preferredColorScheme(.dark)
}
