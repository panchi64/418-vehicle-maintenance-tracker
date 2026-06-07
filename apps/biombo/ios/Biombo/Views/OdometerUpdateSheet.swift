import SwiftUI
import DesignKit
import Localization
import VehicleSharing

/// Sheet for entering a new odometer reading that gets queued for Checkpoint.
struct OdometerUpdateSheet: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(OdometerStore.self) private var store

    let vehicle: SharedVehicleOdometer

    @State private var reading: Int?
    @FocusState private var fieldFocused: Bool

    private var unit: SharedDistanceUnit { vehicle.distanceUnit }

    /// Current displayed value, in the vehicle's unit.
    private var currentDisplay: Int { unit.fromMiles(vehicle.displayMileage) }

    private var isValid: Bool {
        guard let reading else { return false }
        return reading >= currentDisplay
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: DKSpacing.lg) {
                DataRow(
                    label: String(localized: "odometer.current"),
                    value: "\(currentDisplay.formatted()) \(unit.abbreviation.uppercased())",
                    labelColor: theme.textTertiary,
                    valueColor: theme.textPrimary,
                    labelFont: theme.font(.caption, weight: .semibold),
                    valueFont: theme.font(.body, weight: .bold)
                )

                VStack(alignment: .leading, spacing: DKSpacing.sm) {
                    Text("odometer.reading")
                        .font(theme.font(.caption, weight: .semibold))
                        .foregroundStyle(theme.textTertiary)
                        .textCase(.uppercase)
                        .tracking(1.5)

                    HStack(spacing: DKSpacing.sm) {
                        TextField("0", value: $reading, format: .number)
                            .keyboardType(.numberPad)
                            .focused($fieldFocused)
                            .font(theme.font(.title2, weight: .bold))
                            .foregroundStyle(theme.textPrimary)

                        Text(unit.abbreviation.uppercased())
                            .font(theme.font(.body, weight: .bold))
                            .foregroundStyle(theme.textSecondary)
                    }
                    .padding(DKSpacing.sm)
                    .brutalistBorder(color: theme.borderSubtle, lineWidth: 2)
                }

                Text("odometer.sync_note")
                    .font(theme.font(.caption))
                    .foregroundStyle(theme.textSecondary)

                Spacer()
            }
            .padding(DKSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.backgroundPrimary.ignoresSafeArea())
            .navigationTitle(Text("odometer.update.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Shared.Action.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Shared.Action.save) {
                        if let reading { store.submit(displayValue: reading, for: vehicle) }
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear { fieldFocused = true }
        }
    }
}
