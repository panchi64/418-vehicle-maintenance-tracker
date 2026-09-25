//
//  SettingsView.swift
//  checkpoint
//
//  Settings screen organized by: Display, Reminders, Smart Features, Data & Sync, Privacy
//

import SwiftUI
import SwiftData
#if DEBUG
import UserNotifications
#endif

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    var onboardingState: OnboardingState?
    /// Replays the tour without re-running the intro/preferences flow.
    /// Owned by ContentView because seeding sample data requires the
    /// SwiftData query context that lives there.
    var onReplayTour: (() -> Void)?

    @State private var showRecallSheet = false
    @State private var showCSVImport = false

    var body: some View {
        @Bindable var appState = appState
        return NavigationStack {
            ZStack {
                Theme.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        // DISPLAY — most commonly adjusted
                        displaySection

                        // REMINDERS — notification thresholds and seasonal alerts
                        remindersSection

                        // SAFETY — recalls (per current vehicle)
                        safetySection

                        // SMART FEATURES — service bundling
                        smartFeaturesSection

                        // DATA & SYNC — rarely changed after setup
                        dataSection

                        // SUPPORT
                        supportSection

                        // PRIVACY — analytics opt-out
                        privacySection

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
            .sheet(isPresented: $appState.showProPaywall) {
                ProPaywallSheet()
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

    // MARK: - Display Section

    private var displaySection: some View {
        SettingsGroup(title: L10n.settingsDisplay) {
            NavigationLink {
                ThemePickerView()
            } label: {
                SettingsValueRow(
                    title: L10n.settingsTheme,
                    value: ThemeManager.shared.current.displayName
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

            // App Icon Auto-change (moved from Alerts — it's a display preference)
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

    // MARK: - Reminders Section

    private var remindersSection: some View {
        SettingsGroup(title: L10n.settingsReminders) {
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

    // MARK: - Safety Section

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

    // MARK: - Smart Features Section

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

    // MARK: - Data Section

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            SettingsGroup(title: L10n.settingsDataSync) {
                SettingsActionRow(
                    title: L10n.settingsImportHistory,
                    systemImage: "square.and.arrow.down",
                    iconColor: Theme.textTertiary
                ) {
                    showCSVImport = true
                }
            }

            SyncSettingsSection()
        }
    }

    // MARK: - Support Section

    private var supportSection: some View {
        SettingsGroup(title: L10n.settingsSupport, titleColor: Theme.accent, borderColor: Theme.accent) {
            NavigationLink {
                TipJarView()
                    .environment(appState)
            } label: {
                SettingsRowLabel(
                    title: L10n.tipSupportCheckpoint,
                    subtitle: L10n.tipEveryTipUnlocks,
                    systemImage: "heart.fill"
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
                Task { await StoreManager.shared.restorePurchases() }
            }

            SettingsRowDivider()

            SettingsActionRow(
                title: L10n.settingsFindGasPrices,
                subtitle: L10n.settingsFindGasPricesDesc,
                systemImage: "fuelpump.fill"
            ) {
                CompanionAppLauncher.openBiombo()
            }
        }
    }

    // MARK: - Privacy Section

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

    // MARK: - Debug Section

    #if DEBUG
    @State private var showTipModal = false

    // Developer-only rows: English, never localized.
    private var debugSection: some View {
        SettingsGroup(title: "DEBUG", titleColor: Theme.statusOverdue) {
            SettingsActionRow(
                title: "Replay Onboarding",
                systemImage: "arrow.counterclockwise",
                iconColor: Theme.textTertiary
            ) {
                onboardingState?.replayOnboarding()
                dismiss()
            }

            SettingsRowDivider()

            SettingsActionRow(
                title: "Show Tip Prompt",
                systemImage: "heart",
                iconColor: Theme.textTertiary
            ) {
                showTipModal = true
            }
            .sheet(isPresented: $showTipModal) {
                TipModalView()
                    .environment(appState)
            }

            SettingsRowDivider()

            SettingsActionRow(
                title: "Fire Test Notification (3s)",
                systemImage: "bell",
                iconColor: Theme.textTertiary
            ) {
                Task { await Self.fireTestNotification() }
            }
        }
    }

    private static func fireTestNotification() async {
        let messages: [(title: String, body: String)] = [
            ("Odometer Sync Requested", "It's been a while. How far have we gone?"),
            ("Marbete Status: 30 Days", "Would prefer not to be impounded."),
            ("Marbete Status: 7 Days", "Starting to worry about that marbete."),
            ("Marbete Status: URGENT", "Expires tomorrow. Legally speaking."),
            ("Oil Change Due in 1 Week", "The oil is aging. So are we all."),
            ("Tire Rotation Reminder", "The tires asked me to ask you."),
            ("Brake Inspection Due", "Stopping is optional. Until it isn't."),
            ("Coolant Flush Due Soon", "Running a little warm. Thought you should know."),
            ("2025 Expense Report", "You spent a lot last year. You're welcome."),
            ("Marbete Status: 60 Days", "Requesting registration renewal. No rush. Yet."),
        ]
        guard let pick = messages.randomElement() else { return }
        let content = UNMutableNotificationContent()
        content.title = pick.title
        content.body = pick.body
        content.sound = .default
        content.categoryIdentifier = NotificationService.serviceDueCategoryID
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        let request = UNNotificationRequest(identifier: "debug-test-notification", content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }
    #endif
}

#Preview {
    SettingsView()
        .environment(AppState())
        .preferredColorScheme(.dark)
}
