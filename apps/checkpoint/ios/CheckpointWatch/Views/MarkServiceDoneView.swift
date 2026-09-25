//
//  MarkServiceDoneView.swift
//  CheckpointWatch
//
//  Confirm service completion from Watch — sends to iPhone for processing
//  Brutalist: monospace, ALL CAPS, status as shape + word
//

import SwiftUI

struct MarkServiceDoneView: View {
    @Environment(WatchDataStore.self) private var dataStore
    @Environment(WatchConnectivityService.self) private var connectivity
    @Environment(\.dismiss) private var dismiss

    let service: WatchService

    /// Dial value in the user's distance unit; converted to miles on confirm
    @State private var mileage: Double = 0
    @State private var isConfirming = false
    @State private var showSuccess = false

    private var distanceUnit: DistanceUnit {
        dataStore.vehicleData?.resolvedDistanceUnit ?? .miles
    }

    var body: some View {
        // The Crown scrolls this screen; tap the mileage dial to hand it the
        // Crown instead.
        ScrollView {
            VStack(spacing: WatchSpacing.lg) {
                if showSuccess {
                    WatchConfirmation(
                        title: String(localized: "SERVICE LOGGED"),
                        tint: WatchColors.statusGood,
                        onFinish: { dismiss() }
                    )
                } else {
                    serviceHeader

                    WatchDivider()

                    VStack(spacing: WatchSpacing.xs) {
                        Text("MILEAGE AT SERVICE")
                            .font(.watchCaption)
                            .foregroundStyle(WatchColors.textSecondary)
                        MileageDial(
                            mileage: $mileage,
                            unit: distanceUnit.uppercaseAbbreviation,
                            tint: WatchColors.textPrimary
                        )
                    }

                    MileageStepButtons(mileage: $mileage)

                    // Date: today (no picker — keep simple)
                    VStack(spacing: WatchSpacing.xs) {
                        Text("DATE")
                            .font(.watchCaption)
                            .foregroundStyle(WatchColors.textSecondary)
                        Text(Date().formatted(date: .abbreviated, time: .omitted).uppercased())
                            .font(.watchLabel)
                            .foregroundStyle(WatchColors.textPrimary)
                    }
                    .accessibilityElement(children: .combine)

                    WatchDivider()

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

                    if !connectivity.isPhoneReachable {
                        PhoneUnreachableNote()
                    }
                }
            }
            .padding(.horizontal, WatchSpacing.md)
        }
        .navigationTitle(Text("Complete"))
        .onAppear {
            mileage = Double(distanceUnit.fromMiles(dataStore.vehicleData?.currentMileage ?? 0))
        }
    }

    private var serviceHeader: some View {
        VStack(spacing: WatchSpacing.sm) {
            Text(service.name.uppercased())
                .font(.watchTitle)
                .foregroundStyle(WatchColors.textPrimary)
                .multilineTextAlignment(.center)

            WatchStatusTag(status: service.status)

            Text(service.dueDescription.uppercased())
                .font(.watchCaption)
                .foregroundStyle(WatchColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Confirm

    private func confirm() {
        guard let vehicleID = dataStore.vehicleData?.vehicleID else { return }
        isConfirming = true

        connectivity.sendMarkServiceDone(
            vehicleID: vehicleID,
            serviceID: service.serviceID,
            serviceName: service.name,
            mileageAtService: distanceUnit.toMiles(Int(mileage))
        )

        // The confirmation plays the haptic and announces itself.
        withAnimation(.easeIn(duration: 0.2)) {
            showSuccess = true
        }
    }
}
