//
//  TappableCardModifier.swift
//  checkpoint
//
//  Custom gesture modifier that distinguishes taps from swipes
//  Solves conflict between card taps and tab-switching swipe gestures
//  Uses onTapGesture which has proper priority with ScrollView
//

import SwiftUI

struct TappableCardModifier: ViewModifier {
    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .onTapGesture {
                action()
            }
    }
}

extension View {
    /// Adds a tap gesture that only fires when movement is minimal
    /// Use this instead of Button for tappable cards in swipeable contexts
    func tappableCard(action: @escaping () -> Void) -> some View {
        modifier(TappableCardModifier(action: action))
    }
}
