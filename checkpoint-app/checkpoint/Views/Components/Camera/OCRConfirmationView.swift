//
//  OCRConfirmationView.swift
//  checkpoint
//
//  Confirmation dialog for OCR-extracted mileage
//  Shows low-confidence warning when needed
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

    /// Raw text recognized by Vision (for debugging)
    let rawText: String

    /// Cropped image sent to Vision (for debugging)
    let debugImage: UIImage?

    @State private var editedMileage: Int?
    @State private var sourceUnit: DistanceUnit = .miles

    private var displayMileage: Int {
        editedMileage ?? extractedMileage
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

    /// Binding for the mileage text field (limited to 7 digits)
    private var mileageTextBinding: Binding<String> {
        Binding(
            get: { String(editedMileage ?? extractedMileage) },
            set: { newValue in
                let filtered = String(newValue.filter { $0.isNumber }.prefix(7))
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
        detectedUnit: DistanceUnit? = nil,
        rawText: String = "",
        debugImage: UIImage? = nil
    ) {
        self.extractedMileage = extractedMileage
        self.confidence = confidence
        self.onConfirm = onConfirm
        self.currentMileage = currentMileage
        self.detectedUnit = detectedUnit
        self.rawText = rawText
        self.debugImage = debugImage
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundPrimary
                    .ignoresSafeArea()

                VStack(spacing: Spacing.lg) {
                    // Extracted mileage display (directly editable)
                    mileageDisplay

                    // Warning for low confidence only (no confidence bar)
                    if confidenceLevel == .low {
                        lowConfidenceWarning
                    }

                    // Debug: raw OCR text and cropped image preview
                    // Uncomment to diagnose camera/OCR issues:
                    // #if DEBUG
                    // rawTextDebugView
                    // #endif

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
                        .font(.brutalistBody)
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

    // MARK: - Debug: Raw OCR Text

    #if DEBUG
    private var rawTextDebugView: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("RAW OCR TEXT")
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1.5)

            HStack {
                Text(rawText.isEmpty ? "(empty)" : rawText)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    UIPasteboard.general.string = rawText
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.accent)
                }
            }

            if let img = debugImage {
                Text("CROPPED IMAGE")
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.textTertiary)
                    .tracking(1.5)
                    .padding(.top, Spacing.xs)

                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 120)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(Spacing.md)
        .background(Theme.surfaceInstrument)
        .overlay(
            Rectangle()
                .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
        )
    }
    #endif

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
