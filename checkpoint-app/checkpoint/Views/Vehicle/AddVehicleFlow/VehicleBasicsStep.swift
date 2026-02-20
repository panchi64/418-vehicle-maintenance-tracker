//
//  VehicleBasicsStep.swift
//  checkpoint
//
//  Step 1 of the add vehicle wizard: Basic vehicle information and VIN
//

import SwiftUI

struct VehicleBasicsStep: View {
    @Bindable var formState: VehicleFormState

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Step indicator
                StepIndicator(currentStep: 1, totalSteps: 2)
                    .padding(.top, Spacing.md)

                // Vehicle Basics Section
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    InstrumentSectionHeader(title: L10n.addVehicleBasics)

                    VStack(spacing: Spacing.md) {
                        InstrumentTextField(
                            label: L10n.vehicleNickname,
                            text: $formState.name,
                            placeholder: L10n.vehicleNicknamePlaceholder
                        )

                        InstrumentTextField(
                            label: L10n.vehicleMake,
                            text: $formState.make,
                            placeholder: L10n.vehicleMakePlaceholder,
                            isRequired: true
                        )
                        .overlay(
                            Rectangle()
                                .strokeBorder(Theme.accent, lineWidth: Theme.borderWidth)
                                .opacity(formState.autoFilledFields.contains("make") ? 1 : 0)
                                .animation(.easeOut(duration: Theme.animationMedium), value: formState.autoFilledFields)
                        )

                        InstrumentTextField(
                            label: L10n.vehicleModel,
                            text: $formState.model,
                            placeholder: L10n.vehicleModelPlaceholder,
                            isRequired: true
                        )
                        .overlay(
                            Rectangle()
                                .strokeBorder(Theme.accent, lineWidth: Theme.borderWidth)
                                .opacity(formState.autoFilledFields.contains("model") ? 1 : 0)
                                .animation(.easeOut(duration: Theme.animationMedium), value: formState.autoFilledFields)
                        )

                        InstrumentNumberField(
                            label: L10n.vehicleYear,
                            value: $formState.year,
                            placeholder: L10n.vehicleYearPlaceholder,
                            isRequired: true
                        )
                        .overlay(
                            Rectangle()
                                .strokeBorder(Theme.accent, lineWidth: Theme.borderWidth)
                                .opacity(formState.autoFilledFields.contains("year") ? 1 : 0)
                                .animation(.easeOut(duration: Theme.animationMedium), value: formState.autoFilledFields)
                        )
                    }
                }

                // VIN Section
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    InstrumentSectionHeader(title: L10n.vehicleIdentification)

                    VINInputSection(formState: formState)

                    InstrumentTextField(
                        label: "License Plate",
                        text: $formState.licensePlate,
                        placeholder: "ABC-1234 (Optional)"
                    )
                }

            }
            .padding(Spacing.screenHorizontal)
            .padding(.bottom, Spacing.xxl)
        }
    }
}

// MARK: - Step Indicator

struct StepIndicator: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(1...totalSteps, id: \.self) { step in
                Rectangle()
                    .fill(step == currentStep ? Theme.accent : Color.clear)
                    .frame(width: 8, height: 8)
                    .overlay(
                        Rectangle()
                            .strokeBorder(
                                step == currentStep ? Theme.accent : Theme.gridLine,
                                lineWidth: Theme.borderWidth
                            )
                    )
            }
        }
    }
}

// MARK: - VIN Input Section

private struct VINInputSection: View {
    @Bindable var formState: VehicleFormState

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Value prop banner — visible when VIN is empty
            if formState.vin.isEmpty {
                VINValuePropBanner()
                    .transition(.opacity)
            }

