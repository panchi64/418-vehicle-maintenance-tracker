//
//  SharedVehicleOdometer.swift
//  VehicleSharing
//
//  Read-only odometer snapshot published by Checkpoint for companion apps.
//

import Foundation

/// A single vehicle's odometer state, published by Checkpoint (source of truth)
/// into the shared App Group for companion apps to read.
///
/// `currentMileage` / `estimatedMileage` are always in **miles** (Checkpoint's
/// internal storage unit). Use `distanceUnit` to convert for display.
public struct SharedVehicleOdometer: Codable, Sendable, Identifiable, Equatable {
    /// The vehicle's UUID, as a string (matches Checkpoint's `Vehicle.id`).
    public let id: String
    public let displayName: String
    /// Last user-entered odometer reading, in miles.
    public let currentMileage: Int
    /// Pace-projected mileage, in miles, when available.
    public let estimatedMileage: Int?
    /// Whether `displayMileage` should prefer the estimate.
    public let isEstimated: Bool
    /// The user's preferred display unit (display/input only — values are miles).
    public let distanceUnit: SharedDistanceUnit
    /// When Checkpoint last recorded a reading for this vehicle.
    public let updatedAt: Date?

    public init(
        id: String,
        displayName: String,
        currentMileage: Int,
        estimatedMileage: Int? = nil,
        isEstimated: Bool = false,
        distanceUnit: SharedDistanceUnit = .miles,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.currentMileage = currentMileage
        self.estimatedMileage = estimatedMileage
        self.isEstimated = isEstimated
        self.distanceUnit = distanceUnit
        self.updatedAt = updatedAt
    }

    /// Mileage to surface to the user, in miles — the estimate when available,
    /// otherwise the last recorded reading.
    public var displayMileage: Int {
        (isEstimated ? estimatedMileage : nil) ?? currentMileage
    }

    /// A copy reflecting a freshly-entered reading (in miles): the new current
    /// value (never moving backwards), estimate cleared, timestamp bumped. Used
    /// by companion apps for optimistic local updates after queueing a reading.
    /// Keeping this on the struct means new fields can't be silently dropped by
    /// a hand-rolled rebuild at the call site.
    public func applyingReading(_ miles: Int, at date: Date) -> SharedVehicleOdometer {
        SharedVehicleOdometer(
            id: id,
            displayName: displayName,
            currentMileage: max(currentMileage, miles),
            estimatedMileage: nil,
            isEstimated: false,
            distanceUnit: distanceUnit,
            updatedAt: date
        )
    }
}
