//
//  ToastService.swift
//  checkpoint
//
//  Observable service for displaying toast notifications with actions
//

import Foundation
import SwiftUI

@Observable @MainActor
final class ToastService {
    static let shared = ToastService()

    var currentToast: Toast?

    private var dismissTask: Task<Void, Never>?

    struct ToastAction {
        let label: String
        let handler: @MainActor @Sendable () -> Void
    }

    struct Toast: Identifiable {
        let id = UUID()
        let message: String
        let action: ToastAction?
    }

    private init() {}

    /// Show a toast notification with optional action button
    func show(_ message: String, action: ToastAction? = nil) {
        // Cancel existing dismiss task
        dismissTask?.cancel()

        // Set new toast
        currentToast = Toast(message: message, action: action)

        // Auto-dismiss after 5 seconds
        dismissTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(5))
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
