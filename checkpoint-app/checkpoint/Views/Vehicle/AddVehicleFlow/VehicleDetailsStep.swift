//
//  VehicleDetailsStep.swift
//  checkpoint
//
//  Step 2 of the add vehicle wizard: Optional details (odometer, specs, notes)
//

import SwiftUI

struct VehicleDetailsStep: View {
    @Bindable var formState: VehicleFormState

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Step indicator
                StepIndicator(currentStep: 2, totalSteps: 2)
                    .padding(.top, Spacing.md)

                // Odometer Section
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    InstrumentSectionHeader(title: L10n.vehicleOdometer)

                    InstrumentNumberField(
                        label: L10n.vehicleCurrentMileage,
                        value: $formState.currentMileage,
                        placeholder: L10n.vehicleMileagePlaceholder,
                        suffix: "mi",
                        showCameraButton: formState.isCameraAvailable,
                        onCameraTap: {
                            formState.clearOdometerError()
                            formState.showOdometerCamera = true
                        }
                    )

                    // Odometer OCR processing indicator
                    if formState.isProcessingOdometerOCR {
                        OCRProcessingIndicator(text: L10n.addVehicleScanningOdometer)
                    }

                    // Odometer OCR error
                    if let error = formState.odometerOCRError {
                        ErrorMessageRow(message: error) {
                            formState.clearOdometerError()
                        }
                    }
                }

                // Specifications Section
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    InstrumentSectionHeader(title: L10n.vehicleSpecifications)

                    VStack(spacing: Spacing.md) {
                        InstrumentTextField(
                            label: L10n.vehicleTireSize,
                            text: $formState.tireSize,
                            placeholder: L10n.vehicleTireSizePlaceholder
                        )

                        InstrumentTextField(
                            label: L10n.vehicleOilType,
                            text: $formState.oilType,
                            placeholder: L10n.vehicleOilTypePlaceholder
                        )
                    }
                }

                // Marbete Section (Registration Tag)
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    InstrumentSectionHeader(title: "Marbete")

                    MarbetePicker(
                        month: $formState.marbeteExpirationMonth,
                        year: $formState.marbeteExpirationYear
                    )

                    Text("Yearly vehicle registration tag expiration")
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.textTertiary)
                        .padding(.leading, 4)
                }

                // Notes Section
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    InstrumentSectionHeader(title: L10n.vehicleNotes)

                    InstrumentTextEditor(
                        label: L10n.vehicleNotes,
                        text: $formState.notes,
                        placeholder: L10n.vehicleNotesPlaceholder
                    )
                }

            }
            .padding(Spacing.screenHorizontal)
            .padding(.bottom, Spacing.xxl)
        }
    }
}

#Preview {
    ZStack {
        AtmosphericBackground()

        VehicleDetailsStep(formState: VehicleFormState())
    }
    .preferredColorScheme(.dark)
}
