//
//  TouchTarget.swift
//  checkpoint
//
//  Touch target constants and accessibility modifier
//  Ensures all interactive elements meet 44pt minimum
//

import SwiftUI

enum TouchTarget {
    /// Apple HIG recommended minimum touch target size
    static let minimum: CGFloat = 44
}

// MARK: - Minimum Touch Target Modifier

struct MinimumTouchTargetModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(minWidth: TouchTarget.minimum, minHeight: TouchTarget.minimum)
            .contentShape(Rectangle())
    }
}

extension View {
    /// Ensures the view has a minimum 44x44pt touch target
    /// Visual appearance stays the same, but tap area is expanded
    func minimumTouchTarget() -> some View {
        modifier(MinimumTouchTargetModifier())
    }
}
