//
//  ServiceClusteringService.swift
//  checkpoint
//
//  Detects service clusters for bundling opportunities
//

import Foundation

/// Service for detecting clusters of services that can be bundled together
struct ServiceClusteringService {

    /// Detect clusters from a vehicle's services
    /// - Parameters:
    ///   - vehicle: The vehicle whose services to cluster
    ///   - services: All services for the vehicle
    ///   - settings: Clustering settings
    /// - Returns: Array of clusters with 2+ services each
    @MainActor
    static func detectClusters(
        for vehicle: Vehicle,
        services: [Service],
        settings: ClusteringSettings
    ) -> [ServiceCluster] {
        // Bail early if clustering disabled
        guard settings.isEnabled else { return [] }

        let currentMileage = vehicle.effectiveMileage
        let dailyPace = vehicle.dailyMilesPace

        // Filter to actionable services only (overdue or due soon)
        let actionableServices = services.filter { service in
            let status = service.status(currentMileage: currentMileage)
            return status == .overdue || status == .dueSoon
        }

        // Need at least 2 services to form a cluster
        guard actionableServices.count >= settings.minimumClusterSize else { return [] }

        // Sort by urgency (most urgent first)
        let sortedServices = actionableServices.sorted {
            $0.urgencyScore(currentMileage: currentMileage, dailyPace: dailyPace) <
            $1.urgencyScore(currentMileage: currentMileage, dailyPace: dailyPace)
        }

        var clusters: [ServiceCluster] = []
        var assignedServiceIDs: Set<UUID> = []

        // Greedy clustering: start with most urgent, pull in nearby services
        for potentialAnchor in sortedServices {
            // Skip if already assigned to a cluster
            guard !assignedServiceIDs.contains(potentialAnchor.id) else { continue }

            // Find services within window of this potential anchor
            var clusterServices: [Service] = [potentialAnchor]

            for candidate in sortedServices {
                guard candidate.id != potentialAnchor.id,
                      !assignedServiceIDs.contains(candidate.id) else { continue }

                if isWithinWindow(
                    anchor: potentialAnchor,
                    candidate: candidate,
                    currentMileage: currentMileage,
                    dailyPace: dailyPace,
                    mileageWindow: settings.mileageWindow,
                    daysWindow: settings.daysWindow
                ) {
                    clusterServices.append(candidate)
                }
            }

            // Only create cluster if we have enough services
            if clusterServices.count >= settings.minimumClusterSize {
                let cluster = ServiceCluster(
                    services: clusterServices,
                    anchorService: potentialAnchor,
                    vehicle: vehicle,
                    mileageWindow: settings.mileageWindow,
                    daysWindow: settings.daysWindow
                )
                clusters.append(cluster)

                // Mark all services in this cluster as assigned
                for service in clusterServices {
                    assignedServiceIDs.insert(service.id)
                }
            }
        }

        return clusters
    }

    /// Check if a candidate service is within the clustering window of an anchor
    private static func isWithinWindow(
        anchor: Service,
        candidate: Service,
        currentMileage: Int,
        dailyPace: Double?,
        mileageWindow: Int,
        daysWindow: Int
    ) -> Bool {
        // Check mileage window (if both have mileage tracking)
        if let anchorMileage = anchor.dueMileage,
           let candidateMileage = candidate.dueMileage {
            let mileageDiff = abs(anchorMileage - candidateMileage)
            if mileageDiff <= mileageWindow {
                return true  // Within mileage window
            }
        }

        // Check date window (if both have date tracking)
        if let anchorDate = anchor.effectiveDueDate(currentMileage: currentMileage, dailyPace: dailyPace),
           let candidateDate = candidate.effectiveDueDate(currentMileage: currentMileage, dailyPace: dailyPace) {
            let calendar = Calendar.current
            let daysDiff = abs(calendar.dateComponents([.day], from: anchorDate, to: candidateDate).day ?? Int.max)
            if daysDiff <= daysWindow {
                return true  // Within days window
            }
        }

        // Fallback: check raw due dates if effective dates unavailable
        if let anchorDate = anchor.dueDate,
           let candidateDate = candidate.dueDate {
            let calendar = Calendar.current
            let daysDiff = abs(calendar.dateComponents([.day], from: anchorDate, to: candidateDate).day ?? Int.max)
            if daysDiff <= daysWindow {
                return true
            }
        }

        return false
    }

    /// Get the primary cluster for a vehicle (most urgent one)
    @MainActor
    static func primaryCluster(
        for vehicle: Vehicle,
        services: [Service],
        settings: ClusteringSettings
    ) -> ServiceCluster? {
        detectClusters(for: vehicle, services: services, settings: settings).first
    }

    // MARK: - Convenience Overloads (use shared settings)

    /// Detect clusters using shared settings
    @MainActor
    static func detectClusters(
        for vehicle: Vehicle,
        services: [Service]
    ) -> [ServiceCluster] {
        detectClusters(for: vehicle, services: services, settings: .shared)
    }

    /// Get primary cluster using shared settings
    @MainActor
    static func primaryCluster(
        for vehicle: Vehicle,
        services: [Service]
    ) -> ServiceCluster? {
        primaryCluster(for: vehicle, services: services, settings: .shared)
    }
}
