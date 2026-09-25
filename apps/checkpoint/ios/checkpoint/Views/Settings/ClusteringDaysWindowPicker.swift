//
//  ClusteringDaysWindowPicker.swift
//  checkpoint
//
//  Picker for selecting service clustering days window
//

import SwiftUI

struct ClusteringDaysWindowPicker: View {
    @State private var selectedWindow: Int = ClusteringSettings.shared.daysWindow

    var body: some View {
        SettingsPickerScreen(
            title: L10n.settingsDaysWindow,
            caption: L10n.settingsDaysWindowDesc
        ) {
            SettingsOptionList(
                options: ClusteringSettings.daysWindowOptions,
                selection: selectedWindow,
                title: { L10n.settingsDaysCount($0) },
                subtitle: { $0 == 30 ? L10n.dueSoonDefault : nil }
            ) { option in
                HapticService.shared.selectionChanged()
                selectedWindow = option
                ClusteringSettings.shared.daysWindow = option
            }
        }
    }
}

#Preview {
    NavigationStack {
        ClusteringDaysWindowPicker()
    }
    .preferredColorScheme(.dark)
}
