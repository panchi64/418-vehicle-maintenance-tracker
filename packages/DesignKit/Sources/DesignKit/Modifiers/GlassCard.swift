import SwiftUI

public enum GlassIntensity: Sendable {
    case subtle, medium, strong, heavy

    public var blurRadius: CGFloat {
        switch self {
        case .subtle: return 10
        case .medium: return 20
        case .strong: return 30
        case .heavy: return 30
        }
    }

    public var tintOpacity: Double {
        switch self {
        case .subtle: return 0.05
        case .medium: return 0.08
        case .strong: return 0.12
        case .heavy: return 0.15
        }
    }

    public var materialOpacity: Double {
        switch self {
        case .heavy: return 0.75
        default: return 0.5
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
                        .fill(intensity == .heavy ? .thinMaterial : .ultraThinMaterial)
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
