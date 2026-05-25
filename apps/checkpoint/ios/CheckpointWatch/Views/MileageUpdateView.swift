//
//  MileageUpdateView.swift
//  CheckpointWatch
//
//  Digital Crown mileage adjustment + quick-step buttons
//  Brutalist: monospace, ALL CAPS, amber accent
//

import SwiftUI
import WatchKit

struct MileageUpdateView: View {
    @Environment(WatchDataStore.self) private var dataStore
    @Environment(WatchConnectivityService.self) private var connectivity
    @Environment(\.dismiss) private var dismiss

    @State private var mileage: Double = 0
    @State private var isSaving = false
    @State private var showSaved = false

    private var distanceUnit: WatchDistanceUnit {
        dataStore.vehicleData?.resolvedDistanceUnit ?? .miles
    }

    var body: some View {
        ScrollView {
            VStack(spacing: WatchSpacing.lg) {
                if showSaved {
                    // Saved confirmation
                    Spacer()
                    VStack(spacing: WatchSpacing.md) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundStyle(WatchColors.accent)
                        Text("SAVED")
                            .font(.watchHeadline)
                            .foregroundStyle(WatchColors.accent)
                    }
                    Spacer()
                } else {
                    // Mileage display
                    Text("\(Int(mileage).formatted())")
                        .font(.watchDisplayLarge)
                        .foregroundStyle(WatchColors.accent)
                        .monospacedDigit()

                    Text(distanceUnit.abbreviation)
                        .font(.watchCaption)
                        .foregroundStyle(WatchColors.textTertiary)

                    WatchDivider()

                    // Quick-adjust buttons
                    HStack(spacing: WatchSpacing.md) {
                        adjustButton(delta: -100, label: "-100")
                        adjustButton(delta: -10, label: "-10")
                        adjustButton(delta: +10, label: "+10")
                        adjustButton(delta: +100, label: "+100")
                    }

                    WatchDivider()

                    // Save button
                    Button {
                        save()
                    } label: {
                        Text("SAVE")
                            .font(.watchBody)
                            .foregroundStyle(WatchColors.backgroundPrimary)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(WatchColors.accent)
                    .disabled(isSaving)

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
        .navigationTitle("MILEAGE")
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

    // MARK: - Save

    private func save() {
        guard let vehicleID = dataStore.vehicleData?.vehicleID else { return }
        isSaving = true

        connectivity.sendMileageUpdate(
            vehicleID: vehicleID,
            newMileage: Int(mileage)
        )

        // Haptic feedback
        WKInterfaceDevice.current().play(.success)

        // Show saved state, then dismiss
        withAnimation(.easeIn(duration: 0.2)) {
            showSaved = true
        }
        Task {
            try? await Task.sleep(for: .milliseconds(800))
            await MainActor.run {
                isSaving = false
                dismiss()
            }
        }
    }
}
