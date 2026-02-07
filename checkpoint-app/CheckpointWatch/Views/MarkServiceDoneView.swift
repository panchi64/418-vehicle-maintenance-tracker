//
//  MarkServiceDoneView.swift
//  CheckpointWatch
//
//  Confirm service completion from Watch — sends to iPhone for processing
//  Brutalist: monospace, ALL CAPS, status-colored accents
//

import SwiftUI

struct MarkServiceDoneView: View {
    @Environment(WatchDataStore.self) private var dataStore
    @Environment(WatchConnectivityService.self) private var connectivity
    @Environment(\.dismiss) private var dismiss

    let service: WatchService

    @State private var mileage: Double = 0
    @State private var isConfirming = false

    var body: some View {
        ScrollView {
            VStack(spacing: WatchSpacing.lg) {
                // Service info
                VStack(spacing: WatchSpacing.sm) {
                    StatusSquare(status: service.status)

                    Text(service.name.uppercased())
                        .font(.watchTitle)
                        .foregroundStyle(WatchColors.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(service.dueDescription.uppercased())
                        .font(.watchCaption)
                        .foregroundStyle(service.status.color)
                }

                WatchDivider()

                // Mileage at service
                VStack(spacing: WatchSpacing.xs) {
                    Text("MILEAGE AT SERVICE")
                        .font(.watchCaption)
                        .foregroundStyle(WatchColors.textTertiary)

                    Text("\(Int(mileage).formatted()) MI")
                        .font(.watchHeadline)
                        .foregroundStyle(WatchColors.textPrimary)
                        .monospacedDigit()
                }

                // Date: today (no picker — keep simple)
                VStack(spacing: WatchSpacing.xs) {
                    Text("DATE")
                        .font(.watchCaption)
                        .foregroundStyle(WatchColors.textTertiary)

                    Text(Date().formatted(date: .abbreviated, time: .omitted).uppercased())
                        .font(.watchLabel)
                        .foregroundStyle(WatchColors.textSecondary)
                }

                WatchDivider()

                // Confirm button
                Button {
                    confirm()
                } label: {
                    Text("MARK DONE")
                        .font(.watchBody)
                        .foregroundStyle(WatchColors.backgroundPrimary)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(WatchColors.statusGood)
                .disabled(isConfirming)

                // Unreachable warning
                if !connectivity.isPhoneReachable {
                    Text("WILL SYNC WHEN\nPHONE IS NEARBY")
                        .font(.watchCaption)
                        .foregroundStyle(WatchColors.textTertiary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, WatchSpacing.md)
        }
        .focusable()
        .digitalCrownRotation(
            $mileage,
            from: 0,
            through: 999999,
            by: 1,
            sensitivity: .medium
        )
        .navigationTitle("COMPLETE")
        .onAppear {
            mileage = Double(dataStore.vehicleData?.currentMileage ?? 0)
        }
    }

    // MARK: - Confirm

    private func confirm() {
        guard let vehicleID = dataStore.vehicleData?.vehicleID else { return }
        isConfirming = true

        connectivity.sendMarkServiceDone(
            vehicleID: vehicleID,
            serviceName: service.name,
            mileageAtService: Int(mileage)
        )

        // Brief delay for feedback, then dismiss
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            await MainActor.run {
                isConfirming = false
                dismiss()
            }
        }
    }
}
