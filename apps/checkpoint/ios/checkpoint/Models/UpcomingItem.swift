//
//  UpcomingItem.swift
//  checkpoint
//
//  Protocol for items that can appear in "Next Up" displays (services, marbete, etc.)
//

import Foundation

/// Type of upcoming item for display differentiation
enum UpcomingItemType {
    case service
    case marbete
}

/// Protocol for items that can appear in "Next Up" displays
protocol UpcomingItem: Identifiable {
    var id: UUID { get }
    var itemName: String { get }
    var itemStatus: ServiceStatus { get }
    var daysRemaining: Int? { get }
    var urgencyScore: Int { get }
    var itemType: UpcomingItemType { get }
}

// MARK: - Marbete Upcoming Item

/// Wrapper for Vehicle's marbete data as an UpcomingItem
struct MarbeteUpcomingItem: UpcomingItem {
    let id: UUID
    let vehicle: Vehicle

    var itemName: String { L10n.descMarbeteRenewal }

    var itemStatus: ServiceStatus { vehicle.marbeteStatus }

    var daysRemaining: Int? { vehicle.daysUntilMarbeteExpiration }

    var urgencyScore: Int { vehicle.marbeteUrgencyScore }

    var itemType: UpcomingItemType { .marbete }

    /// Formatted expiration date
    var expirationFormatted: String? { vehicle.marbeteExpirationFormatted }

    init(vehicle: Vehicle) {
        self.id = UUID() // Generate unique ID for the wrapper
        self.vehicle = vehicle
    }
}

// MARK: - Service UpcomingItem Conformance

extension Service: UpcomingItem {
    var itemName: String { name }

    var itemStatus: ServiceStatus {
        guard let vehicle = vehicle else { return .neutral }
        return status(on: vehicle)
    }

    var daysRemaining: Int? {
        guard let vehicle = vehicle else { return nil }
        let pace = vehicle.dailyMilesPace
        guard let effectiveDate = effectiveDueDate(currentMileage: vehicle.effectiveMileage, dailyPace: pace) else {
            return nil
        }
        return Calendar.current.dateComponents([.day], from: .now, to: effectiveDate).day
    }

    var urgencyScore: Int {
        guard let vehicle = vehicle else { return Int.max }
        return urgencyScore(currentMileage: vehicle.effectiveMileage, dailyPace: vehicle.dailyMilesPace)
    }

    var itemType: UpcomingItemType { .service }
}

// MARK: - Vehicle Extension for Upcoming Items

extension Vehicle {
    /// All upcoming items (services + marbete if configured), sorted by urgency
    ///
    /// Scores are computed once up front and sorted on, rather than read through
    /// `UpcomingItem.urgencyScore` from inside the comparator: that accessor
    /// re-derives `effectiveMileage` and `dailyMilesPace` on every comparison,
    /// which walks every mileage snapshot O(n log n) times for one sort.
    var allUpcomingItems: [any UpcomingItem] {
        let mileage = mileageEstimate

        // Only include services with due tracking (exclude log-only/neutral services)
        var scored: [(item: any UpcomingItem, score: Int)] = (services ?? [])
            .filter { $0.hasDueTracking }
            .map { service in
                (
                    service as any UpcomingItem,
                    service.urgencyScore(currentMileage: mileage.effective, dailyPace: mileage.pace)
                )
            }

        // Include marbete if configured
        if hasMarbeteExpiration {
            let marbete = MarbeteUpcomingItem(vehicle: self)
            scored.append((marbete, marbete.urgencyScore))
        }

        // Sort by urgency (lower score = more urgent)
        return scored.sorted { $0.score < $1.score }.map(\.item)
    }

    /// The most urgent upcoming item (service or marbete)
    var nextUpItem: (any UpcomingItem)? {
        allUpcomingItems.first
    }

    /// `nextUpItem` for a caller that has already resolved the mileage estimate
    /// and urgency-sorted this vehicle's due-tracking services — Home needs both
    /// the winner and the remainder, and deriving them separately meant sorting
    /// twice and walking the mileage snapshots twice.
    ///
    /// - Parameter tracked: due-tracking services, most urgent first.
    func mostUrgentUpcomingItem(
        mileage: MileageEstimate,
        tracked: [Service]
    ) -> (any UpcomingItem)? {
        let topService = tracked.first
        guard hasMarbeteExpiration else { return topService }

        let marbete = MarbeteUpcomingItem(vehicle: self)
        guard let topService else { return marbete }

        let serviceScore = topService.urgencyScore(
            currentMileage: mileage.effective,
            dailyPace: mileage.pace
        )
        return marbete.urgencyScore < serviceScore ? marbete : topService
    }
}
