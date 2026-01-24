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
                        HStack(spacing: Spacing.sm) {
                            if let truncatedVIN = vehicle.truncatedVIN {
                                Text(truncatedVIN)
                                    .font(.brutalistSecondary)
                                    .foregroundStyle(Theme.textSecondary)
                            }

                            if vehicle.tireSize != nil {
                                Text("•")
                                    .font(.brutalistSecondary)
                                    .foregroundStyle(Theme.gridLine)

                                Text(vehicle.tireSize!)
                                    .font(.brutalistSecondary)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                    }

                    // Chevron indicator with rotation
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
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

                    // Specs grid - values first, labels below
                    VStack(spacing: Spacing.lg) {
                        // Main specs in a horizontal layout
                        HStack(alignment: .top, spacing: Spacing.lg) {
                            // VIN (takes more space)
                            if let vin = vehicle.vin {
                                specBlock(
                                    value: vin,
                                    label: "VIN",
                                    isMonospace: true
                                )
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }

                        // Tire and Oil side by side
                        if vehicle.tireSize != nil || vehicle.oilType != nil {
                            HStack(alignment: .top, spacing: Spacing.lg) {
                                if let tireSize = vehicle.tireSize {
                                    specBlock(
                                        value: tireSize,
                                        label: "TIRES",
                                        isMonospace: false
                                    )
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }

                                if let oilType = vehicle.oilType {
                                    specBlock(
                                        value: oilType,
                                        label: "OIL",
                                        isMonospace: false
                                    )
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }

                        // Empty state
                        if !hasAnySpecs {
                            Text("No specifications added")
                                .font(.brutalistSecondary)
                                .foregroundStyle(Theme.textTertiary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(Spacing.md)
                    .padding(.bottom, Spacing.xs)

                    // Divider before edit button
                    Rectangle()
                        .fill(Theme.gridLine)
                        .frame(height: 1)

                    // Edit button - more subtle
                    Button {
                        onEdit()
                    } label: {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "pencil")
                                .font(.system(size: 11, weight: .medium))
                            Text(hasAnySpecs ? "EDIT" : "ADD SPECS")
                                .font(.brutalistLabel)
                                .tracking(1)
                        }
                        .foregroundStyle(Theme.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
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

    /// Spec block with large value and small label below
    private func specBlock(value: String, label: String, isMonospace: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            // Value - prominent
            Text(value)
                .font(isMonospace ? .brutalistBody : .brutalistHeading)
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            // Label - secondary
            Text(label)
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1)
        }
    }
}

#Preview {
    ZStack {
        AtmosphericBackground()

        ScrollView {
            VStack(spacing: Spacing.lg) {
                // With all specs - expanded
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
    }
    .preferredColorScheme(.dark)
}
