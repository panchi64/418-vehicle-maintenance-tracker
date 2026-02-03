//
//  FeatureDiscovery.swift
//  checkpoint
//
//  Observable singleton for tracking feature hint visibility with UserDefaults persistence
//

import Foundation

/// Manages one-time feature hints that appear contextually to help users discover app features.
/// Once a user dismisses a hint, it never appears again.
@Observable
@MainActor
final class FeatureDiscovery {
    // MARK: - Singleton

    static let shared = FeatureDiscovery()

    // MARK: - Feature Enumeration

    /// Features that have discoverable hints
    enum Feature: String, CaseIterable {
        case vinLookup          // VIN scanning in vehicle details
        case odometerOCR        // Camera OCR for mileage capture
        case swipeNavigation    // Tab swipe gestures
        case serviceBundling    // Service clustering by proximity

        /// UserDefaults key for this feature's seen status
        var storageKey: String {
            "featureHint_\(rawValue)_seen"
        }

        /// Human-readable hint message
        var message: String {
            switch self {
            case .vinLookup:
                return "Scan your VIN to auto-fill vehicle details"
            case .odometerOCR:
                return "Point your camera at the odometer to capture mileage"
            case .swipeNavigation:
                return "Swipe left or right to switch tabs"
            case .serviceBundling:
                return "Services due around the same time are grouped together"
            }
        }

        /// SF Symbol icon name
        var icon: String {
            switch self {
            case .vinLookup:
                return "barcode.viewfinder"
            case .odometerOCR:
                return "camera.viewfinder"
            case .swipeNavigation:
                return "hand.draw"
            case .serviceBundling:
                return "square.stack.3d.up"
            }
        }
    }

    // MARK: - Properties

    /// Tracks which hints have been seen (for observable updates)
    private var seenFeatures: Set<Feature> = []

    // MARK: - Initialization

    private init() {
        loadSeenFeatures()
    }

    // MARK: - Public API

    /// Check if a hint should be displayed for the given feature
    /// - Parameter feature: The feature to check
    /// - Returns: True if the hint has never been seen before
    func shouldShowHint(for feature: Feature) -> Bool {
        return !seenFeatures.contains(feature)
    }

    /// Mark a hint as seen, preventing it from appearing again
    /// - Parameter feature: The feature whose hint was dismissed
    func markHintSeen(_ feature: Feature) {
        guard !seenFeatures.contains(feature) else { return }

        seenFeatures.insert(feature)
        UserDefaults.standard.set(true, forKey: feature.storageKey)
    }

    // MARK: - Persistence

    private func loadSeenFeatures() {
        let defaults = UserDefaults.standard
        seenFeatures = Set(
            Feature.allCases.filter { defaults.bool(forKey: $0.storageKey) }
        )
    }

    // MARK: - Testing Support

    /// Reset all hints (useful for testing and debugging)
    func resetAllHints() {
        for feature in Feature.allCases {
            UserDefaults.standard.removeObject(forKey: feature.storageKey)
        }
        seenFeatures.removeAll()
    }

    /// Reset a specific hint
    /// - Parameter feature: The feature to reset
    func resetHint(for feature: Feature) {
        UserDefaults.standard.removeObject(forKey: feature.storageKey)
        seenFeatures.remove(feature)
    }

    // MARK: - Default Registration

    /// Register default values for UserDefaults (call once at app launch)
    static func registerDefaults() {
        let defaults: [String: Bool] = Dictionary(
            uniqueKeysWithValues: Feature.allCases.map { ($0.storageKey, false) }
        )
        UserDefaults.standard.register(defaults: defaults)
    }
}
