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
    let onUpdate: (Int) -> Void

    @State private var showMileageSheet = false

    private var formattedMileage: String {
        Formatters.mileageNumber(vehicle.currentMileage)
    }

    private var unitAbbreviation: String {
        DistanceSettings.shared.unit.uppercaseAbbreviation
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            InstrumentSectionHeader(title: "Odometer")

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

                    Text(vehicle.mileageUpdateDescription)
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.textTertiary)
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
            .padding(Spacing.md)
            .background(Theme.surfaceInstrument)
            .overlay(
                Rectangle()
                    .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
            )
        }
        .sheet(isPresented: $showMileageSheet) {
            MileageUpdateSheet(
                currentMileage: vehicle.currentMileage,
                onSave: { newMileage in
                    onUpdate(newMileage)
                }
            )
            .presentationDetents([.height(340)])
        }
    }
}

// MARK: - Mileage Update Sheet

struct MileageUpdateSheet: View {
    @Environment(\.dismiss) private var dismiss

    let currentMileage: Int
    let onSave: (Int) -> Void

    @State private var newMileage: Int?
    @State private var showCamera = false
    @State private var showOCRConfirmation = false
    @State private var ocrResult: OdometerOCRService.OCRResult?
    @State private var isProcessingOCR = false
    @State private var ocrError: String?

    /// Check if camera is available (requires physical device)
    private var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundPrimary
                    .ignoresSafeArea()

                VStack(spacing: Spacing.lg) {
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

                    Button("Save") {
                        if let mileage = newMileage, mileage > 0 {
                            onSave(mileage)
                            dismiss()
                        }
                    }
                    .buttonStyle(.primary)
                    .disabled(newMileage == nil || newMileage! <= 0 || isProcessingOCR)

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
                        .foregroundStyle(Theme.accent)
                }
            }
        }
        .onAppear {
            newMileage = currentMileage
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
                    currentMileage: currentMileage,
                    detectedUnit: result.detectedUnit
                )
                .presentationDetents([.medium])
            }
        }
    }

    // MARK: - Mileage Input Section

    private var mileageInputSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Label
            Text("CURRENT MILEAGE")
                .font(.instrumentLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1.5)

            // Input with camera button
            HStack(spacing: 0) {
                // Number input
                HStack(spacing: 8) {
                    TextField("\(currentMileage)", text: mileageBinding)
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

        Task {
            do {
                let result = try await OdometerOCRService.shared.recognizeMileage(from: image)

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
