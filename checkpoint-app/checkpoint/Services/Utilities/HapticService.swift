//
//  HapticService.swift
//  checkpoint
//
//  Centralized haptic feedback service for consistent tactile feedback
//

import UIKit

@MainActor
final class HapticService {
    static let shared = HapticService()

    private init() {}

    // MARK: - Tab Navigation

    /// Soft haptic for tab changes and swipe navigation
    func tabChanged() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    // MARK: - Feedback Types

    /// Success haptic for completed actions (form saves, task completion)
    func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// Warning haptic for destructive or important actions (delete confirmations)
    func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    /// Error haptic for failed actions
    func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    /// Selection changed haptic for picker changes
    func selectionChanged() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    // MARK: - Impact Variations

    /// Light impact for subtle interactions
    func lightImpact() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// Medium impact for standard interactions
    func mediumImpact() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    /// Heavy impact for significant interactions
    func heavyImpact() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }
}
