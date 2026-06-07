import SwiftUI
import DesignKit
import VehicleSharing

/// Compact card on the main screen showing the selected vehicle's odometer
/// (published by Checkpoint) with a vehicle picker and an update action.
struct OdometerCard: View {
    @Environment(\.theme) private var theme
    @Environment(OdometerStore.self) private var store

    @State private var showingUpdate = false

    var body: some View {
        if let vehicle = store.selectedVehicle {
            content(for: vehicle)
                .sheet(isPresented: $showingUpdate) {
                    OdometerUpdateSheet(vehicle: vehicle)
                }
        }
    }

    private func content(for vehicle: SharedVehicleOdometer) -> some View {
        let unit = vehicle.distanceUnit
        let display = unit.fromMiles(vehicle.displayMileage)

        return VStack(alignment: .leading, spacing: DKSpacing.sm) {
            HStack {
                Text("odometer.title")
                    .font(theme.font(.caption, weight: .semibold))
                    .foregroundStyle(theme.textTertiary)
                    .textCase(.uppercase)
                    .tracking(2)

                Spacer()

                vehiclePicker(selected: vehicle)
            }

            HStack(alignment: .firstTextBaseline, spacing: DKSpacing.xs) {
                Text(display.formatted())
                    .font(theme.font(.title, weight: .bold))
                    .foregroundStyle(theme.textPrimary)
                Text(unit.abbreviation.uppercased())
                    .font(theme.font(.caption, weight: .bold))
                    .foregroundStyle(theme.textSecondary)
                    .tracking(1)

                Spacer()

                Button {
                    showingUpdate = true
                } label: {
                    Text("odometer.update")
                        .font(theme.font(.caption, weight: .bold))
                        .textCase(.uppercase)
                        .tracking(1.5)
                        .foregroundStyle(theme.backgroundPrimary)
                        .padding(.horizontal, DKSpacing.md)
                        .frame(minHeight: 36)
                        .background(theme.accent)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("odometer.update")
            }
        }
        .padding(DKSpacing.md)
        .brutalistBorder(color: theme.borderSubtle, lineWidth: 2)
    }

    @ViewBuilder
    private func vehiclePicker(selected: SharedVehicleOdometer) -> some View {
        if store.vehicles.count > 1 {
            Menu {
                ForEach(store.vehicles) { vehicle in
                    Button {
                        store.selectedID = vehicle.id
                    } label: {
                        Text(vehicle.displayName)
                        if vehicle.id == selected.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            } label: {
                HStack(spacing: DKSpacing.xs) {
                    Text(selected.displayName)
                        .font(theme.font(.caption, weight: .bold))
                        .foregroundStyle(theme.textPrimary)
                        .textCase(.uppercase)
                        .tracking(1)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(theme.textSecondary)
                }
            }
            .accessibilityIdentifier("odometer.vehicle-picker")
        } else {
            Text(selected.displayName)
                .font(theme.font(.caption, weight: .bold))
                .foregroundStyle(theme.textPrimary)
                .textCase(.uppercase)
                .tracking(1)
        }
    }
}
