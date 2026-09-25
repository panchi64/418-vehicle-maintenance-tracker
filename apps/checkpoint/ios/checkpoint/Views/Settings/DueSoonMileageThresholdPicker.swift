//
//  DueSoonMileageThresholdPicker.swift
//  checkpoint
//
//  Picker view for selecting the "due soon" mileage threshold
//

import SwiftUI

struct DueSoonMileageThresholdPicker: View {
    @State private var selectedThreshold: Int = DueSoonSettings.shared.mileageThreshold

    var body: some View {
        SettingsPickerScreen(
            title: L10n.dueSoonMileageTitle,
            caption: L10n.dueSoonMileageDesc
        ) {
            SettingsOptionList(
                options: DueSoonSettings.mileageOptions,
                selection: selectedThreshold,
                title: { L10n.settingsDistanceValue($0) },
                subtitle: { $0 == 750 ? L10n.dueSoonDefault : nil }
            ) { option in
                HapticService.shared.selectionChanged()
                selectedThreshold = option
                DueSoonSettings.shared.mileageThreshold = option
            }
        }
    }
}

#Preview {
    NavigationStack {
        DueSoonMileageThresholdPicker()
    }
    .preferredColorScheme(.dark)
}
