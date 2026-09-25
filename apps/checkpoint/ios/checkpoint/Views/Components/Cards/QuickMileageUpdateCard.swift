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
    var mileageTrackedServiceCount: Int = 0
    let onUpdate: (Int) -> Void

    @State private var showMileageSheet = false

    /// Whether to show estimates (from settings)
    private var showEstimates: Bool {
        MileageEstimateSettings.shared.showEstimates
    }

    /// Whether we're displaying an estimated value
    private var isShowingEstimate: Bool {
        showEstimates && vehicle.isUsingEstimatedMileage
    }

    /// Display mileage: use estimated if available and enabled, otherwise actual
    private var displayMileage: Int {
        isShowingEstimate ? (vehicle.estimatedMileage ?? vehicle.currentMileage) : vehicle.currentMileage
    }

    private var formattedMileage: String {
        let unit = DistanceSettings.shared.unit
        let displayValue = unit.fromMiles(displayMileage)
        let number = Formatters.mileageNumber(displayValue)

        // Add tilda prefix for estimates
        if isShowingEstimate {
            return "~" + number
        }
        return number
    }

    private var unitAbbreviation: String {
        DistanceSettings.shared.unit.uppercaseAbbreviation
    }

    /// Spoken form of the reading ("~45,000" + "MI" would be read as "tilde"
    /// and letters). The card's other lines — pace confidence, last update,
    /// reminder count — combine after it.
    private var odometerAccessibilityLabel: String {
        let distance = L10n.spokenDistance(displayMileage)
        return isShowingEstimate ? L10n.readoutOdometerEstimated(distance) : L10n.readoutOdometer(distance)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            InstrumentSectionHeader(title: "Odometer")

            VStack(alignment: .leading, spacing: Spacing.sm) {
                AdaptiveStack(verticalAlignment: .center) {
                    // Mileage display
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            RollingNumberText(formattedMileage, resetToken: vehicle.id)
                                .font(.brutalistTitle)
                                .foregroundStyle(Theme.accent)

                            Text(unitAbbreviation)
                                .font(.brutalistLabel)
                                .foregroundStyle(Theme.textTertiary)
                                .tracking(1)
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(odometerAccessibilityLabel)

                        // Inline confidence indicator when showing estimate
                        if isShowingEstimate, let confidence = vehicle.paceConfidence {
                            HStack(spacing: Spacing.xs) {
                                CompactConfidenceBar(level: confidence)
                                Text(confidence.label)
                                    .font(.brutalistLabel)
                                    .foregroundStyle(confidence.color)
                                    .tracking(1)
                            }
                        }

                        Text(vehicle.mileageUpdateDescription)
                            .font(.brutalistSecondary)
                            .foregroundStyle(Theme.textTertiary)

                        if mileageTrackedServiceCount > 0 {
                            Text("KEEPS \(mileageTrackedServiceCount) SERVICE REMINDERS ACCURATE")
                                .font(.brutalistLabel)
                                .foregroundStyle(Theme.textTertiary)
                                .tracking(1)
                        }
                    }
                    // One element for the reading; the Update button beside
                    // it stays separately reachable.
                    .accessibilityElement(children: .combine)

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
                            .frame(minHeight: TouchTarget.minimum)
                            .background(Theme.accent)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel(L10n.mileageUpdateTitle)
                }
            }
            .padding(Spacing.md)
            .background(Theme.surfaceInstrument)
            .brutalistBorder()
        }
        .sheet(isPresented: $showMileageSheet) {
            MileageUpdateSheet(
                vehicle: vehicle,
                onSave: { newMileage in
                    onUpdate(newMileage)
                }
            )
            .presentationDetents([.medium, .large])
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
