//
//  HomeTab+EmptyStates.swift
//  checkpoint
//
//  Empty state views extracted from HomeTab
//

import SwiftUI

extension HomeTab {
    var syncingDataState: some View {
        VStack(spacing: Spacing.lg) {
            ZStack {
                Rectangle()
                    .fill(Theme.accent.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "icloud.and.arrow.down")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(Theme.accent)
                    .symbolEffect(.pulse, options: .repeating)
            }

            VStack(spacing: Spacing.xs) {
                Text("Syncing Your Data")
                    .font(.brutalistHeading)
                    .foregroundStyle(Theme.textPrimary)

                Text("Restoring your vehicles and maintenance\nhistory from iCloud")
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            ProgressView()
                .tint(Theme.accent)
                .padding(.top, Spacing.sm)
        }
        .padding(Spacing.xxl)
    }

    var emptyVehicleState: some View {
        EmptyStateView(
            icon: "car.side.fill",
            title: "No Vehicles",
            message: "Add your first vehicle to start\ntracking maintenance",
            action: { appState.requestAddVehicle(vehicleCount: 0) },
            actionLabel: "Add Vehicle"
        )
    }

    var noServicesState: some View {
        EmptyStateView(
            icon: "checkmark",
            title: "All Clear",
            message: "No maintenance services scheduled\nfor this vehicle"
        )
    }
}
