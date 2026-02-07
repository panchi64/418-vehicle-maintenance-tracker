//
//  AnalyticsScreenTracker.swift
//  checkpoint
//
//  ViewModifier for automatic screen view tracking
//

import SwiftUI

/// ViewModifier that fires a screen view event on appear
private struct ScreenTrackingModifier: ViewModifier {
    let screen: AnalyticsEvent.ScreenName

    func body(content: Content) -> some View {
        content
            .onAppear {
                AnalyticsService.shared.capture(.screenViewed(screen: screen))
            }
    }
}

extension View {
    /// Track a screen view event when this view appears
    func trackScreen(_ screen: AnalyticsEvent.ScreenName) -> some View {
        modifier(ScreenTrackingModifier(screen: screen))
    }
}
