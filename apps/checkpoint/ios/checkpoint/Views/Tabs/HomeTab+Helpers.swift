//
//  HomeTab+Helpers.swift
//  checkpoint
//
//  Helper methods extracted from HomeTab
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
        appState.seasonalPrefill = reminder.toPrefill()
        appState.showAddService = true
        refreshSeasonalReminders()
    }

    func dismissSeasonalReminder(_ reminder: SeasonalReminder) {
        let year = Calendar.current.component(.year, from: Date())
        SeasonalSettings.shared.dismissForYear(reminder.id, year: year)
        withAnimation(.easeOut(duration: Theme.animationMedium)) {
            refreshSeasonalReminders()
        }
    }

    // MARK: - Mileage

    /// Manual entry is an authoritative statement about the odometer *right
    /// now*, so it commits directly rather than going through
    /// `MileageCommit.commitIfNewest` — the user must be able to correct a
    /// too-high reading downward, which a newest-and-higher gate would block.
    /// Only readings derived as a side effect of logging a service are gated.
    func updateMileage(_ newMileage: Int, for vehicle: Vehicle) {
        // Was a hand-rolled duplicate of `recordMileage`, which meant two
        // implementations of the same commit could drift apart.
        vehicle.recordMileage(newMileage, source: .manual, in: modelContext)

        // Force immediate save to trigger SwiftUI observation for dependent views
        try? modelContext.save()

        // Update app icon based on new mileage affecting service status
        AppIconService.shared.updateIcon(for: vehicle, services: services)

        // Reschedule mileage reminder for 14 days from now
        NotificationService.shared.scheduleMileageReminder(for: vehicle, lastUpdateDate: .now)

        // Reschedule service notifications with updated pace data
        NotificationService.shared.rescheduleNotifications(for: vehicle)
    }

    // MARK: - Activity Row

    /// Recent activity uses the shared `ServiceEventRow`, so it can no longer
    /// disagree with the Services tab's history rows or the Costs tab's expense
    /// rows on hierarchy, date format, or cost styling — which it previously did
    /// (this row rendered cost at brutalistBody while ExpenseRow used
    /// brutalistHeading for the same value).
    func activityRow(log: ServiceLog) -> some View {
        let name = log.service?.name ?? L10n.rowServiceFallback
        let date = Formatters.shortDate.string(from: log.performedDate)

        return ServiceEventRow(
            indicator: .completed(),
            title: name,
            metadata: [.detail(date)],
            amount: log.formattedCost.map { .init(text: $0, color: Theme.accent) },
            accessibilityLabelText: L10n.rowCompletedAccessibility(name, date),
            onTap: { appState.selectedServiceLog = log }
        )
    }
}
