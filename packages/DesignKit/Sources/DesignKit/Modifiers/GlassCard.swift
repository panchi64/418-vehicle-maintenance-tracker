import SwiftUI

public enum GlassIntensity: Sendable {
    /// Near-solid frosted surface (`ultraThickMaterial`). Use when the card
    /// must stay fully legible regardless of what's underneath — e.g. an
    /// overlay card floating over the live, colorful app UI.
    case subtle, medium, strong, heavy, opaque

    public var blurRadius: CGFloat {
        switch self {
        case .subtle: return 10
        case .medium: return 20
        case .strong: return 30
        case .heavy: return 30
        case .opaque: return 30
        }
    }

    public var tintOpacity: Double {
        switch self {
        case .subtle: return 0.05
        case .medium: return 0.08
        case .strong: return 0.12
        case .heavy: return 0.15
        // The opaque material already supplies the surface; the tint pass
        // is skipped entirely so it doesn't lighten brand colors.
        case .opaque: return 0.0
        }
    }

    public var materialOpacity: Double {
        switch self {
        case .heavy: return 0.75
        case .opaque: return 1.0
        default: return 0.5
        }
    }

    /// The SwiftUI material used for the frosted plate. Heavier intensities
    /// climb the system's material ladder.
    public var material: Material {
        switch self {
        case .opaque: return .ultraThickMaterial
        case .heavy: return .thinMaterial
        default: return .ultraThinMaterial
        }
    }
}

public struct GlassCardModifier: ViewModifier {
    let intensity: GlassIntensity
    let padding: CGFloat
    let borderColor: Color
    let borderWidth: CGFloat

    public init(intensity: GlassIntensity, padding: CGFloat, borderColor: Color, borderWidth: CGFloat) {
        self.intensity = intensity
        self.padding = padding
        self.borderColor = borderColor
        self.borderWidth = borderWidth
    }

    public func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    Rectangle()
                        .fill(intensity.material)
                        .opacity(intensity.materialOpacity)
                    Rectangle().fill(Color.white.opacity(intensity.tintOpacity))
                }
            )
            .brutalistBorder(color: borderColor, lineWidth: borderWidth)
    }
}

public extension View {
    func glassCard(
        intensity: GlassIntensity = .medium,
        padding: CGFloat = 16,
        borderColor: Color,
        borderWidth: CGFloat = 2
    ) -> some View {
        modifier(
            GlassCardModifier(
                intensity: intensity,
                padding: padding,
                borderColor: borderColor,
                borderWidth: borderWidth
            )
        )
    }
}
