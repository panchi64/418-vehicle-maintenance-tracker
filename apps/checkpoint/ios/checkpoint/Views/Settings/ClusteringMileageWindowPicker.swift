//
//  ClusteringMileageWindowPicker.swift
//  checkpoint
//
//  Picker for selecting service clustering mileage window
//

import SwiftUI

struct ClusteringMileageWindowPicker: View {
    @State private var selectedWindow: Int = ClusteringSettings.shared.mileageWindow

    var body: some View {
        SettingsPickerScreen(
            title: L10n.settingsMileageWindow,
            caption: L10n.settingsMileageWindowDesc
        ) {
            SettingsOptionList(
                options: ClusteringSettings.mileageWindowOptions,
                selection: selectedWindow,
                title: { L10n.settingsDistanceValue($0) },
                subtitle: { $0 == 1000 ? L10n.dueSoonDefault : nil }
            ) { option in
                HapticService.shared.selectionChanged()
                selectedWindow = option
                ClusteringSettings.shared.mileageWindow = option
            }
        }
    }
}

#Preview {
    NavigationStack {
        ClusteringMileageWindowPicker()
    }
    .preferredColorScheme(.dark)
}
