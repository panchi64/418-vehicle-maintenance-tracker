//
//  SettingsView.swift
//  checkpoint
//
//  Switchboard: independent, equal-weight rows in system-style grouped
//  sections. Order runs from what is adjusted most (Display, Reminders) to
//  what is set once (Data, Privacy). Support comes last and looks like every
//  other group — nothing here may out-rank the functional settings.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AppState.self) var appState
    var onboardingState: OnboardingState?
    /// Replays the tour without re-running the intro/preferences flow.
    /// Owned by ContentView because seeding sample data requires the
    /// SwiftData query context that lives there.
    var onReplayTour: (() -> Void)?

    @State private var showRecallSheet = false
    @State private var showCSVImport = false
    #if DEBUG
    @State var showTipModal = false
    #endif

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.xl) {
                        displaySection
                        remindersSection
                        safetySection
                        smartFeaturesSection
                        dataSection
                        SyncSettingsSection()
                        privacySection
                        supportSection

                        #if DEBUG
                        debugSection
                        #endif
                    }
                    .padding(Spacing.screenHorizontal)
                    .padding(.top, Spacing.lg)
                }
            }
            .trackScreen(.settings)
            .navigationTitle(L10n.settingsTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.commonDone) { dismiss() }
                        .toolbarButtonStyle()
                }
            }
            .sheet(isPresented: $showRecallSheet) {
                if let vehicle = appState.selectedVehicle {
                    RecallSheetView(vehicle: vehicle, recalls: appState.currentRecalls)
                }
            }
            .sheet(isPresented: $showCSVImport) {
                CSVImportView()
            }
        }
    }

    // MARK: - Display

    private var displaySection: some View {
        SettingsGroup(title: L10n.settingsDisplay) {
            NavigationLink {
                ThemePickerView()
            } label: {
                let theme = ThemeManager.shared.current
                SettingsValueRow(
                    title: L10n.settingsTheme,
                    value: theme.displayName,
                    swatch: theme.previewColors.map { Color(hex: $0) }
                )
            }
            .buttonStyle(.plain)

            SettingsRowDivider()

            NavigationLink {
                DistanceUnitPickerView()
            } label: {
                SettingsValueRow(
                    title: L10n.settingsDistanceUnit,
                    value: DistanceSettings.shared.unit.displayName
                )
            }
            .buttonStyle(.plain)

            SettingsRowDivider()

            SettingToggle(
                title: L10n.settingsMileageEstimation,
                subtitle: L10n.settingsMileageEstimationDesc,
                read: { MileageEstimateSettings.shared.showEstimates },
                write: { MileageEstimateSettings.shared.showEstimates = $0 }
            )

            SettingsRowDivider()

            SettingToggle(
                title: L10n.settingsAutomaticIcon,
                subtitle: L10n.settingsAutomaticIconDesc,
                read: { AppIconSettings.shared.autoChangeEnabled },
                write: { isOn in
                    AppIconSettings.shared.autoChangeEnabled = isOn
                    if !isOn {
                        AppIconService.shared.resetToDefaultIcon()
                    }
                }
            )
        }
    }

    // MARK: - Reminders

    private var remindersSection: some View {
        SettingsGroup(title: L10n.settingsReminders) {
            // First: every threshold below is moot while this is off.
            SettingsNotificationRow()

            SettingsRowDivider()

            NavigationLink {
                DueSoonMileageThresholdPicker()
            } label: {
                SettingsValueRow(
                    title: L10n.settingsDueSoonMileage,
                    value: L10n.settingsDistanceValue(DueSoonSettings.shared.mileageThreshold)
                )
            }
            .buttonStyle(.plain)

            SettingsRowDivider()

            NavigationLink {
                DueSoonDaysThresholdPicker()
            } label: {
                SettingsValueRow(
                    title: L10n.settingsDueSoonDays,
                    value: L10n.settingsDaysCount(DueSoonSettings.shared.daysThreshold)
                )
            }
            .buttonStyle(.plain)

            SettingsRowDivider()

            SettingToggle(
                title: L10n.settingsSeasonalAlerts,
                subtitle: L10n.settingsSeasonalAlertsDesc,
                read: { SeasonalSettings.shared.isEnabled },
                write: { SeasonalSettings.shared.isEnabled = $0 }
            )

            SettingsRowDivider()

            // Climate Zone Picker (only active when Seasonal Alerts is on)
            NavigationLink {
                ClimateZonePickerView()
            } label: {
                SettingsValueRow(
                    title: L10n.settingsClimateZone,
                    value: SeasonalSettings.shared.climateZone?.displayName ?? L10n.settingsNotSet
                )
            }
            .buttonStyle(.plain)
            .disabled(!SeasonalSettings.shared.isEnabled)
            .opacity(SeasonalSettings.shared.isEnabled ? 1.0 : 0.5)
        }
    }

    // MARK: - Safety

    private var safetySection: some View {
        let recalls = appState.currentRecalls
        let hasRecalls = appState.selectedVehicle != nil && !recalls.isEmpty

        return SettingsGroup(title: L10n.settingsSafety) {
            Button {
                showRecallSheet = true
            } label: {
                SettingsValueRow(
                    title: L10n.recallSettingsRowTitle,
                    value: hasRecalls ? L10n.recallSettingsCount(recalls.count) : L10n.recallSettingsNoneOnFile
                )
            }
            .buttonStyle(.plain)
            .disabled(!hasRecalls)
            .opacity(hasRecalls ? 1.0 : 0.5)
        }
    }

    // MARK: - Smart Features

    private var smartFeaturesSection: some View {
        let bundlingEnabled = ClusteringSettings.shared.isEnabled

        return SettingsGroup(title: L10n.settingsSmartFeatures) {
            SettingToggle(
                title: L10n.settingsBundleSuggestions,
                subtitle: L10n.settingsBundleSuggestionsDesc,
                read: { ClusteringSettings.shared.isEnabled },
                write: { ClusteringSettings.shared.isEnabled = $0 }
            )

            SettingsRowDivider()

            // Windows only apply when Service Bundling is on
            NavigationLink {
                ClusteringMileageWindowPicker()
            } label: {
                SettingsValueRow(
                    title: L10n.settingsMileageWindow,
                    value: L10n.settingsDistanceValue(ClusteringSettings.shared.mileageWindow)
                )
            }
            .buttonStyle(.plain)
            .disabled(!bundlingEnabled)
            .opacity(bundlingEnabled ? 1.0 : 0.5)

            SettingsRowDivider()

            NavigationLink {
                ClusteringDaysWindowPicker()
            } label: {
                SettingsValueRow(
                    title: L10n.settingsDaysWindow,
                    value: L10n.settingsDaysCount(ClusteringSettings.shared.daysWindow)
                )
            }
            .buttonStyle(.plain)
            .disabled(!bundlingEnabled)
            .opacity(bundlingEnabled ? 1.0 : 0.5)
        }
    }

    // MARK: - Data

    private var dataSection: some View {
        SettingsGroup(title: L10n.settingsDataSync) {
            SettingsActionRow(
                title: L10n.settingsImportHistory,
                systemImage: "square.and.arrow.down",
                iconColor: Theme.textTertiary
            ) {
                showCSVImport = true
            }
        }
    }

    // MARK: - Privacy

    private var privacySection: some View {
        SettingsGroup(title: L10n.settingsPrivacy) {
            SettingToggle(
                title: L10n.settingsUsageAnalytics,
                subtitle: L10n.settingsUsageAnalyticsDesc,
                read: { AnalyticsSettings.shared.isEnabled },
                write: { AnalyticsService.shared.setEnabled($0) }
            )
        }
    }

    // MARK: - Support

    /// Plain like every other group: no accent border or accent title, and
    /// the heart icon in the same tertiary ink as the rest.
    private var supportSection: some View {
        SettingsGroup(title: L10n.settingsSupport) {
            NavigationLink {
                TipJarView()
                    .environment(appState)
            } label: {
                SettingsRowLabel(
                    title: L10n.tipSupportCheckpoint,
                    subtitle: L10n.tipEveryTipUnlocks,
                    systemImage: "chevron.right",
                    iconColor: Theme.textTertiary
                )
            }
            .buttonStyle(.plain)

            SettingsRowDivider()

            SettingsActionRow(
                title: L10n.settingsReplayTour,
                subtitle: L10n.settingsReplayTourDesc,
                systemImage: "play.circle",
                iconColor: Theme.textTertiary
            ) {
                onReplayTour?()
                dismiss()
            }

            SettingsRowDivider()

            SettingsActionRow(
                title: L10n.settingsRestorePurchases,
                systemImage: "arrow.counterclockwise",
                iconColor: Theme.textTertiary
            ) {
                Task { await RestorePurchasesAction.run() }
            }

            SettingsRowDivider()

            SettingsActionRow(
                title: L10n.settingsFindGasPrices,
                subtitle: L10n.settingsFindGasPricesDesc,
                systemImage: "fuelpump",
                iconColor: Theme.textTertiary
            ) {
                CompanionAppLauncher.openBiombo()
            }
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppState())
        .preferredColorScheme(.dark)
}
