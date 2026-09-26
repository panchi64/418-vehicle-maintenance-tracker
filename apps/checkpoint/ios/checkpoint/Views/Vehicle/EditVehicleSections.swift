//
//  EditVehicleSections.swift
//  checkpoint
//
//  The sections only Edit Vehicle arranges this way. Everything they contain
//  is shared with Add Vehicle (`VehicleFormSections`).
//

import SwiftUI

/// The marbete stays on Edit's default path: filling it schedules renewal
/// reminders, so it makes a feature work rather than completing a record.
/// The tag states that effect ("[OPTIONAL] is a promise").
struct EditVehicleMarbeteSection: View {
    @Bindable var formState: VehicleFormState

    var body: some View {
        FormSection(title: L10n.vehicleMarbete, trailing: L10n.formOptionalTag) {
            VehicleMarbeteFields(formState: formState, help: L10n.vehicleMarbeteHelpLong)
        }
    }
}

/// Reference values nothing computes from — VIN, plate, specs — in the
/// Details disclosure, which opens by itself once any of them is filled.
/// Notes are not here: a vehicle has a list of them now, edited from its
/// Notes screen (Home → specs → Notes).
struct EditVehicleDetailsSection: View {
    @Bindable var formState: VehicleFormState

    private var filledCount: Int {
        let fields = formState.fields
        return [fields.vin, fields.licensePlate, fields.tireSize, fields.oilType]
            .filter { !$0.isEmpty }
            .count
    }

    var body: some View {
        CollapsibleDetailsSection(
            storageKey: "formDetailsEditVehicle",
            filledCount: filledCount,
            autoExpandWhenFilled: true
        ) {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                VehicleVINSection(formState: formState)

                FormSection(title: L10n.vehicleSpecifications, trailing: L10n.formOptionalTag) {
                    VehicleSpecFields(formState: formState)
                }
            }
        }
    }
}
