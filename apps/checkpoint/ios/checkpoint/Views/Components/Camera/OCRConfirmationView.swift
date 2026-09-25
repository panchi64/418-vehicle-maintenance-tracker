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

    @State private var mileageText: String = ""
    @State private var sourceUnit: DistanceUnit = .miles
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var heroLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: Spacing.sm))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: Spacing.sm))
    }

    private var parsedMileage: Int? {
        Int(mileageText)
    }

    private var finalMileageInMiles: Int {
        sourceUnit.toMiles(parsedMileage ?? extractedMileage)
    }

    private var isLowerThanCurrent: Bool {
        guard currentMileage > 0, parsedMileage != nil else { return false }
        return finalMileageInMiles < currentMileage
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

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Extracted mileage display (directly editable)
                        mileageDisplay

                        if parsedMileage == nil {
                            FormAdvisory.blocking(L10n.formEnterReading)
                        }

                        if confidenceLevel == .low {
                            FormAdvisory.caution(L10n.formOCRLowConfidence)
                        }

                        if isLowerThanCurrent {
                            FormAdvisory.caution(L10n.formOCRBelowPrevious(Formatters.mileage(currentMileage)))
                        }

                        // Debug: raw OCR text and cropped image preview
                        // Uncomment to diagnose camera/OCR issues:
                        // #if DEBUG
                        // rawTextDebugView
                        // #endif
                    }
                    .padding(Spacing.screenHorizontal)
                    .padding(.top, Spacing.lg)
                }
            }
            .keyboardDismissToolbar()
            // The confirm is the toolbar's, like every other form: the scanned
            // value is a proposal the user accepts, not a second Save button.
            .formToolbar(
                title: L10n.formOCRTitle,
                saveTitle: L10n.formUse,
                canSave: parsedMileage != nil,
                isDirty: false,
                onSave: confirm
            )
        }
        .onAppear {
            // Initialize sourceUnit from detected unit or user preference
            sourceUnit = detectedUnit ?? DistanceSettings.shared.unit
            if mileageText.isEmpty {
                mileageText = String(extractedMileage)
            }
        }
    }

    // MARK: - Mileage Display

    private var mileageDisplay: some View {
        VStack(spacing: Spacing.sm) {
            Text(L10n.formOCRDetectedValue.uppercased())
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(2)

            // The unit sits beside the number until accessibility sizes, where
            // a seven-digit hero no longer leaves room for it.
            heroLayout {
                TextField(text: $mileageText) { EmptyView() }
                    .font(.brutalistHero)
                    // Hero numeral: capped so seven digits still fit the width.
                    .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                    .foregroundStyle(Theme.accent)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    // Hug the digits so the unit sits beside them; when stacked,
                    // take the full width instead so a long reading can't clip.
                    .fixedSize(horizontal: !dynamicTypeSize.isAccessibilitySize, vertical: true)
                    .accessibilityLabel(L10n.a11yDetectedMileage)
                    .onChange(of: mileageText) { _, newValue in
                        let filtered = String(newValue.filter(\.isNumber).prefix(7))
                        if filtered != newValue {
                            mileageText = filtered
                        }
                    }

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
                        .minimumTouchTarget()
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.a11yDistanceUnit)
                .accessibilityValue(sourceUnit.uppercaseAbbreviation)
            }

            Text(L10n.formOCRTapToEdit.uppercased())
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
        .background(Theme.surfaceInstrument)
        .brutalistBorder()
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
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    UIPasteboard.general.string = rawText
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.footnote)
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
        .brutalistBorder()
    }
    #endif

    // MARK: - Confirm

    private func confirm() {
        let userValue = parsedMileage ?? extractedMileage
        AnalyticsService.shared.capture(.ocrConfirmed(
            ocrType: .odometer,
            valueEdited: userValue != extractedMileage
        ))
        onConfirm(finalMileageInMiles)
        dismiss()
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
