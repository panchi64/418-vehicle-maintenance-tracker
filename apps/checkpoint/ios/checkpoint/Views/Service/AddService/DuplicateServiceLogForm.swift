//
//  DuplicateServiceLogForm.swift
//  checkpoint
//
//  Duplicate a history entry — onto the same vehicle or another one. A DIY
//  owner does the same oil change or wiper swap across cars; this logs it
//  once per car without retyping.
//
//  The form is `ServiceLogForm` (one form, one write path). Its vehicle is
//  fixed for its lifetime — its queries, odometer and draft scope are all
//  scoped to it — so choosing another vehicle rebuilds the form for that
//  vehicle, carrying over what the user has entered. Saving then goes through
//  `LoggedServiceWriter` like any log: a matching tracked service on the
//  target is completed ("Completes X"); otherwise one is created.
//
//  TAP BUDGET (from Services, >1 vehicle):
//    Duplicate to another car   3   long-press row → Duplicate To ▸ car → Save
//

import SwiftUI
import SwiftData

/// Everything in a duplicate form that survives a change of vehicle.
struct ServiceLogCarryover {
    let draft: ServiceFormDraft
    let attachments: [AttachmentPicker.AttachmentData]
}

/// The duplicate door's vehicle choice. Nil (and nothing drawn) with one
/// vehicle.
struct ServiceLogVehicleChoice {
    let vehicles: [Vehicle]
    let select: (Vehicle, ServiceLogCarryover) -> Void
}

/// Presenter for Duplicate: owns the target vehicle and rebuilds the form
/// when it changes.
struct DuplicateServiceLogForm: View {
    let log: ServiceLog
    @State private var target: Vehicle
    @State private var carryover: ServiceLogCarryover?
    @Query private var vehicles: [Vehicle]

    init(log: ServiceLog, target: Vehicle) {
        self.log = log
        _target = State(initialValue: target)
    }

    var body: some View {
        ServiceLogForm(
            duplicating: log,
            vehicle: target,
            carryover: carryover,
            vehicleChoice: vehicles.count > 1 ? ServiceLogVehicleChoice(vehicles: vehicles) { vehicle, carried in
                carryover = carried
                target = vehicle
            } : nil
        )
        // A new vehicle is a new form: its queries and odometer are scoped in init.
        .id(target.id)
    }
}

/// "VEHICLE / Honda Civic ⌃⌄" — shaped like the form's other fields (label,
/// value, rule), on the default path because the vehicle decides what the
/// entry completes. VoiceOver: "Vehicle, Honda Civic, button".
struct ServiceLogVehicleMenu: View {
    let current: Vehicle
    let vehicles: [Vehicle]
    let onSelect: (Vehicle) -> Void

    var body: some View {
        Menu {
            // An inline picker gives the current vehicle the system checkmark.
            Picker(selection: Binding(
                get: { current.id },
                set: { id in
                    guard id != current.id, let vehicle = vehicles.first(where: { $0.id == id }) else { return }
                    HapticService.shared.selectionChanged()
                    onSelect(vehicle)
                }
            )) {
                ForEach(vehicles) { vehicle in
                    Text(vehicle.displayName).tag(vehicle.id)
                }
            } label: {
                EmptyView()
            }
            .pickerStyle(.inline)
        } label: {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(L10n.formVehicle.uppercased())
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.textTertiary)
                    .tracking(1.5)

                HStack(spacing: Spacing.sm) {
                    Text(current.displayName)
                        .font(.brutalistBody)
                        .foregroundStyle(Theme.textPrimary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Theme.accent)
                }
                .frame(minHeight: TouchTarget.minimum)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(Theme.borderSubtle)
                        .frame(height: Theme.borderWidth)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.formVehicle)
        .accessibilityValue(current.displayName)
        .accessibilityIdentifier("form.vehicle")
    }
}

#Preview {
    @Previewable @State var vehicle = Vehicle(name: "Daily", make: "Honda", model: "Civic", year: 2020)

    ZStack {
        AtmosphericBackground()
        ServiceLogVehicleMenu(
            current: vehicle,
            vehicles: [vehicle, Vehicle(name: "Weekend", make: "Mazda", model: "MX-5", year: 2019)],
            onSelect: { _ in }
        )
        .padding(Spacing.screenHorizontal)
    }
}
