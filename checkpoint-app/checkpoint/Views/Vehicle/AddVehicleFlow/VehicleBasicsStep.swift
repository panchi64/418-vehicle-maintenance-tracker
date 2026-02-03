//
//  VehicleBasicsStep.swift
//  checkpoint
//
//  Step 1 of the add vehicle wizard: Basic vehicle information
//

import SwiftUI

struct VehicleBasicsStep: View {
    @Bindable var formState: VehicleFormState
    let onNext: () -> Void

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

                // Next button
                Button(L10n.commonNext) {
                    onNext()
                }
                .buttonStyle(.primary)
                .disabled(!formState.isBasicsValid)
                .padding(.top, Spacing.md)
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

#Preview {
    ZStack {
        AtmosphericBackground()

        VehicleBasicsStep(
            formState: VehicleFormState(),
            onNext: {}
        )
    }
    .preferredColorScheme(.dark)
}
