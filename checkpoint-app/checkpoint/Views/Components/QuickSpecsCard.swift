//
//  QuickSpecsCard.swift
//  checkpoint
//
//  Collapsible card showing VIN, tire size, oil type
//  Collapsed by default, tap to expand
//

import SwiftUI

struct QuickSpecsCard: View {
    let vehicle: Vehicle
    let onEdit: () -> Void

    @State private var isExpanded = false

    private var hasAnySpecs: Bool {
        vehicle.vin != nil || vehicle.tireSize != nil || vehicle.oilType != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header (always visible, tappable)
            Button {
                withAnimation(.easeOut(duration: Theme.animationMedium)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text("SPECS")
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.textTertiary)
                        .tracking(2)

                    Spacer()

                    // Quick preview when collapsed (if has data)
                    if !isExpanded && hasAnySpecs {
                        HStack(spacing: Spacing.xs) {
                            if let truncatedVIN = vehicle.truncatedVIN {
                                Text("VIN: \(truncatedVIN)")
                                    .font(.brutalistSecondary)
                                    .foregroundStyle(Theme.textTertiary)
                            }

                            if vehicle.tireSize != nil {
                                Text("|")
                                    .font(.brutalistSecondary)
                                    .foregroundStyle(Theme.gridLine)

                                Text(vehicle.tireSize!)
                                    .font(.brutalistSecondary)
                                    .foregroundStyle(Theme.textTertiary)
                            }
                        }
                    }

                    // Expand/collapse indicator
                    Image(systemName: isExpanded ? "minus" : "plus")
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.accent)
                        .frame(width: 20, height: 20)
                }
                .padding(Spacing.md)
                .background(Theme.surfaceInstrument)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Expandable content
            if isExpanded {
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Theme.gridLine)
                        .frame(height: 1)

                    VStack(spacing: 0) {
                        if let vin = vehicle.vin {
                            specRow(label: "VIN", value: vin)
                            Rectangle()
                                .fill(Theme.gridLine)
                                .frame(height: 1)
                                .padding(.leading, Spacing.md)
                        }

                        if let tireSize = vehicle.tireSize {
                            specRow(label: "TIRE SIZE", value: tireSize)
                            if vehicle.oilType != nil {
                                Rectangle()
                                    .fill(Theme.gridLine)
                                    .frame(height: 1)
                                    .padding(.leading, Spacing.md)
                            }
                        }

                        if let oilType = vehicle.oilType {
                            specRow(label: "OIL TYPE", value: oilType)
                        }

                        // Edit button
                        Button {
                            onEdit()
                        } label: {
                            HStack {
                                Image(systemName: "pencil")
                                    .font(.system(size: 12))
                                Text("EDIT SPECS")
                                    .font(.brutalistLabel)
                                    .tracking(1)
                            }
                            .foregroundStyle(Theme.accent)
                            .frame(maxWidth: .infinity)
                            .padding(Spacing.md)
                        }
                    }
                }
                .background(Theme.surfaceInstrument)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .overlay(
            Rectangle()
                .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
        )
        .clipped()
    }

    private func specRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1)

            Spacer()

            Text(value)
                .font(.brutalistBody)
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
        }
        .padding(Spacing.md)
    }
}

#Preview {
    ZStack {
        AtmosphericBackground()

        VStack(spacing: Spacing.lg) {
            // With all specs
            QuickSpecsCard(
                vehicle: Vehicle(
                    name: "Daily Driver",
                    make: "Toyota",
                    model: "Camry",
                    year: 2022,
                    currentMileage: 32500,
                    vin: "1HGBH41JXMN109186",
                    tireSize: "225/45R17",
                    oilType: "0W-20 Synthetic"
                )
            ) {
                print("Edit tapped")
            }

            // With partial specs
            QuickSpecsCard(
                vehicle: Vehicle(
                    name: "Weekend Car",
                    make: "Mazda",
                    model: "MX-5",
                    year: 2020,
                    currentMileage: 18200,
                    vin: "JM1NDAL79L0123456"
                )
            ) {
                print("Edit tapped")
            }

            // With no specs
            QuickSpecsCard(
                vehicle: Vehicle(
                    name: "New Car",
                    make: "Honda",
                    model: "Civic",
                    year: 2024,
                    currentMileage: 1500
                )
            ) {
                print("Edit tapped")
            }
        }
        .padding(Spacing.screenHorizontal)
    }
    .preferredColorScheme(.dark)
}
