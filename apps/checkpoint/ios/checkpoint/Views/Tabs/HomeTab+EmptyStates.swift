//
//  HomeTab+EmptyStates.swift
//  checkpoint
//
//  Home with no vehicle at all. (A vehicle with no services is not an empty
//  state: Home keeps its five sections, each with one quiet line.)
//

import SwiftUI

extension HomeTab {
    @ViewBuilder
    var noVehicleState: some View {
        if case .syncing = SyncStatusService.shared.syncState {
            ContentUnavailableView {
                Label {
                    Text(L10n.homeSyncingTitle)
                        .font(.brutalistHeading)
                        .foregroundStyle(Theme.textPrimary)
                } icon: {
                    Image(systemName: "icloud.and.arrow.down")
                        .foregroundStyle(Theme.accent)
                        .symbolEffect(.pulse, options: .repeating)
                }
            } description: {
                Text(L10n.homeSyncingMessage)
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textSecondary)
            } actions: {
                ProgressView()
                    .tint(Theme.accent)
            }
        } else {
            // One primary: the action that fixes it.
            ContentUnavailableView {
                Label {
                    Text(L10n.homeEmptyTitle)
                        .font(.brutalistHeading)
                        .foregroundStyle(Theme.textPrimary)
                } icon: {
                    Image(systemName: "car.side")
                        .foregroundStyle(Theme.accent)
                }
            } description: {
                Text(L10n.homeEmptyMessage)
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textSecondary)
            } actions: {
                Button(L10n.homeEmptyAddVehicle) {
                    appState.requestAddVehicle(vehicleCount: 0)
                }
                .buttonStyle(.primary)
                .fixedSize()
            }
        }
    }
}
