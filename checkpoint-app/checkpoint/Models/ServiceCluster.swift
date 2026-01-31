//
//  ServiceCluster.swift
//  checkpoint
//
//  Model representing a cluster of services due around the same time
//

import Foundation

/// A cluster of services that can be bundled together for a single shop visit
struct ServiceCluster: Identifiable {
    let id: UUID
    let services: [Service]
    let anchorService: Service  // Most urgent service (determines timing)
    let vehicle: Vehicle
    let mileageWindow: Int      // Window used for clustering
    let daysWindow: Int         // Window used for clustering

    init(
        id: UUID = UUID(),
        services: [Service],
        anchorService: Service,
        vehicle: Vehicle,
        mileageWindow: Int,
        daysWindow: Int
    ) {
        self.id = id
        self.services = services
        self.anchorService = anchorService
        self.vehicle = vehicle
        self.mileageWindow = mileageWindow
        self.daysWindow = daysWindow
    }

    /// Number of services in the cluster
    var serviceCount: Int { services.count }

    /// Suggested target mileage (from anchor service)
    var suggestedMileage: Int? { anchorService.dueMileage }

    /// Suggested target date (from anchor service)
    var suggestedDate: Date? { anchorService.dueDate }

    /// Most urgent status in the cluster (from anchor)
    var mostUrgentStatus: ServiceStatus {
        anchorService.status(currentMileage: vehicle.effectiveMileage)
    }

    /// Total estimated cost if available
    var totalEstimatedCost: Decimal? {
        // Future: sum estimated costs when that field is added
        nil
    }

    /// Cluster urgency score (same as anchor)
    var clusterUrgencyScore: Int {
        anchorService.urgencyScore(
            currentMileage: vehicle.effectiveMileage,
            dailyPace: vehicle.dailyMilesPace
        )
    }

    /// Human-readable window description
    var windowDescription: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let formatted = formatter.string(from: NSNumber(value: mileageWindow)) ?? "\(mileageWindow)"
        return "\(formatted) MI"
    }

    /// Content hash for dismissal tracking - stable across different orderings
    var contentHash: String {
        services
            .map { $0.id.uuidString }
            .sorted()
            .joined(separator: "-")
    }
}
