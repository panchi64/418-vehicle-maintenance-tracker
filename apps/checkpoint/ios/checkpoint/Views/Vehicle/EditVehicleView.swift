//
//  EditVehicleView.swift
//  checkpoint
//
//  Edit an existing vehicle. Shares `VehicleFormState` and the section views
//  with Add Vehicle, so validation, VIN decoding and OCR behave identically;
//  only the arrangement differs — identity and odometer first, the marbete on
//  the default path (it schedules reminders), reference fields in Details.
//

import SwiftUI
import SwiftData

struct EditVehicleView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var services: [Service]

    let vehicle: Vehicle

    @State private var formState: VehicleFormState
    @State private var showBlockingReason = false
    @State private var showDeleteConfirmation = false

    init(vehicle: Vehicle) {
        self.vehicle = vehicle
        _formState = State(initialValue: VehicleFormState(vehicle: vehicle))
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ZStack {
                    AtmosphericBackground()

                    ScrollView {
                        VStack(alignment: .leading, spacing: Spacing.xl) {
                            // F2: the blocking advisory sits at the field that
                            // resolves it — identity first, then the odometer.
                            VStack(alignment: .leading, spacing: Spacing.md) {
                                VehicleIdentitySection(formState: formState, includesNickname: true)
                                if showBlockingReason, formState.currentMileage != nil,
                                   let reason = formState.blockingReason {
                                    FormAdvisory.blocking(reason)
                                }
                            }
                            .id("identity")

                            VStack(alignment: .leading, spacing: Spacing.md) {
                                VehicleOdometerSection(formState: formState)
                                if showBlockingReason, formState.currentMileage == nil,
                                   let reason = formState.blockingReason {
                                    FormAdvisory.blocking(reason)
                                }
                            }
                            .id("odometer")

                            EditVehicleMarbeteSection(formState: formState)

                            EditVehicleDetailsSection(formState: formState)

                            deleteButton
                        }
                        .padding(.horizontal, Spacing.screenHorizontal)
                        .padding(.top, Spacing.md)
                        .padding(.bottom, Spacing.xxl)
                    }
                }
                .keyboardDismissToolbar()
                .formToolbar(
                    title: L10n.vehicleEditTitle,
                    subtitle: vehicle.displayName,
                    canSave: formState.blockingReason == nil,
                    isDirty: formState.isDirty,
                    onSave: saveChanges,
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
                .trackScreen(.editVehicle)
                .vehicleCapture(formState)
            }
        }
    }

    /// Destructive, so last in the scroll and never beside Save (F1).
    private var deleteButton: some View {
        DestructiveFormButton(title: L10n.vehicleDeleteAction) {
            showDeleteConfirmation = true
        }
        .alert(L10n.vehicleDeleteConfirmTitle, isPresented: $showDeleteConfirmation) {
            Button(L10n.commonDelete, role: .destructive) { deleteVehicle() }
            Button(L10n.commonCancel, role: .cancel) {}
        } message: {
            Text(L10n.vehicleDeleteConfirmMessage)
        }
    }

    // MARK: - Save

    private func saveChanges() {
        HapticService.shared.success()
        VehicleCapture.recordVINScanConfirmation(formState)
        AnalyticsService.shared.capture(.vehicleEdited)

        let fields = formState.fields
        vehicle.name = fields.name
        vehicle.make = fields.make
        vehicle.model = fields.model
        vehicle.year = fields.year ?? 0
        // F11: an edited odometer is a manual reading — record it (timestamp +
        // snapshot) rather than overwrite the number and leave the estimate
        // engine measuring from a stale date. Unchanged means no new reading.
        if let mileage = fields.currentMileage, mileage != vehicle.currentMileage {
            vehicle.recordMileage(mileage, source: .manual, in: modelContext)
        }
        vehicle.vin = fields.vin.isEmpty ? nil : fields.vin
        vehicle.licensePlate = fields.licensePlate.isEmpty ? nil : fields.licensePlate
        vehicle.tireSize = fields.tireSize.isEmpty ? nil : fields.tireSize
        vehicle.oilType = fields.oilType.isEmpty ? nil : fields.oilType
        vehicle.notes = fields.notes.isEmpty ? nil : fields.notes

        let hadMarbete = vehicle.hasMarbeteExpiration
        vehicle.marbeteExpirationMonth = fields.marbeteExpirationMonth
        vehicle.marbeteExpirationYear = fields.marbeteExpirationYear
        if vehicle.hasMarbeteExpiration {
            NotificationService.shared.scheduleMarbeteNotifications(for: vehicle)
        } else if hadMarbete {
            NotificationService.shared.cancelMarbeteNotifications(for: vehicle)
        }

        // Refresh pending service reminders so they pick up edits
        // (name, mileage) instead of firing with stale content
        NotificationService.shared.rescheduleNotifications(for: vehicle)

        AppIconService.shared.updateIcon(for: vehicle, services: services)
        WidgetDataService.shared.updateWidget(for: vehicle)
        ToastService.shared.show(L10n.toastVehicleUpdated, icon: "checkmark", style: .success)
        dismiss()
    }

    private func deleteVehicle() {
        HapticService.shared.warning()
        AnalyticsService.shared.capture(.vehicleDeleted)
        NotificationService.shared.cancelAllNotifications(for: vehicle)
        modelContext.delete(vehicle)
        // Sweep documents that were linked only to this vehicle and have no
        // service log — Vehicle.documents uses .nullify, not .cascade, so
        // they'd otherwise persist forever with no owner.
        Document.purgeOrphans(in: modelContext)
        AppIconService.shared.updateIcon(for: vehicle, services: services)
        WidgetDataService.shared.clearWidgetData()
        dismiss()
    }
}

#Preview {
    @Previewable @State var vehicle = Vehicle(
        name: "Daily Driver",
        make: "Toyota",
        model: "Camry",
        year: 2022,
        currentMileage: 32500,
        vin: "1HGBH41JXMN109186",
        tireSize: "225/45R17",
        oilType: "0W-20 Synthetic"
    )

    EditVehicleView(vehicle: vehicle)
        .modelContainer(for: Vehicle.self, inMemory: true)
}
