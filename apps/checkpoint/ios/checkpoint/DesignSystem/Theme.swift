//
//  Theme.swift
//  checkpoint
//
//  Brutalist-Tech-Modernist design system
//  Structural honesty, terminal aesthetics, geometric clarity
//

import SwiftUI
@_exported import DesignKit

enum Theme {
    /// Colors come from the active theme's **resolved** palette, not from its hex
    /// strings. Token accessors are read hundreds of times per screen, and
    /// `Color(hex:)` runs a `Scanner` each time; the palette is parsed once per
    /// theme change instead. See `ThemePalette`.
    private static var palette: ThemePalette { ThemeManager.shared.palette }

    // MARK: - Backgrounds
    static var backgroundPrimary: Color { palette.backgroundPrimary }
    static var backgroundElevated: Color { palette.backgroundElevated }
    static var backgroundSubtle: Color { palette.backgroundSubtle }

    // MARK: - Surfaces
    static var surfaceInstrument: Color { palette.surfaceInstrument }
    static var glow: Color { palette.glow }
    static var gridLine: Color { palette.gridLine }

    // MARK: - Text
    static var textPrimary: Color { palette.textPrimary }
    static var textSecondary: Color { palette.textSecondary }
    static var textTertiary: Color { palette.textTertiary }

    // MARK: - Borders
    static var borderSubtle: Color { palette.borderSubtle }

    // MARK: - Accent
    static var accent: Color { palette.accent }
    static var accentMuted: Color { palette.accentMuted }

    // MARK: - Status
    static var statusOverdue: Color { palette.statusOverdue }
    static var statusDueSoon: Color { palette.statusDueSoon }
    static var statusGood: Color { palette.statusGood }
    static var statusNeutral: Color { palette.statusNeutral }

    // MARK: - Brutalist Layout Constants
    static let screenHorizontalPadding: CGFloat = 16
    static let cardCornerRadius: CGFloat = 0      // Sharp corners - brutalist
    static let buttonCornerRadius: CGFloat = 0    // Sharp corners
    static let cardPadding: CGFloat = 16
    static let buttonHeight: CGFloat = 48
    /// HIG minimum touch target. Roughly fifteen views hardcode `44` for this;
    /// they should move onto this constant as they are next edited.
    ///
    /// It is a LAYOUT floor as much as a hit area — an icon button carrying it
    /// is the tallest thing in most rows, so a row that shows one conditionally
    /// has to reserve the same floor or it changes height when the button
    /// appears. See `BrutalistSearchField`.
    static let tapTarget: CGFloat = 44
    static let instrumentCornerRadius: CGFloat = 0
    static let borderWidth: CGFloat = 2           // 2px architectural dividers

    // MARK: - The Frame (35px border around viewport)
    static let frameWidth: CGFloat = 35

    // MARK: - Animation Timing (minimal, functional)
    static let animationFast: Double = 0.1
    static let animationMedium: Double = 0.2
    static let animationSlow: Double = 0.3
    static let revealStagger: Double = 0.05
    static let pulseAnimationDuration: Double = 1.5

    // MARK: - Odometer Roll (see RollingNumberText)
    /// How long one digit wheel takes to settle on its new glyph.
    static let odometerRollDuration: Double = 0.65
    /// Per-place delay. The ones wheel leads; each higher place lags behind it,
    /// which is what makes a carry read as one wheel dragging the next rather
    /// than every digit changing at once.
    static let odometerRollStagger: Double = 0.06
    /// Ceiling on the accumulated stagger, so a seven-figure value doesn't take
    /// half a second before its leading digit starts to move.
    static let odometerRollMaxDelay: Double = 0.24

    // MARK: - Glow Effects (Re-enabled for glass accents)
    static let glowRadius: CGFloat = 8
    static let glowOpacity: Double = 0.3
    static let statusGlowRadius: CGFloat = 12
    static let statusGlowOpacity: Double = 0.4
    static let focusGlowRadius: CGFloat = 6
    static let focusGlowOpacity: Double = 0.5
}

