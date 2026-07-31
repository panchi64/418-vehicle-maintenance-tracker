//
//  StepIndicator.swift
//  checkpoint
//
//  Progress dots for a genuinely multi-step flow.
//
//  Moved here when the two-step add-vehicle wizard was deleted. It survives
//  because onboarding is still paged — and onboarding is a *reading* sequence,
//  where knowing how much is left is the point. A form is not: splitting one
//  entity's fields across steps hid the fast path (VIN) behind the slow one and
//  gave the same entity two disclosure models.
//

import SwiftUI

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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.stepOfTotal(currentStep, totalSteps))
    }
}
