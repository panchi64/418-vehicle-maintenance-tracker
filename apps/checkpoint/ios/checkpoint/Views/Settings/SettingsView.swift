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

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        // DISPLAY — most commonly adjusted
                        displaySection

                        // REMINDERS — notification thresholds and seasonal alerts
                        remindersSection

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

                        Spacer()
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
        }
    }

    // MARK: - Display Section

    private var displaySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(L10n.settingsDisplay)
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(2)

            VStack(spacing: 0) {
                // Theme
                NavigationLink {
                    ThemePickerView()
                } label: {
                    settingRow(
                        title: "Theme",
                        value: ThemeManager.shared.current.displayName
                    )
                }
                .buttonStyle(.plain)

                Rectangle()
                    .fill(Theme.gridLine)
                    .frame(height: Theme.borderWidth)

                // Distance Unit
                NavigationLink {
                    DistanceUnitPickerView()
                } label: {
                    settingRow(
                        title: L10n.settingsDistanceUnit,
                        value: DistanceSettings.shared.unit.displayName
                    )
                }
                .buttonStyle(.plain)

                Rectangle()
                    .fill(Theme.gridLine)
                    .frame(height: Theme.borderWidth)

                // Mileage Estimation
                MileageEstimatesToggle()

                Rectangle()
                    .fill(Theme.gridLine)
                    .frame(height: Theme.borderWidth)

                // App Icon Auto-change (moved from Alerts — it's a display preference)
                AppIconToggle()
            }
            .background(Theme.surfaceInstrument)
            .brutalistBorder()
        }
    }

    // MARK: - Reminders Section

    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(L10n.settingsReminders)
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(2)

            VStack(spacing: 0) {
                // Due Soon Mileage Threshold
                NavigationLink {
                    DueSoonMileageThresholdPicker()
                } label: {
                    settingRow(
                        title: L10n.settingsDueSoonMileage,
                        value: "\(Formatters.mileageNumber(DueSoonSettings.shared.mileageThreshold)) \(DistanceSettings.shared.unit.abbreviation)"
                    )
                }
                .buttonStyle(.plain)

                Rectangle()
                    .fill(Theme.gridLine)
                    .frame(height: Theme.borderWidth)

                // Due Soon Days Threshold
                NavigationLink {
                    DueSoonDaysThresholdPicker()
                } label: {
                    settingRow(
                        title: L10n.settingsDueSoonDays,
                        value: "\(DueSoonSettings.shared.daysThreshold) \(L10n.commonDays)"
                    )
                }
                .buttonStyle(.plain)

                Rectangle()
                    .fill(Theme.gridLine)
                    .frame(height: Theme.borderWidth)

                // Seasonal Alerts Toggle
                SeasonalRemindersToggle()

                Rectangle()
                    .fill(Theme.gridLine)
                    .frame(height: Theme.borderWidth)

                // Climate Zone Picker (only active when Seasonal Alerts is on)
                NavigationLink {
                    ClimateZonePickerView()
                } label: {
                    settingRow(
                        title: "Climate Zone",
                        value: SeasonalSettings.shared.climateZone?.displayName ?? "Not Set"
                    )
                }
                .buttonStyle(.plain)
                .disabled(!SeasonalSettings.shared.isEnabled)
                .opacity(SeasonalSettings.shared.isEnabled ? 1.0 : 0.5)
            }
            .background(Theme.surfaceInstrument)
            .brutalistBorder()
        }
    }

    // MARK: - Smart Features Section

    private var smartFeaturesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(L10n.settingsSmartFeatures)
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(2)

            VStack(spacing: 0) {
                // Service Bundling Toggle
                ServiceBundlingToggle()

                Rectangle()
                    .fill(Theme.gridLine)
                    .frame(height: Theme.borderWidth)

                // Mileage Window (only active when Service Bundling is on)
                NavigationLink {
                    ClusteringMileageWindowPicker()
                } label: {
                    settingRow(
                        title: L10n.settingsMileageWindow,
                        value: "\(Formatters.mileageNumber(ClusteringSettings.shared.mileageWindow)) \(DistanceSettings.shared.unit.abbreviation)"
                    )
                }
                .buttonStyle(.plain)
                .disabled(!ClusteringSettings.shared.isEnabled)
                .opacity(ClusteringSettings.shared.isEnabled ? 1.0 : 0.5)

                Rectangle()
                    .fill(Theme.gridLine)
                    .frame(height: Theme.borderWidth)

                // Days Window (only active when Service Bundling is on)
                NavigationLink {
                    ClusteringDaysWindowPicker()
                } label: {
                    settingRow(
                        title: L10n.settingsDaysWindow,
                        value: "\(ClusteringSettings.shared.daysWindow) \(L10n.commonDays)"
                    )
                }
                .buttonStyle(.plain)
                .disabled(!ClusteringSettings.shared.isEnabled)
                .opacity(ClusteringSettings.shared.isEnabled ? 1.0 : 0.5)
            }
            .background(Theme.surfaceInstrument)
            .brutalistBorder()
        }
    }

    // MARK: - Data Section

    @State private var showCSVImport = false

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("DATA & SYNC")
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.textTertiary)
                    .tracking(2)

                VStack(spacing: 0) {
                    Button {
                        showCSVImport = true
                    } label: {
                        HStack {
                            Text("Import Service History")
                                .font(.brutalistBody)
                                .foregroundStyle(Theme.textPrimary)

                            Spacer()

                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Theme.textTertiary)
                        }
                        .padding(Spacing.md)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .background(Theme.surfaceInstrument)
                .brutalistBorder()
            }

            SyncSettingsSection()
        }
        .sheet(isPresented: $showCSVImport) {
            CSVImportView()
        }
    }

    // MARK: - Support Section

    private var supportSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("SUPPORT")
                .font(.brutalistLabel)
                .foregroundStyle(Theme.accent)
                .tracking(2)

            VStack(spacing: 0) {
                NavigationLink {
                    TipJarView()
                        .environment(appState)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Support Checkpoint")
                                .font(.brutalistBody)
                                .foregroundStyle(Theme.textPrimary)
                            Text("Every tip unlocks a rare theme")
                                .font(.brutalistLabel)
                                .foregroundStyle(Theme.textTertiary)
                        }
                        Spacer()
                        Image(systemName: "heart.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.accent)
                    }
                    .padding(Spacing.md)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Rectangle()
                    .fill(Theme.gridLine)
                    .frame(height: Theme.borderWidth)

                Button {
                    Task { await StoreManager.shared.restorePurchases() }
                } label: {
                    HStack {
                        Text("Restore Purchases")
                            .font(.brutalistBody)
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    .padding(Spacing.md)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .background(Theme.surfaceInstrument)
            .overlay(
                Rectangle()
                    .strokeBorder(Theme.accent, lineWidth: Theme.borderWidth)
            )
        }
    }

    // MARK: - Privacy Section

    private var privacySection: some View {
        AnalyticsSettingsSection(sectionTitle: L10n.settingsPrivacy)
    }

    // MARK: - Debug Section

    #if DEBUG
    @State private var showTipModal = false

    private var debugSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("DEBUG")
                .font(.brutalistLabel)
                .foregroundStyle(Theme.statusOverdue)
                .tracking(2)

            VStack(spacing: 0) {
                Button {
                    OnboardingState.hasCompletedOnboarding = false
                    onboardingState?.currentPhase = .intro
                    dismiss()
                } label: {
                    HStack {
                        Text("Replay Onboarding")
                            .font(.brutalistBody)
                            .foregroundStyle(Theme.textPrimary)

                        Spacer()

                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    .padding(Spacing.md)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Rectangle()
                    .fill(Theme.gridLine)
                    .frame(height: Theme.borderWidth)

                Button {
                    showTipModal = true
                } label: {
                    HStack {
                        Text("Show Tip Prompt")
                            .font(.brutalistBody)
                            .foregroundStyle(Theme.textPrimary)

                        Spacer()

                        Image(systemName: "heart")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    .padding(Spacing.md)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $showTipModal) {
                    TipModalView()
                        .environment(appState)
                }

                Rectangle()
                    .fill(Theme.gridLine)
                    .frame(height: Theme.borderWidth)

                Button {
                    Task {
                        let center = UNUserNotificationCenter.current()
                        let content = UNMutableNotificationContent()
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
                        let pick = messages.randomElement()!
                        content.title = pick.title
                        content.body = pick.body
                        content.sound = .default
                        content.categoryIdentifier = NotificationService.serviceDueCategoryID
                        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
                        let request = UNNotificationRequest(identifier: "debug-test-notification", content: content, trigger: trigger)
                        try? await center.add(request)
                    }
                } label: {
                    HStack {
                        Text("Fire Test Notification (3s)")
                            .font(.brutalistBody)
                            .foregroundStyle(Theme.textPrimary)

                        Spacer()

                        Image(systemName: "bell")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    .padding(Spacing.md)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .background(Theme.surfaceInstrument)
            .brutalistBorder()
        }
    }
    #endif

    private func settingRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.brutalistBody)
                .foregroundStyle(Theme.textPrimary)

            Spacer()

            Text(value)
                .font(.brutalistSecondary)
                .foregroundStyle(Theme.textTertiary)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)
                .accessibilityHidden(true)
        }
        .padding(Spacing.md)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    SettingsView()
        .environment(AppState())
        .preferredColorScheme(.dark)
}
