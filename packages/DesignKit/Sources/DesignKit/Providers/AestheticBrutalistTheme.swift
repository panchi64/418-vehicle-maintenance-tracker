import SwiftUI
import Observation

/// Biombo's theme. Matches docs/AESTHETIC.md — Cerulean #0033BE + Off-White #F5F0DC,
/// JetBrains Mono typography, zero rounded corners.
@Observable
public final class AestheticBrutalistTheme: ThemeProviding {
    public static let shared = AestheticBrutalistTheme()

    public init() {}

    public let backgroundPrimary: Color = Color(hex: "#0033BE")
    public let backgroundElevated: Color = Color(hex: "#0033BE")
    public let backgroundSubtle: Color = Color(hex: "#002A9A")
    public let surfaceInstrument: Color = Color(hex: "#0033BE")
    public let glow: Color = Color(hex: "#F5F0DC").opacity(0.2)
    public let gridLine: Color = Color(hex: "#F5F0DC").opacity(0.2)

    public let textPrimary: Color = Color(hex: "#F5F0DC")
    public let textSecondary: Color = Color(hex: "#F5F0DC").opacity(0.7)
    public let textTertiary: Color = Color(hex: "#F5F0DC").opacity(0.4)

    public let borderSubtle: Color = Color(hex: "#F5F0DC").opacity(0.2)

    public let accent: Color = Color(hex: "#F5F0DC")
    public let accentMuted: Color = Color(hex: "#F5F0DC").opacity(0.7)

    public let statusOverdue: Color = Color(hex: "#F5F0DC")
    public let statusDueSoon: Color = Color(hex: "#F5F0DC").opacity(0.7)
    public let statusGood: Color = Color(hex: "#F5F0DC").opacity(0.5)
    public let statusNeutral: Color = Color(hex: "#F5F0DC").opacity(0.4)

    public let fontDesign: Font.Design = .monospaced
    public let colorScheme: ColorScheme? = .dark
}
