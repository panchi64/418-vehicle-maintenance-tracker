//
//  OCRConfirmationView.swift
//  checkpoint
//
//  Confirmation dialog for OCR-extracted mileage with confidence indicator
//  Follows brutalist design: sharp corners, 2px borders, monospace typography
//

import SwiftUI

/// Confirmation view for OCR-extracted mileage
struct OCRConfirmationView: View {
    @Environment(\.dismiss) private var dismiss

    /// The extracted mileage value
    let extractedMileage: Int

    /// Confidence score from 0.0 to 1.0
    let confidence: Float

    /// Callback when user confirms the mileage (value is always in miles for storage)
    let onConfirm: (Int) -> Void

    /// Current mileage for validation
    let currentMileage: Int

    /// Detected distance unit from OCR (nil if no unit indicator found)
    let detectedUnit: DistanceUnit?

    @State private var editedMileage: Int?
    @State private var sourceUnit: DistanceUnit = .miles

    private var displayMileage: Int {
        editedMileage ?? extractedMileage
    }

    private var confidencePercentage: Int {
        Int(confidence * 100)
    }

    private var confidenceLevel: ConfidenceLevel {
        if confidence >= OdometerOCRService.highConfidenceThreshold {
            return .high
        } else if confidence >= OdometerOCRService.mediumConfidenceThreshold {
            return .medium
        } else {
            return .low
        }
    }

    /// Binding for the mileage text field
    private var mileageTextBinding: Binding<String> {
        Binding(
            get: { String(editedMileage ?? extractedMileage) },
            set: { newValue in
                let filtered = newValue.filter { $0.isNumber }
                editedMileage = Int(filtered)
            }
        )
    }

    /// Initialize with optional detected unit (defaults to nil for backward compatibility)
    init(
        extractedMileage: Int,
        confidence: Float,
        onConfirm: @escaping (Int) -> Void,
        currentMileage: Int,
        detectedUnit: DistanceUnit? = nil
    ) {
        self.extractedMileage = extractedMileage
        self.confidence = confidence
        self.onConfirm = onConfirm
        self.currentMileage = currentMileage
        self.detectedUnit = detectedUnit
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundPrimary
                    .ignoresSafeArea()

                VStack(spacing: Spacing.lg) {
                    // Extracted mileage display (directly editable)
                    mileageDisplay

                    // Confidence indicator
                    confidenceIndicator

                    // Warning for low confidence
                    if confidenceLevel == .low {
                        lowConfidenceWarning
                    }

                    Spacer()

                    // Action button (single "USE THIS" button)
                    actionButtons
                }
                .padding(Spacing.screenHorizontal)
                .padding(.top, Spacing.lg)
            }
            .navigationTitle("Extracted Mileage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.accent)
                }
            }
        }
        .onAppear {
            // Initialize sourceUnit from detected unit or user preference
            sourceUnit = detectedUnit ?? DistanceSettings.shared.unit
        }
    }

    // MARK: - Mileage Display

    private var mileageDisplay: some View {
        VStack(spacing: Spacing.sm) {
            Text("DETECTED VALUE")
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(2)

            HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                TextField("", text: mileageTextBinding)
                    .font(.brutalistHero)
                    .foregroundStyle(Theme.accent)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .fixedSize()

                // Unit toggle button
                Button {
                    sourceUnit = (sourceUnit == .miles) ? .kilometers : .miles
                } label: {
                    Text(sourceUnit.uppercaseAbbreviation)
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.accent)
                        .tracking(1)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .overlay(
                            Rectangle()
                                .strokeBorder(Theme.accent.opacity(0.5), lineWidth: 1)
                        )
                }
            }

            Text("TAP TO EDIT")
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary.opacity(0.6))
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
        .background(Theme.surfaceInstrument)
        .overlay(
            Rectangle()
                .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
        )
    }

    // MARK: - Confidence Indicator

    private var confidenceIndicator: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("CONFIDENCE")
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.textTertiary)
                    .tracking(1.5)

                Spacer()

                Text("\(confidencePercentage)%")
                    .font(.brutalistBody)
                    .foregroundStyle(confidenceLevel.color)
            }

            // Segmented bar (brutalist style - 10 rectangular segments)
            ConfidenceBar(confidence: confidence, level: confidenceLevel)
        }
        .padding(Spacing.md)
        .background(Theme.surfaceInstrument)
        .overlay(
            Rectangle()
                .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
        )
    }

    // MARK: - Low Confidence Warning

    private var lowConfidenceWarning: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.statusOverdue)

            Text("LOW CONFIDENCE - VERIFY VALUE")
                .font(.brutalistLabel)
                .foregroundStyle(Theme.statusOverdue)
                .tracking(1)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity)
        .background(Theme.statusOverdue.opacity(0.1))
        .overlay(
            Rectangle()
                .strokeBorder(Theme.statusOverdue.opacity(0.5), lineWidth: Theme.borderWidth)
        )
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        Button {
            var finalMileage = editedMileage ?? extractedMileage
            // Convert to miles if source was kilometers (internal storage is always miles)
            if sourceUnit == .kilometers {
                finalMileage = sourceUnit.toMiles(finalMileage)
            }
            onConfirm(finalMileage)
            dismiss()
        } label: {
            Text("USE THIS")
                .font(.brutalistLabel)
                .foregroundStyle(Theme.surfaceInstrument)
                .tracking(1.5)
                .frame(maxWidth: .infinity)
                .frame(height: Theme.buttonHeight)
                .background(Theme.accent)
        }
    }
}

// Note: ConfidenceLevel and ConfidenceBar are now in ConfidenceIndicator.swift

// MARK: - Preview

#Preview("High Confidence") {
    OCRConfirmationView(
        extractedMileage: 51247,
        confidence: 0.92,
        onConfirm: { mileage in
            print("Confirmed: \(mileage)")
        },
        currentMileage: 50000
    )
    .preferredColorScheme(.dark)
}

#Preview("Medium Confidence") {
    OCRConfirmationView(
        extractedMileage: 32500,
        confidence: 0.65,
        onConfirm: { mileage in
            print("Confirmed: \(mileage)")
        },
        currentMileage: 32000
    )
    .preferredColorScheme(.dark)
}

#Preview("Low Confidence") {
    OCRConfirmationView(
        extractedMileage: 12345,
        confidence: 0.35,
        onConfirm: { mileage in
            print("Confirmed: \(mileage)")
        },
        currentMileage: 12000
    )
    .preferredColorScheme(.dark)
}
