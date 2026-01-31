//
//  TappableCardModifier.swift
//  checkpoint
//
//  Custom gesture modifier that distinguishes taps from swipes
//  Solves conflict between card taps and tab-switching swipe gestures
//

import SwiftUI

struct TappableCardModifier: ViewModifier {
    let action: () -> Void
    @GestureState private var isPressed = false

    /// Maximum movement distance (in points) to consider a touch as a tap
    /// Movement beyond this threshold is treated as a swipe/drag
    private let maxTapDistance: CGFloat = 10

    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .opacity(isPressed ? 0.7 : 1.0)
            .animation(.easeOut(duration: Theme.animationFast), value: isPressed)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($isPressed) { _, isPressed, _ in
                        isPressed = true
                    }
                    .onEnded { value in
                        // Only fire if movement was minimal (tap, not swipe)
                        let distance = sqrt(
                            pow(value.translation.width, 2) +
                            pow(value.translation.height, 2)
                        )
                        if distance < maxTapDistance {
                            action()
                        }
                    }
            )
    }
}

extension View {
    /// Adds a tap gesture that only fires when movement is minimal
    /// Use this instead of Button for tappable cards in swipeable contexts
    func tappableCard(action: @escaping () -> Void) -> some View {
        modifier(TappableCardModifier(action: action))
    }
}
