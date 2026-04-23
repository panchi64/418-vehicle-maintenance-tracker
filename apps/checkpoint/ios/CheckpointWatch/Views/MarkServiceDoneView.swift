//
//  MarkServiceDoneView.swift
//  CheckpointWatch
//
//  Confirm service completion from Watch — sends to iPhone for processing
//  Brutalist: monospace, ALL CAPS, status-colored accents
//

import SwiftUI
import WatchKit

struct MarkServiceDoneView: View {
    @Environment(WatchDataStore.self) private var dataStore
    @Environment(WatchConnectivityService.self) private var connectivity
    @Environment(\.dismiss) private var dismiss

    let service: WatchService

    @State private var mileage: Double = 0
    @State private var isConfirming = false
    @State private var showSuccess = false

    private var distanceUnit: WatchDistanceUnit {
        dataStore.vehicleData?.resolvedDistanceUnit ?? .miles
    }

    var body: some View {
        ScrollView {
            VStack(spacing: WatchSpacing.lg) {
                if showSuccess {
                    // Success confirmation overlay
                    Spacer()
                    VStack(spacing: WatchSpacing.md) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundStyle(WatchColors.statusGood)
                        Text("LOGGED")
                            .font(.watchHeadline)
                            .foregroundStyle(WatchColors.statusGood)
                    }
                    Spacer()
                } else {
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

                        Text("\(Int(mileage).formatted()) \(distanceUnit.abbreviation)")
                            .font(.watchHeadline)
                            .foregroundStyle(WatchColors.textPrimary)
                            .monospacedDigit()
                    }

                    // Quick-adjust buttons
                    HStack(spacing: WatchSpacing.md) {
                        adjustButton(delta: -100, label: "-100")
                        adjustButton(delta: -10, label: "-10")
                        adjustButton(delta: +10, label: "+10")
                        adjustButton(delta: +100, label: "+100")
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
            }
            .padding(.horizontal, WatchSpacing.md)
        }
        .focusable()
        .digitalCrownRotation(
            $mileage,
            from: 0,
            through: 999999,
            by: 10,
            sensitivity: .medium
        )
        .navigationTitle("COMPLETE")
        .onAppear {
            mileage = Double(dataStore.vehicleData?.currentMileage ?? 0)
        }
    }

    // MARK: - Quick Adjust Button

    private func adjustButton(delta: Int, label: String) -> some View {
        Button {
            mileage = max(0, mileage + Double(delta))
        } label: {
            Text(label)
                .font(.watchCaption)
                .foregroundStyle(WatchColors.textSecondary)
                .frame(minWidth: 32)
        }
        .buttonStyle(.bordered)
    }

    // MARK: - Confirm

    private func confirm() {
        guard let vehicleID = dataStore.vehicleData?.vehicleID else { return }
        isConfirming = true

        connectivity.sendMarkServiceDone(
            vehicleID: vehicleID,
            serviceID: service.serviceID,
            serviceName: service.name,
            mileageAtService: Int(mileage)
        )

        // Haptic feedback
        WKInterfaceDevice.current().play(.success)

        // Show success state, then dismiss
        withAnimation(.easeIn(duration: 0.2)) {
            showSuccess = true
        }
        Task {
            try? await Task.sleep(for: .milliseconds(800))
            await MainActor.run {
                isConfirming = false
                dismiss()
            }
        }
    }
}
