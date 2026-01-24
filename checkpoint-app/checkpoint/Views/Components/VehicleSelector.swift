//
//  VehicleSelector.swift
//  checkpoint
//
//  Centered dropdown showing current vehicle
//

import SwiftUI

struct VehicleSelector: View {
    let vehicleName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                Text(vehicleName)
                    .font(.title)
                    .foregroundStyle(Theme.textPrimary)

                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Select vehicle")
        .accessibilityHint("Currently selected: \(vehicleName). Double tap to choose a different vehicle.")
    }
}

#Preview {
    ZStack {
        Theme.backgroundPrimary
            .ignoresSafeArea()

        VehicleSelector(vehicleName: "Daily Driver") {
            print("Tapped")
        }
    }
}
