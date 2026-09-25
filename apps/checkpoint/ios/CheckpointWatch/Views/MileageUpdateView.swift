//
//  MileageUpdateView.swift
//  CheckpointWatch
//
//  Digital Crown mileage adjustment + quick-step buttons
//  Brutalist: monospace, ALL CAPS, amber accent
//

import SwiftUI

struct MileageUpdateView: View {
    @Environment(WatchDataStore.self) private var dataStore
    @Environment(WatchConnectivityService.self) private var connectivity
    @Environment(\.dismiss) private var dismiss

    /// Dial value in the user's distance unit; converted to miles on save
    @State private var mileage: Double = 0
    @State private var isSaving = false
    @State private var showSaved = false

    private var distanceUnit: DistanceUnit {
        dataStore.vehicleData?.resolvedDistanceUnit ?? .miles
    }

    var body: some View {
        ScrollView {
            VStack(spacing: WatchSpacing.lg) {
                if showSaved {
                    WatchConfirmation(
                        title: String(localized: "MILEAGE SAVED"),
                        tint: WatchColors.accent,
                        onFinish: { dismiss() }
                    )
                } else {
                    // The screen's one job: the dial takes the Crown on arrival.
                    MileageDial(
                        mileage: $mileage,
                        unit: distanceUnit.uppercaseAbbreviation,
                        tint: WatchColors.accent,
                        autofocus: true
                    )

                    MileageStepButtons(mileage: $mileage)

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

                    if !connectivity.isPhoneReachable {
                        PhoneUnreachableNote()
                    }
                }
            }
            .padding(.horizontal, WatchSpacing.md)
        }
        .navigationTitle(Text("Mileage"))
        .onAppear {
            mileage = Double(distanceUnit.fromMiles(dataStore.vehicleData?.currentMileage ?? 0))
        }
    }

    // MARK: - Save

    private func save() {
        guard let vehicleID = dataStore.vehicleData?.vehicleID else { return }
        isSaving = true

        connectivity.sendMileageUpdate(
            vehicleID: vehicleID,
            newMileage: distanceUnit.toMiles(Int(mileage))
        )

        // The confirmation plays the haptic and announces itself.
        withAnimation(.easeIn(duration: 0.2)) {
            showSaved = true
        }
    }
}
