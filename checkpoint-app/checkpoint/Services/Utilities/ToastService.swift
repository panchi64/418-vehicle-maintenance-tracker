//
//  ToastService.swift
//  checkpoint
//
//  Observable service for displaying toast notifications with actions
//

import Foundation
import SwiftUI
import UIKit

@Observable @MainActor
final class ToastService {
    static let shared = ToastService()

    var currentToast: Toast?

    private var dismissTask: Task<Void, Never>?

    // MARK: - Types

    enum ToastStyle {
        case success
        case error
        case info

        var iconColor: Color {
            switch self {
            case .success: return Theme.statusGood
            case .error: return Theme.statusOverdue
            case .info: return Theme.accent
            }
        }
    }

    struct ToastAction {
        let label: String
        let handler: @MainActor @Sendable () -> Void
    }

    struct Toast: Identifiable {
        let id = UUID()
        let message: String
        let icon: String?
        let style: ToastStyle
        let action: ToastAction?
    }

    private init() {}

    /// Show a toast notification with icon, style, and optional action button
    func show(
        _ message: String,
        icon: String? = nil,
        style: ToastStyle = .info,
        action: ToastAction? = nil
    ) {
        // Cancel existing dismiss task
        dismissTask?.cancel()

        // Set new toast
        currentToast = Toast(message: message, icon: icon, style: style, action: action)

        // Post VoiceOver announcement
        UIAccessibility.post(notification: .announcement, argument: message)

        // Auto-dismiss after 3 seconds (5 seconds if has action)
        let duration: Double = action != nil ? 5 : 3
        dismissTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(duration))
            if !Task.isCancelled {
                dismiss()
            }
        }
    }

    /// Dismiss the current toast immediately
    func dismiss() {
        dismissTask?.cancel()
        dismissTask = nil
        currentToast = nil
    }
}