            // VIN input with camera button
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.vehicleVIN)
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.textTertiary)
                    .tracking(1.5)
                    .textCase(.uppercase)

                HStack(spacing: 0) {
                    TextField(L10n.vehicleVINPlaceholder, text: $formState.vin)
                        .font(.brutalistBody)
                        .foregroundStyle(Theme.textPrimary)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .padding(16)
                        .background(Theme.surfaceInstrument)
                        .onChange(of: formState.vin) {
                            formState.clearVINErrors()
                            formState.clearAutoFillFeedback()
                        }

                    // Camera scan button
                    if formState.isCameraAvailable {
                        Button {
                            formState.clearVINOCRError()
                            formState.showVINCamera = true
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

            // Dynamic character count
            VINCharacterCountLabel(vin: formState.vin, isValid: formState.isVINValid)
                .padding(.leading, 4)

            // Auto-fill success banner
            if formState.vinLookupSucceeded {
                VINAutoFillBanner()
                    .transition(.opacity)
            }

            // VIN OCR processing indicator
            if formState.isProcessingVINOCR {
                OCRProcessingIndicator(text: L10n.addVehicleScanningVIN)
            }

            // VIN OCR error
            if let error = formState.vinOCRError {
                ErrorMessageRow(message: error) {
                    formState.clearVINOCRError()
                }
            }

            // Look Up VIN button
            if formState.isVINValid {
                VINLookupButton(formState: formState)
            }

            // VIN lookup error
            if let error = formState.vinLookupError {
                ErrorMessageRow(message: error) {
                    formState.vinLookupError = nil
                }
            }
        }
        .animation(.easeOut(duration: Theme.animationMedium), value: formState.vin.isEmpty)
        .animation(.easeOut(duration: Theme.animationMedium), value: formState.vinLookupSucceeded)
    }
}

// MARK: - VIN Value Prop Banner

private struct VINValuePropBanner: View {
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: "info.circle")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.accent)

            Text(L10n.addVehicleVINValueProp)
                .font(.brutalistSecondary)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(Spacing.listItem)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.accent.opacity(0.08))
        .overlay(
            Rectangle()
                .strokeBorder(Theme.accent.opacity(0.2), lineWidth: Theme.borderWidth)
        )
    }
}

// MARK: - VIN Character Count Label

private struct VINCharacterCountLabel: View {
    let vin: String
    let isValid: Bool

    var body: some View {
        if vin.isEmpty {
            Text(L10n.vehicleVINHelp)
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1.5)
                .textCase(.uppercase)
        } else if isValid {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                Text(L10n.addVehicleVINValidLookup)
            }
            .font(.brutalistLabel)
            .foregroundStyle(Theme.statusGood)
            .tracking(1.5)
            .textCase(.uppercase)
        } else {
            Text("\(vin.count) / 17 CHARACTERS")
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1.5)
        }
    }
}

// MARK: - VIN Auto-Fill Banner

private struct VINAutoFillBanner: View {
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "checkmark")
                .font(.system(size: 10, weight: .bold))

            Text(L10n.addVehicleVINDetailsFilled)
        }
        .font(.brutalistLabel)
        .foregroundStyle(Theme.statusGood)
        .tracking(1.5)
        .padding(Spacing.listItem)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.statusGood.opacity(0.1))
        .overlay(
            Rectangle()
                .strokeBorder(Theme.statusGood.opacity(0.3), lineWidth: Theme.borderWidth)
        )
    }
}

// MARK: - VIN Lookup Button

private struct VINLookupButton: View {
    @Bindable var formState: VehicleFormState

    var body: some View {
        Button {
            lookUpVIN()
        } label: {
            HStack(spacing: Spacing.sm) {
                if formState.isDecodingVIN {
                    ProgressView()
                        .tint(Theme.surfaceInstrument)
                }
                Text(formState.isDecodingVIN ? L10n.addVehicleVINLookupLoading : L10n.addVehicleVINLookup)
            }
        }
        .buttonStyle(.secondary)
        .disabled(formState.isDecodingVIN)
        .padding(.top, Spacing.xs)
    }

    private func lookUpVIN() {
        formState.isDecodingVIN = true
        formState.vinLookupError = nil

        Task {
            do {
                let result = try await NHTSAService.shared.decodeVIN(formState.vin)

                await MainActor.run {
                    formState.isDecodingVIN = false
                    formState.usedVINLookup = true

                    var filled: Set<String> = []
                    // Auto-fill only empty fields
                    if formState.make.isEmpty {
                        formState.make = result.make
                        filled.insert("make")
                    }
                    if formState.model.isEmpty {
                        formState.model = result.model
                        filled.insert("model")
                    }
                    if formState.year == nil {
                        formState.year = result.modelYear
                        filled.insert("year")
                    }

                    if !filled.isEmpty {
                        formState.autoFilledFields = filled
                        formState.vinLookupSucceeded = true

                        // Auto-clear feedback after 3 seconds
                        Task {
                            try? await Task.sleep(for: .seconds(3))
                            formState.clearAutoFillFeedback()
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    formState.isDecodingVIN = false
                    formState.vinLookupError = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    ZStack {
        AtmosphericBackground()

        VehicleBasicsStep(formState: VehicleFormState())
    }
    .preferredColorScheme(.dark)
}
