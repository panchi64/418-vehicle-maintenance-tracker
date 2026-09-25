//
//  DueSoonDaysThresholdPicker.swift
//  checkpoint
//
//  Picker view for selecting the "due soon" days threshold
//

import SwiftUI

struct DueSoonDaysThresholdPicker: View {
    @State private var selectedThreshold: Int = DueSoonSettings.shared.daysThreshold

    var body: some View {
        SettingsPickerScreen(
            title: L10n.dueSoonDaysTitle,
            caption: L10n.dueSoonDaysDesc
        ) {
            SettingsOptionList(
                options: DueSoonSettings.daysOptions,
                selection: selectedThreshold,
                title: { L10n.settingsDaysCount($0) },
                subtitle: { $0 == 30 ? L10n.dueSoonDefault : nil }
            ) { option in
                HapticService.shared.selectionChanged()
                selectedThreshold = option
                DueSoonSettings.shared.daysThreshold = option
            }
        }
    }
}

#Preview {
    NavigationStack {
        DueSoonDaysThresholdPicker()
    }
    .preferredColorScheme(.dark)
}
