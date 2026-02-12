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

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            InstrumentSectionHeader(title: "Odometer")

            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(alignment: .center) {
                    // Mileage display
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(formattedMileage)
                                .font(.brutalistTitle)
                                .foregroundStyle(Theme.accent)

                            Text(unitAbbreviation)
                                .font(.brutalistLabel)
                                .foregroundStyle(Theme.textTertiary)
                                .tracking(1)
                        }

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
                            .background(Theme.accent)
                    }
                    .accessibilityLabel("Update mileage")
                    .accessibilityHint("Opens mileage entry screen")
                }
            }
            .padding(Spacing.md)
            .background(Theme.surfaceInstrument)
            .overlay(
                Rectangle()
                    .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Odometer, \(formattedMileage) \(unitAbbreviation)")
        .accessibilityValue(vehicle.mileageUpdateDescription)
        .sheet(isPresented: $showMileageSheet) {
            MileageUpdateSheet(
                vehicle: vehicle,
                onSave: { newMileage in
                    onUpdate(newMileage)
                }
            )
            .presentationDetents([.height(450)])
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
