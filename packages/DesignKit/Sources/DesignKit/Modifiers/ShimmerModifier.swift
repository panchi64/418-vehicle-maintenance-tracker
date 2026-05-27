import SwiftUI

/// Subtle diagonal shine sweep. Designed to compose on top of a flat or
/// glowing element — for example, the onboarding spotlight in Checkpoint
/// places it over an off-white underglow. The peak opacity stays low by
/// default so the effect reads as motion rather than illumination.
///
/// The sweep is purely decorative (`allowsHitTesting(false)`). Pass a
/// `restartKey` whose value changes (e.g. a step index) to replay the
/// sweep without rebuilding the view tree.
public struct ShimmerModifier: ViewModifier {
    let isActive: Bool
    let color: Color
    let intensity: Double
    let duration: Double
    let restartKey: AnyHashable?

    public init(
        isActive: Bool,
        color: Color,
        intensity: Double = 0.18,
        duration: Double = 3.0,
        restartKey: AnyHashable? = nil
    ) {
        self.isActive = isActive
        self.color = color
        self.intensity = intensity
        self.duration = duration
        self.restartKey = restartKey
    }

    public func body(content: Content) -> some View {
        content.overlay {
            if isActive {
                ShimmerOverlay(
                    color: color,
                    intensity: intensity,
                    duration: duration,
                    restartKey: restartKey
                )
                .mask(Rectangle())
                .allowsHitTesting(false)
            }
        }
    }
}

private struct ShimmerOverlay: View {
    let color: Color
    let intensity: Double
    let duration: Double
    let restartKey: AnyHashable?

    @State private var phase: CGFloat = -1

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let diagonal = max(width, height) * 1.5

            Rectangle()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: color.opacity(0), location: 0.0),
                            .init(color: color.opacity(intensity), location: 0.5),
                            .init(color: color.opacity(0), location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: diagonal, height: diagonal)
                .offset(x: phase * (width + diagonal), y: 0)
        }
        // `.task(id:)` runs on appearance and re-runs (cancelling the
        // previous task) whenever `restartKey` changes — resetting `phase`
        // and replaying the sweep in place without forcing the consumer
        // to bump view identity.
        .task(id: restartKey) {
            phase = -1
            withAnimation(
                .linear(duration: duration).repeatForever(autoreverses: false)
            ) {
                phase = 1
            }
        }
    }
}

public extension View {
    /// Continuous diagonal shine sweep. The shimmer is theme-agnostic — pass
    /// the accent color of the current theme (e.g. `theme.accent` or
    /// `Theme.accent`) so the effect stays on-brand per app. Pass a
    /// `restartKey` whose value changes (e.g. a step index) to replay the
    /// sweep — without it the animation only fires on first appearance.
    func shimmer(
        isActive: Bool = true,
        color: Color,
        intensity: Double = 0.18,
        duration: Double = 3.0,
        restartKey: AnyHashable? = nil
    ) -> some View {
        modifier(ShimmerModifier(
            isActive: isActive,
            color: color,
            intensity: intensity,
            duration: duration,
            restartKey: restartKey
        ))
    }
}
