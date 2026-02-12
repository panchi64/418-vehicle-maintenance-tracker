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
    var onSettingsTap: (() -> Void)? = nil

    private var syncService: CloudSyncStatusService {
        CloudSyncStatusService.shared
    }

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
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(vehicle?.displayName ?? "Select vehicle")
                .accessibilityHint("Double tap to choose a vehicle")

                // Mileage + model info
                if let vehicle = vehicle {
                    HStack(spacing: 0) {
                        // Mileage - tappable to update
                        Button {
                            onMileageTap?()
                        } label: {
                            Text(Formatters.mileage(vehicle.currentMileage))
                                .font(.brutalistBody)
                                .foregroundStyle(Theme.accent)
                                .underline(onMileageTap != nil, color: Theme.accent.opacity(0.5))
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Mileage: \(Formatters.mileage(vehicle.currentMileage))")
                        .accessibilityHint(onMileageTap != nil ? "Double tap to update mileage" : "")

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
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 4)
                }
            }

            // Sync error indicator (only shown on error)
            if let error = syncService.currentError {
                Button {
                    onSettingsTap?()
                } label: {
                    Image(systemName: error.systemImage)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(error.iconColor)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Sync error")
                .accessibilityHint("Double tap to open settings")
            }

            // Settings button
            if let onSettingsTap = onSettingsTap {
                Button {
                    onSettingsTap()
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Theme.textTertiary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Settings")
            }
        }
        .padding(.horizontal, Theme.screenHorizontalPadding)
        .padding(.vertical, Spacing.listItem)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Theme.gridLine)
                .frame(height: Theme.borderWidth)
        }
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
