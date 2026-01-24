//
//  VehicleHeader.swift
//  checkpoint
//
//  Persistent vehicle header showing vehicle name, mileage, and select action
//

import SwiftUI

struct VehicleHeader: View {
    let vehicle: Vehicle?
    var onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: 0) {
                    // Vehicle name - brutalist monospace
                    Text(vehicle?.displayName.uppercased() ?? "SELECT_VEHICLE")
                        .font(.brutalistTitle)
                        .foregroundStyle(Theme.textPrimary)

                    // Mileage + model info
                    if let vehicle = vehicle {
                        HStack(spacing: 0) {
                            Text(formatMileage(vehicle.currentMileage))
                                .font(.brutalistBody)
                                .foregroundStyle(Theme.accent)

                            Text(" // ")
                                .font(.brutalistSecondary)
                                .foregroundStyle(Theme.textTertiary)

                            Text("\(String(vehicle.year))_\(vehicle.make)_\(vehicle.model)".uppercased())
                                .font(.brutalistSecondary)
                                .foregroundStyle(Theme.textTertiary)

                            Spacer()

                            Text("[SELECT]")
                                .font(.brutalistLabel)
                                .foregroundStyle(Theme.accent)
                                .tracking(1)
                        }
                        .padding(.top, 4)
                    }
                }
            }
            .padding(.horizontal, Theme.screenHorizontalPadding)
            .padding(.vertical, 12)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Theme.gridLine)
                    .frame(height: Theme.borderWidth)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func formatMileage(_ miles: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return (formatter.string(from: NSNumber(value: miles)) ?? "\(miles)") + " mi"
    }
}

#Preview {
    ZStack {
        AtmosphericBackground()

        VStack {
            VehicleHeader(vehicle: Vehicle.sampleVehicle) {
                print("Vehicle header tapped")
            }
            .padding(.top, Spacing.sm)

            Spacer()
        }
    }
    .preferredColorScheme(.dark)
}
