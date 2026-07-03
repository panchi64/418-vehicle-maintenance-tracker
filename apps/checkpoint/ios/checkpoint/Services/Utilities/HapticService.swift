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

    // Cached generators. Reusing a single instance per feedback kind and calling
    // prepare() before firing keeps the Taptic Engine warm, which lowers latency
    // and avoids the allocation churn of creating a generator per call.
    private let impactSoft = UIImpactFeedbackGenerator(style: .soft)
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()

    private init() {}

    // MARK: - Tab Navigation

    /// Soft haptic for tab changes and swipe navigation
    func tabChanged() {
        impactSoft.prepare()
        impactSoft.impactOccurred()
    }

    // MARK: - Feedback Types

    /// Success haptic for completed actions (form saves, task completion)
    func success() {
        notification.prepare()
        notification.notificationOccurred(.success)
    }

    /// Warning haptic for destructive or important actions (delete confirmations)
    func warning() {
        notification.prepare()
        notification.notificationOccurred(.warning)
    }

    /// Error haptic for failed actions
    func error() {
        notification.prepare()
        notification.notificationOccurred(.error)
    }

    /// Selection changed haptic for picker changes
    func selectionChanged() {
        selection.prepare()
        selection.selectionChanged()
    }

    // MARK: - Impact Variations

    /// Light impact for subtle interactions
    func lightImpact() {
        impactLight.prepare()
        impactLight.impactOccurred()
    }

    /// Medium impact for standard interactions
    func mediumImpact() {
        impactMedium.prepare()
        impactMedium.impactOccurred()
    }

    /// Heavy impact for significant interactions
    func heavyImpact() {
        impactHeavy.prepare()
        impactHeavy.impactOccurred()
    }
}