extension View {
    func brutalistBorder(color: Color = Theme.gridLine) -> some View {
        brutalistBorder(color: color, lineWidth: Theme.borderWidth)
    }

    func cardStyle(padding: CGFloat = Theme.cardPadding) -> some View {
        brutalistCard(
            background: Theme.surfaceInstrument,
            borderColor: Theme.gridLine,
            borderWidth: Theme.borderWidth,
            padding: padding
        )
    }

    func instrumentCardStyle(padding: CGFloat = Theme.cardPadding) -> some View {
        cardStyle(padding: padding)
    }
}

// MARK: - Brutalist Primary Button

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.brutalistBody)
            .textCase(.uppercase)
            .tracking(1)
            .foregroundStyle(Theme.surfaceInstrument)
            .buttonLabelFit()
            .frame(maxWidth: .infinity)
            .frame(height: Theme.buttonHeight)
            .background(Theme.accent)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeOut(duration: Theme.animationFast), value: configuration.isPressed)
    }
}

// MARK: - Brutalist Secondary Button

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.brutalistBody)
            .textCase(.uppercase)
            .tracking(1)
            .foregroundStyle(Theme.textPrimary)
            .buttonLabelFit()
            .frame(maxWidth: .infinity)
            .frame(height: Theme.buttonHeight)
            .background(Theme.surfaceInstrument)
            .brutalistBorder()
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeOut(duration: Theme.animationFast), value: configuration.isPressed)
    }
}

private extension View {
    /// Keeps a button label off its own border.
    ///
    /// Both styles are `maxWidth: .infinity`, so a long label in a shared row —
    /// "SAVE & LOG ANOTHER" next to "SAVE" in `FormActionBar` — got exactly the
    /// half-width it was given and ran edge to edge inside a 2pt border. The
    /// gutter is stated first so it is never the thing that gets sacrificed;
    /// the label scales into what is left, and a long word breaks rather than
    /// truncating to an ellipsis on a control whose whole job is to say what it
    /// does.
    func buttonLabelFit() -> some View {
        multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.75)
            .padding(.horizontal, Spacing.listItem)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}


// MARK: - Status Glow (Liquid Glass accent on brutalist base)

struct StatusGlowModifier: ViewModifier {
    let color: Color
    let isActive: Bool

    func body(content: Content) -> some View {
        content
            .background(
                Group {
                    if isActive {
                        Rectangle()
                            .fill(color)
                            .blur(radius: Theme.statusGlowRadius)
                            .opacity(Theme.statusGlowOpacity)
                    }
                }
            )
    }
}

extension View {
    func statusGlow(color: Color, isActive: Bool = true) -> some View {
        modifier(StatusGlowModifier(color: color, isActive: isActive))
    }
}

// MARK: - Focus Glow (for input fields)

struct FocusGlowModifier: ViewModifier {
    let color: Color
    let isActive: Bool

    func body(content: Content) -> some View {
        content
            .shadow(
                color: isActive ? color.opacity(Theme.focusGlowOpacity) : .clear,
                radius: isActive ? Theme.focusGlowRadius : 0
            )
    }
}

extension View {
    func focusGlow(color: Color = Theme.accent, isActive: Bool) -> some View {
        modifier(FocusGlowModifier(color: color, isActive: isActive))
    }
}

// MARK: - Glass Card Style

typealias GlassIntensity = DesignKit.GlassIntensity

extension View {
    func glassCardStyle(intensity: GlassIntensity = .medium, padding: CGFloat = Theme.cardPadding) -> some View {
        glassCard(
            intensity: intensity,
            padding: padding,
            borderColor: Theme.gridLine,
            borderWidth: Theme.borderWidth
        )
    }
}

// MARK: - Pulse Animation (subtle blink for terminals)

struct PulseAnimationModifier: ViewModifier {
    let isActive: Bool

    @State private var opacity: Double = 1.0

    func body(content: Content) -> some View {
        content
            .opacity(isActive ? opacity : 1.0)
            .onAppear {
                if isActive {
                    withAnimation(
                        .easeInOut(duration: Theme.pulseAnimationDuration)
                        .repeatForever(autoreverses: true)
                    ) {
                        opacity = 0.4
                    }
                }
            }
    }
}

