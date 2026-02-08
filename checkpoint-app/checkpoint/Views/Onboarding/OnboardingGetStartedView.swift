//
//  OnboardingGetStartedView.swift
//  checkpoint
//
//  Phase 3: Full-screen VIN input view with lookup, manual entry, and skip options
//

import SwiftUI

struct OnboardingGetStartedView: View {
    let onVINLookupComplete: (VINDecodeResult, String) -> Void
    let onManualEntry: () -> Void
    let onSkip: () -> Void

    @State private var vin = ""
    @State private var isDecodingVIN = false
    @State private var vinLookupError: String?
    @State private var vinResult: VINDecodeResult?
    @State private var showVINCamera = false

    private var isVINValid: Bool {
        let trimmed = vin.trimmingCharacters(in: .whitespaces)
        guard trimmed.count == 17 else { return false }
        let forbidden = CharacterSet(charactersIn: "IOQioq")
        return trimmed.unicodeScalars.allSatisfy {
            !forbidden.contains($0) && CharacterSet.alphanumerics.contains($0)
        }
    }

    var body: some View {
        ZStack {
            AtmosphericBackground()

            VStack(spacing: 0) {
                // Skip button — top right
                HStack {
                    Spacer()
                    Button {
                        onSkip()
                    } label: {
                        Text(L10n.onboardingSkip)
                            .brutalistLabelStyle(color: Theme.textTertiary)
                    }
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.top, Spacing.md)

                ScrollView {
                    VStack(spacing: 0) {
                        Spacer(minLength: Spacing.xxl)

                        VStack(alignment: .leading, spacing: Spacing.lg) {
                            // Title
                            Text(L10n.onboardingGetStartedTitle)
                                .font(.brutalistHeading)
                                .foregroundStyle(Theme.textPrimary)
                                .textCase(.uppercase)

                            Rectangle()
                                .fill(Theme.gridLine)
                                .frame(height: Theme.borderWidth)

                            // VIN section
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                HStack(spacing: Spacing.sm) {
                                    Image(systemName: "barcode.viewfinder")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(Theme.accent)

                                    Text(L10n.onboardingGetStartedVINLabel)
                                        .brutalistLabelStyle(color: Theme.accent)
                                }

                                Text(L10n.onboardingGetStartedVINHelp)
                                    .font(.brutalistSecondary)
                                    .foregroundStyle(Theme.textSecondary)
                            }

                            // VIN input field
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 0) {
                                    TextField(L10n.onboardingGetStartedVINPlaceholder, text: $vin)
                                        .font(.brutalistBody)
                                        .foregroundStyle(Theme.textPrimary)
                                        .textInputAutocapitalization(.characters)
                                        .autocorrectionDisabled()
                                        .padding(16)
                                        .background(Theme.surfaceInstrument)
                                        .onChange(of: vin) {
                                            vinLookupError = nil
                                            vinResult = nil
                                        }

                                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                        Button {
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

                                // Character count
                                Text(L10n.onboardingGetStartedCharacters(vin.count))
                                    .font(.brutalistLabel)
                                    .foregroundStyle(Theme.textTertiary)
                                    .tracking(1.5)
                                    .textCase(.uppercase)
                                    .padding(.leading, 4)
                            }

                            // VIN lookup error
                            if let error = vinLookupError {
                                Text(error)
                                    .font(.brutalistSecondary)
                                    .foregroundStyle(Theme.statusOverdue)
                            }

                            // VIN lookup results
                            if let result = vinResult {
                                VStack(alignment: .leading, spacing: Spacing.sm) {
                                    vinResultRow(label: "MAKE", value: result.make)
                                    vinResultRow(label: "MODEL", value: result.model)
                                    if let year = result.modelYear {
                                        vinResultRow(label: "YEAR", value: String(year))
                                    }
                                }
                                .padding(Spacing.md)
                                .background(Theme.surfaceInstrument)
                                .overlay(
                                    Rectangle()
                                        .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
                                )
                            }

                            // Primary action button
                            if vinResult != nil {
                                Button {
                                    onVINLookupComplete(vinResult!, vin)
                                } label: {
                                    Text(L10n.onboardingGetStartedAddVehicle)
                                }
                                .buttonStyle(.primary)
                            } else if isVINValid {
                                Button {
                                    lookUpVIN()
                                } label: {
                                    HStack(spacing: Spacing.sm) {
                                        if isDecodingVIN {
                                            ProgressView()
                                                .tint(Theme.surfaceInstrument)
                                        }
                                        Text(isDecodingVIN ? L10n.onboardingGetStartedLookingUp : L10n.onboardingGetStartedLookup)
                                    }
                                }
                                .buttonStyle(.primary)
                                .disabled(isDecodingVIN)
                            }

                            // Divider with OR
                            HStack(spacing: Spacing.sm) {
                                Rectangle()
                                    .fill(Theme.gridLine)
                                    .frame(height: 1)
                                Text(L10n.onboardingGetStartedOr)
                                    .font(.brutalistLabel)
                                    .foregroundStyle(Theme.textTertiary)
                                    .tracking(1.5)
                                Rectangle()
                                    .fill(Theme.gridLine)
                                    .frame(height: 1)
                            }

                            // Manual entry
                            Button {
                                onManualEntry()
                            } label: {
                                Text(L10n.onboardingGetStartedManual)
                            }
                            .buttonStyle(.secondary)

                            // Skip
                            HStack {
                                Spacer()
                                Button {
                                    onSkip()
                                } label: {
                                    Text(L10n.onboardingGetStartedSkip)
                                        .brutalistLabelStyle(color: Theme.textTertiary)
                                }
                                Spacer()
                            }
                        }
                        .padding(.horizontal, Spacing.screenHorizontal)

                        Spacer(minLength: Spacing.xxl)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $showVINCamera) {
            OdometerCameraSheet(
                onImageCaptured: { image in
                    processVINOCR(image: image)
                },
                guideText: L10n.addVehicleVINAlignGuide,
                viewfinderAspectRatio: 5.0
            )
        }
    }

    // MARK: - VIN Result Row

    private func vinResultRow(label: String, value: String) -> some View {
        HStack {
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Theme.statusGood)

            Text(label)
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1.5)

            Spacer()

            Text(value)
                .font(.brutalistBody)
                .foregroundStyle(Theme.textPrimary)
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
                    vinResult = result
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
        Task {
            do {
                let result = try await VINOCRService.shared.recognizeVIN(from: image)
                await MainActor.run {
                    vin = result.vin
                }
            } catch {
                await MainActor.run {
                    vinLookupError = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    OnboardingGetStartedView(
        onVINLookupComplete: { _, _ in },
        onManualEntry: {},
        onSkip: {}
    )
    .preferredColorScheme(.dark)
}
