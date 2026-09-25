//
//  HomeTab+Helpers.swift
//  checkpoint
//
//  Suggestion-slot state (cluster + seasonal) and the Recent row.
//

import SwiftUI
import SwiftData

extension HomeTab {
    // MARK: - Cluster Management

    func detectClusters() {
        guard let vehicle = appState.selectedVehicle else {
            primaryCluster = nil
            return
        }
        primaryCluster = ServiceClusteringService.primaryCluster(
            for: vehicle,
            services: vehicleServices
        )
    }

    func dismissCluster(_ cluster: ServiceCluster) {
        dismissedClusterHashes.insert(cluster.contentHash)
        saveDismissedClusters()
    }

    func loadDismissedClusters() {
        dismissedClusterHashes = Set(
            dismissedClusterHashesStorage
                .split(separator: ",")
                .map(String.init)
        )
    }

    func saveDismissedClusters() {
        dismissedClusterHashesStorage = dismissedClusterHashes.joined(separator: ",")
    }

    // MARK: - Seasonal Reminders

    func refreshSeasonalReminders() {
        let zone = SeasonalSettings.shared.climateZone
        activeSeasonalReminders = SeasonalReminder.activeReminders(for: zone, on: Date())
    }

    func scheduleSeasonalService(_ reminder: SeasonalReminder) {
        let year = Calendar.current.component(.year, from: Date())
        SeasonalSettings.shared.dismissForYear(reminder.id, year: year)
        appState.present(.addService(seasonal: reminder.toPrefill()))
        refreshSeasonalReminders()
    }

    func dismissSeasonalReminder(_ reminder: SeasonalReminder) {
        let year = Calendar.current.component(.year, from: Date())
        SeasonalSettings.shared.dismissForYear(reminder.id, year: year)
        refreshSeasonalRemindersAnimated()
    }

    func suppressSeasonalReminder(_ reminder: SeasonalReminder) {
        SeasonalSettings.shared.suppressPermanently(reminder.id)
        refreshSeasonalRemindersAnimated()
    }

    private func refreshSeasonalRemindersAnimated() {
        withAnimation(.easeOut(duration: Theme.animationMedium)) {
            refreshSeasonalReminders()
        }
    }

    // MARK: - Suggestion slot

    func suggestionView(_ suggestion: HomeSuggestion) -> some View {
        switch suggestion {
        case .cluster(let cluster):
            return HomeSuggestionView(
                suggestion: suggestion,
                onAccept: {
                    AnalyticsService.shared.capture(.serviceClusterTapped)
                    appState.present(.clusterDetail(cluster))
                },
                onDismiss: {
                    withAnimation(.easeOut(duration: Theme.animationMedium)) {
                        dismissCluster(cluster)
                    }
                }
            )
        case .seasonal(let reminder):
            return HomeSuggestionView(
                suggestion: suggestion,
                onAccept: { scheduleSeasonalService(reminder) },
                onDismiss: { dismissSeasonalReminder(reminder) },
                onSuppress: { suppressSeasonalReminder(reminder) }
            )
        }
    }

    // MARK: - Activity Row

    /// Recent uses the shared `ServiceEventRow`, so it cannot disagree with the
    /// Services tab's history rows or the Costs tab's expense rows.
    func activityRow(log: ServiceLog) -> some View {
        let name = log.service?.name ?? L10n.rowServiceFallback
        let date = Formatters.shortDate.string(from: log.performedDate)

        return ServiceEventRow(
            indicator: .completed(),
            title: name,
            metadata: [.detail(date)],
            amount: log.formattedCost.map { .init(text: $0, color: Theme.accent) },
            // Spoken in full ("June 6, 2026"); the visible short date would
            // be read as numbers.
            accessibilityLabelText: L10n.rowCompletedAccessibility(name, L10n.spokenDate(log.performedDate)),
            onTap: { appState.push(.serviceLog(log)) }
        )
        .serviceLogDeleteMenu { ServiceLogDeleteAction.perform(log, offerUndo: true) }
    }
}