extension View {
    func pulseAnimation(isActive: Bool) -> some View {
        modifier(PulseAnimationModifier(isActive: isActive))
    }
}

// MARK: - Reveal Animation (snap in, not soft)

struct RevealAnimationModifier: ViewModifier {
    let delay: Double
    let animation: Animation

    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(animation.delay(delay)) {
                    isVisible = true
                }
            }
    }
}

extension View {
    func revealAnimation(delay: Double = 0, animation: Animation = .easeOut(duration: 0.15)) -> some View {
        modifier(RevealAnimationModifier(delay: delay, animation: animation))
    }
}

// MARK: - Staggered Reveal

struct StaggeredRevealModifier: ViewModifier {
    let index: Int
    let baseDelay: Double

    func body(content: Content) -> some View {
        content
            .revealAnimation(delay: baseDelay + (Double(index) * Theme.revealStagger))
    }
}

extension View {
    func staggeredReveal(index: Int, baseDelay: Double = 0.1) -> some View {
        modifier(StaggeredRevealModifier(index: index, baseDelay: baseDelay))
    }
}

// MARK: - Brutalist Button Style

struct InstrumentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .animation(.easeOut(duration: Theme.animationFast), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == InstrumentButtonStyle {
    static var instrument: InstrumentButtonStyle { InstrumentButtonStyle() }
}

// MARK: - Toolbar Button Style
// iOS 26 toolbars use Liquid Glass styling. Use .tint() to color the glass
// and .buttonStyle(.borderedProminent) for filled buttons with custom color.
// The off-white tint matches our brutalist aesthetic within the glass system.

struct ToolbarButtonStyle: ViewModifier {
    let isDisabled: Bool

    init(isDisabled: Bool = false) {
        self.isDisabled = isDisabled
    }

    func body(content: Content) -> some View {
        content
            .font(.brutalistBody)
            .buttonStyle(.borderedProminent)
            .tint(Theme.textPrimary)
            .opacity(isDisabled ? 0.4 : 1.0)
    }
}

extension View {
    func toolbarButtonStyle(isDisabled: Bool = false) -> some View {
        modifier(ToolbarButtonStyle(isDisabled: isDisabled))
    }
}

// MARK: - Cerulean Background

struct AtmosphericBackground: View {
    var body: some View {
        Theme.backgroundPrimary
            .ignoresSafeArea()
    }
}

// MARK: - Framed Container (35px off-white border)

struct FramedContainer<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        DesignKit.FramedContainer(
            frameColor: Theme.accent,
            frameWidth: Theme.frameWidth,
            backgroundColor: Theme.backgroundPrimary
        ) {
            content
        }
    }
}

// MARK: - Brutalist Section Header

struct InstrumentSectionHeader<Trailing: View>: View {
    let title: String
    let trailing: Trailing

    init(title: String, @ViewBuilder trailing: () -> Trailing = { EmptyView() }) {
        self.title = title
        self.trailing = trailing()
    }

    var body: some View {
        DesignKit.SectionHeader(
            title: title,
            labelColor: Theme.textTertiary,
            dividerColor: Theme.gridLine,
            dividerHeight: Theme.borderWidth,
            labelFont: .brutalistLabel
        ) {
            trailing
        }
    }
}

// MARK: - Terminal-style Data Row

struct BrutalistDataRow: View {
    let label: String
    let value: String
    var valueColor: Color = Theme.textPrimary
    var padding: CGFloat = 0

    var body: some View {
        DesignKit.DataRow(
            label: label,
            value: value,
            labelColor: Theme.textTertiary,
            valueColor: valueColor,
            labelFont: .brutalistLabel,
            valueFont: .brutalistBody,
            padding: padding
        )
    }
}

// MARK: - Grid Structure Overlay

struct GridOverlay: View {
    var body: some View {
        DesignKit.GridOverlay(color: Theme.gridLine.opacity(0.3))
    }
}
