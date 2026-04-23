import SwiftUI
import DesignKit
import Localization

struct FuelSettingsView: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(BiomboAppState.self) private var appState

    var body: some View {
        @Bindable var state = appState

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DKSpacing.lg) {
                    DesignKit.SectionHeader(
                        title: String(localized: "settings.section.units"),
                        labelColor: theme.textTertiary,
                        dividerColor: theme.gridLine,
                        dividerHeight: 2,
                        labelFont: theme.font(.caption, weight: .semibold)
                    )

                    Picker("settings.volume_unit", selection: $state.volumeUnit) {
                        ForEach(VolumeUnit.allCases) { unit in
                            Text(unit.label).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)

                    DesignKit.SectionHeader(
                        title: String(localized: "settings.section.about"),
                        labelColor: theme.textTertiary,
                        dividerColor: theme.gridLine,
                        dividerHeight: 2,
                        labelFont: theme.font(.caption, weight: .semibold)
                    )

                    DesignKit.DataRow(
                        label: String(localized: "settings.about.version"),
                        value: Bundle.appVersion,
                        labelColor: theme.textTertiary,
                        valueColor: theme.textPrimary,
                        labelFont: theme.font(.caption, weight: .semibold),
                        valueFont: theme.font(.body)
                    )
                }
                .padding(DKSpacing.md)
            }
            .background(theme.backgroundPrimary.ignoresSafeArea())
            .navigationTitle(Text("settings.title"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Shared.Action.done) { dismiss() }
                }
            }
        }
    }
}
