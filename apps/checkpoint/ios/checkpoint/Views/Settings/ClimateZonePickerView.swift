//
//  ClimateZonePickerView.swift
//  checkpoint
//
//  Picker view for selecting climate zone used in seasonal reminders
//

import SwiftUI

struct ClimateZonePickerView: View {
    @State private var selectedZone: ClimateZone? = SeasonalSettings.shared.climateZone

    var body: some View {
        SettingsPickerScreen(
            title: L10n.settingsClimateZone,
            caption: L10n.settingsClimateZoneDesc
        ) {
            SettingsOptionList(
                options: ClimateZone.allCases,
                selection: selectedZone,
                title: { $0.displayName },
                subtitle: { $0.description }
            ) { zone in
                HapticService.shared.selectionChanged()
                selectedZone = zone
                SeasonalSettings.shared.climateZone = zone
            }
        }
    }
}

#Preview {
    NavigationStack {
        ClimateZonePickerView()
    }
    .preferredColorScheme(.dark)
}
