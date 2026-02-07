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
        ZStack {
            Theme.backgroundPrimary
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text("Choose the climate zone that best matches where you drive most often.")
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.horizontal, Spacing.screenHorizontal)

                VStack(spacing: 0) {
                    ForEach(ClimateZone.allCases, id: \.self) { zone in
                        zoneRow(for: zone)

                        if zone != ClimateZone.allCases.last {
                            Rectangle()
                                .fill(Theme.gridLine)
                                .frame(height: Theme.borderWidth)
                        }
                    }
                }
                .background(Theme.surfaceInstrument)
                .overlay(
                    Rectangle()
                        .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
                )
                .padding(.horizontal, Spacing.screenHorizontal)

                Spacer()
            }
            .padding(.top, Spacing.lg)
        }
        .navigationTitle("Climate Zone")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedZone) { _, newZone in
            Task { @MainActor in
                HapticService.shared.selectionChanged()
                SeasonalSettings.shared.climateZone = newZone
            }
        }
    }

    private func zoneRow(for zone: ClimateZone) -> some View {
        Button {
            selectedZone = zone
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(zone.displayName)
                        .font(.brutalistBody)
                        .foregroundStyle(Theme.textPrimary)

                    Text(zone.description)
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.textTertiary)
                }

                Spacer()

                if selectedZone == zone {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.accent)
                }
            }
            .padding(Spacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        ClimateZonePickerView()
    }
    .preferredColorScheme(.dark)
}
