//
//  AddVehicleFlowView.swift
//  checkpoint
//
//  Add a vehicle. One scroll, no wizard.
//
//  The two-step wizard is gone: one entity should not have two disclosure
//  models, and Edit Vehicle's single scroll was already the better one. Section
//  order follows what the app needs — VIN (the fast path) above the fields it
//  fills, then the odometer, then make/model/year, then everything optional.
//
//  See `VehicleFormSections` for the per-section reasoning.
//
//  Saving offers the starter schedule next: a vehicle with no services is an
//  empty app next to a used car.
//

import SwiftUI
import SwiftData

struct AddVehicleFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @State private var formState = VehicleFormState()
    @State private var showBlockingReason = false

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ZStack {
                    AtmosphericBackground()

                    ScrollView {
                        VStack(alignment: .leading, spacing: Spacing.xl) {
                            VehicleVINSection(formState: formState)
                                .id("top")

                            // F2: the blocking advisory sits at the field that
                            // resolves it — the odometer first, then identity.
                            VStack(alignment: .leading, spacing: Spacing.md) {
                                VehicleOdometerSection(formState: formState)
                                if showBlockingReason, formState.currentMileage == nil,
                                   let reason = formState.blockingReason {
                                    FormAdvisory.blocking(reason)
                                }
                            }
                            .id("odometer")

                            VStack(alignment: .leading, spacing: Spacing.md) {
                                VehicleIdentitySection(formState: formState)
                                if showBlockingReason, formState.currentMileage != nil,
                                   let reason = formState.blockingReason {
                                    FormAdvisory.blocking(reason)
                                }
                            }
                            .id("identity")

                            VehicleDetailsSection(formState: formState)
                        }
                        .padding(.horizontal, Spacing.screenHorizontal)
                        .padding(.top, Spacing.md)
                        .padding(.bottom, Spacing.xxl)
                    }
                }
                .keyboardDismissToolbar()
                .trackScreen(.addVehicleBasics)
                .formToolbar(
                    title: L10n.vehicleAdd,
                    saveTitle: L10n.vehicleSave,
                    canSave: formState.blockingReason == nil,
                    isDirty: formState.isDirty,
                    onSave: saveVehicle,
                    onBlocked: {
                        showBlockingReason = true
                        withAnimation {
                            proxy.scrollTo(
                                formState.currentMileage == nil ? "odometer" : "identity",
                                anchor: .center
                            )
                        }
                    }
                )
                .onChange(of: formState.blockingReason) { _, newValue in
                    if newValue == nil { showBlockingReason = false }
                }
                .vehicleCapture(formState)
            }
        }
    }

    // MARK: - Save

    private func saveVehicle() {
        VehicleCapture.recordVINScanConfirmation(formState)

        AnalyticsService.shared.capture(.vehicleAdded(
            usedOCR: formState.usedOdometerOCR,
            usedVINLookup: formState.usedVINLookup,
            hasNickname: !formState.name.isEmpty
        ))

        // `currentMileage` is force-unwrappable in spirit — the odometer is
        // required and Save is blocked without it — but the fallback stays
        // rather than trapping.
        let vehicle = Vehicle(
            name: formState.name,
            make: formState.make,
            model: formState.model,
            year: formState.year ?? 0,
            currentMileage: formState.currentMileage ?? 0,
            vin: formState.vin.isEmpty ? nil : formState.vin,
            licensePlate: formState.licensePlate.isEmpty ? nil : formState.licensePlate,
            tireSize: formState.tireSize.isEmpty ? nil : formState.tireSize,
            oilType: formState.oilType.isEmpty ? nil : formState.oilType,
            notes: formState.notes.isEmpty ? nil : formState.notes
        )

        // Marbete
        vehicle.marbeteExpirationMonth = formState.marbeteExpirationMonth
        vehicle.marbeteExpirationYear = formState.marbeteExpirationYear
        if vehicle.hasMarbeteExpiration {
            NotificationService.shared.scheduleMarbeteNotifications(for: vehicle)
        }

        modelContext.insert(vehicle)
        appState.selectVehicle(vehicle)
        HapticService.shared.success()
        ToastService.shared.show(L10n.toastVehicleSaved, icon: "checkmark.circle", style: .success)
        // Queued by the router until this sheet has closed.
        appState.present(.starterSchedule(vehicle))
        dismiss()
    }
}

#Preview {
    AddVehicleFlowView()
        .environment(AppState())
        .modelContainer(for: Vehicle.self, inMemory: true)
        .preferredColorScheme(.dark)
}
