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

    func updateMileage(_ newMileage: Int, for vehicle: Vehicle) {
        vehicle.currentMileage = newMileage
        vehicle.mileageUpdatedAt = .now

        let shouldCreateSnapshot = !MileageSnapshot.hasSnapshotToday(
            snapshots: vehicle.mileageSnapshots ?? []
        )

        if shouldCreateSnapshot {
            let snapshot = MileageSnapshot(
                vehicle: vehicle,
                mileage: newMileage,
                recordedAt: .now,
                source: .manual
            )
            modelContext.insert(snapshot)
        }

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

    func activityRow(log: ServiceLog) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Theme.statusGood)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(log.service?.name ?? "Service")
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)

                Text(Formatters.shortDate.string(from: log.performedDate))
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textTertiary)
            }

            Spacer()

            if let cost = log.formattedCost {
                Text(cost)
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.accent)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(Spacing.md)
        .contentShape(Rectangle())
    }
}
