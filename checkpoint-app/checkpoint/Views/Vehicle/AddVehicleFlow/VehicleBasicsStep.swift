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

                        InstrumentTextField(
                            label: L10n.vehicleModel,
                            text: $formState.model,
                            placeholder: L10n.vehicleModelPlaceholder,
                            isRequired: true
                        )

                        InstrumentNumberField(
                            label: L10n.vehicleYear,
                            value: $formState.year,
                            placeholder: L10n.vehicleYearPlaceholder,
                            isRequired: true
                        )
                    }
                }

                // VIN Section
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    InstrumentSectionHeader(title: L10n.vehicleIdentification)

                    VINInputSection(formState: formState)
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
            // VIN input with camera button
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.vehicleVIN)
                    .font(.instrumentLabel)
                    .foregroundStyle(Theme.textTertiary)
                    .tracking(1.5)
                    .textCase(.uppercase)

                HStack(spacing: 0) {
                    TextField(L10n.vehicleVINPlaceholder, text: $formState.vin)
                        .font(.instrumentBody)
                        .foregroundStyle(Theme.textPrimary)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .padding(16)
                        .background(Theme.surfaceInstrument)
                        .onChange(of: formState.vin) {
                            formState.clearVINErrors()
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

            Text(L10n.vehicleVINHelp)
                .font(.caption)
                .foregroundStyle(Theme.textTertiary)
                .padding(.leading, 4)

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
                    // Auto-fill only empty fields
                    if formState.make.isEmpty { formState.make = result.make }
                    if formState.model.isEmpty { formState.model = result.model }
                    if formState.year == nil { formState.year = result.modelYear }
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
