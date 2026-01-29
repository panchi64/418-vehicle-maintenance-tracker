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

    var itemName: String { "Marbete Renewal" }

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
        return status(currentMileage: vehicle.effectiveMileage)
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
    var allUpcomingItems: [any UpcomingItem] {
        var items: [any UpcomingItem] = services.map { $0 as any UpcomingItem }

        // Include marbete if configured
        if hasMarbeteExpiration {
            items.append(MarbeteUpcomingItem(vehicle: self))
        }

        // Sort by urgency (lower score = more urgent)
        return items.sorted { $0.urgencyScore < $1.urgencyScore }
    }

    /// The most urgent upcoming item (service or marbete)
    var nextUpItem: (any UpcomingItem)? {
        allUpcomingItems.first
    }
}
