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
    var onMileageTap: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: 0) {
                // Vehicle name - brutalist monospace (taps to vehicle picker)
                Button {
                    onTap()
                } label: {
                    Text(vehicle?.displayName.uppercased() ?? "SELECT_VEHICLE")
                        .font(.brutalistTitle)
                        .foregroundStyle(Theme.textPrimary)
                }
                .buttonStyle(.plain)

                // Mileage + model info
                if let vehicle = vehicle {
                    HStack(spacing: 0) {
                        // Mileage - tappable to update
                        Button {
                            onMileageTap?()
                        } label: {
                            Text(formatMileage(vehicle.currentMileage))
                                .font(.brutalistBody)
                                .foregroundStyle(Theme.accent)
                                .underline(onMileageTap != nil, color: Theme.accent.opacity(0.5))
                        }
                        .buttonStyle(.plain)

                        // Separator and model info - tap goes to vehicle picker
                        Button {
                            onTap()
                        } label: {
                            HStack(spacing: 0) {
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
                        }
                        .buttonStyle(.plain)
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
            VehicleHeader(
                vehicle: Vehicle.sampleVehicle,
                onTap: {
                    print("Vehicle header tapped")
                },
                onMileageTap: {
                    print("Mileage tapped")
                }
            )
            .padding(.top, Spacing.sm)

            Spacer()
        }
    }
    .preferredColorScheme(.dark)
}
