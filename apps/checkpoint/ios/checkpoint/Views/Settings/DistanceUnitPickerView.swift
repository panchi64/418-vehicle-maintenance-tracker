//
//  DistanceUnitPickerView.swift
//  checkpoint
//
//  Picker view for selecting distance unit (miles/kilometers)
//

import SwiftUI

struct DistanceUnitPickerView: View {
    @State private var selectedUnit: DistanceUnit = DistanceSettings.shared.unit

    var body: some View {
        SettingsPickerScreen(title: L10n.distanceUnitTitle) {
            SettingsOptionList(
                options: DistanceUnit.allCases,
                selection: selectedUnit,
                title: { $0.displayName },
                subtitle: { $0 == .miles ? L10n.distanceMilesDefault : L10n.distanceKilometersAbbr }
            ) { unit in
                HapticService.shared.selectionChanged()
                selectedUnit = unit
                DistanceSettings.shared.unit = unit
            }
        }
    }
}

#Preview {
    NavigationStack {
        DistanceUnitPickerView()
    }
    .preferredColorScheme(.dark)
}
