//
//  Theme.swift
//  checkpoint
//
//  Design system theme with semantic colors and premium styling
//

import SwiftUI

enum Theme {
    // MARK: - Backgrounds
    static let backgroundPrimary = Color("BackgroundPrimary")
    static let backgroundElevated = Color("BackgroundElevated")
    static let backgroundSubtle = Color("BackgroundSubtle")

    // MARK: - Instrument Panel Surfaces
    static let surfaceInstrument = Color("SurfaceInstrument")
    static let glowAmber = Color("GlowAmber")
    static let gridLine = Color("GridLine")

    // MARK: - Text
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")
    static let textTertiary = Color("TextTertiary")

    // MARK: - Borders
    static let borderSubtle = Color("BorderSubtle")

    // MARK: - Accent
    static let accent = Color("Accent")
    static let accentMuted = Color("AccentMuted")

    // MARK: - Status
    static let statusOverdue = Color("StatusOverdue")
    static let statusDueSoon = Color("StatusDueSoon")
    static let statusGood = Color("StatusGood")
    static let statusNeutral = Color("StatusNeutral")

    // MARK: - Layout Constants
    static let screenHorizontalPadding: CGFloat = 20
    static let cardCornerRadius: CGFloat = 20
    static let buttonCornerRadius: CGFloat = 14
    static let cardPadding: CGFloat = 20
    static let buttonHeight: CGFloat = 52
    static let instrumentCornerRadius: CGFloat = 24

    // MARK: - Glow Effects
    static let glowRadius: CGFloat = 4
    static let glowOpacity: Double = 0.2
    static let statusGlowRadius: CGFloat = 8
    static let statusGlowOpacity: Double = 0.3

    // MARK: - Animation Timing
    static let animationFast: Double = 0.15
    static let animationMedium: Double = 0.3
    static let animationSlow: Double = 0.5
    static let revealStagger: Double = 0.08
    static let pulseAnimationDuration: Double = 2.0
}

// MARK: - Card Style Modifier

struct CardStyle: ViewModifier {
    var padding: CGFloat = Theme.cardPadding

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    Theme.backgroundElevated

                    // Subtle top gradient for depth
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.03),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Theme.borderSubtle.opacity(0.5),
                                Theme.borderSubtle.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}

extension View {
    func cardStyle(padding: CGFloat = Theme.cardPadding) -> some View {
        modifier(CardStyle(padding: padding))
    }
}

// MARK: - Primary Button Style

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(Color(red: 0.071, green: 0.071, blue: 0.071))
            .frame(maxWidth: .infinity)
            .frame(height: Theme.buttonHeight)
            .background(
                ZStack {
                    Theme.accent

                    // Subtle gradient for depth
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.15),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.buttonCornerRadius, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Secondary Button Style

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(Theme.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: Theme.buttonHeight)
            .background(Theme.backgroundSubtle)
            .clipShape(RoundedRectangle(cornerRadius: Theme.buttonCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.buttonCornerRadius, style: .continuous)
                    .strokeBorder(Theme.borderSubtle.opacity(0.5), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

// MARK: - Instrument Card Style

struct InstrumentCardStyle: ViewModifier {
    var padding: CGFloat = Theme.cardPadding
    var glowColor: Color? = nil

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    Theme.surfaceInstrument

                    // Subtle vertical gradient overlay
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.02),
                            Color.clear,
                            Color.black.opacity(0.1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.instrumentCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.instrumentCornerRadius, style: .continuous)
                    .strokeBorder(Theme.gridLine, lineWidth: 1)
            )
            .shadow(color: glowColor?.opacity(Theme.glowOpacity) ?? .clear,
                    radius: Theme.glowRadius, x: 0, y: 0)
    }
}

extension View {
    func instrumentCardStyle(padding: CGFloat = Theme.cardPadding, glowColor: Color? = nil) -> some View {
        modifier(InstrumentCardStyle(padding: padding, glowColor: glowColor))
    }
}

// MARK: - Status Glow Modifier

struct StatusGlowModifier: ViewModifier {
    let color: Color
    let isActive: Bool

    @State private var glowAmount: Double = 0.3

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(isActive ? glowAmount : 0),
                    radius: Theme.statusGlowRadius, x: 0, y: 0)
            .onAppear {
                if isActive {
                    withAnimation(
                        .easeInOut(duration: Theme.pulseAnimationDuration)
                        .repeatForever(autoreverses: true)
                    ) {
                        glowAmount = 0.6
                    }
                }
            }
    }
}

extension View {
    func statusGlow(color: Color, isActive: Bool = true) -> some View {
        modifier(StatusGlowModifier(color: color, isActive: isActive))
    }
}

// MARK: - Pulse Animation Modifier

struct PulseAnimationModifier: ViewModifier {
    let isActive: Bool

    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0

    func body(content: Content) -> some View {
        content
            .scaleEffect(isActive ? scale : 1.0)
            .opacity(isActive ? opacity : 1.0)
            .onAppear {
                if isActive {
                    withAnimation(
                        .easeInOut(duration: Theme.pulseAnimationDuration)
                        .repeatForever(autoreverses: true)
                    ) {
                        scale = 1.15
                        opacity = 0.7
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

// MARK: - Reveal Animation Modifier

struct RevealAnimationModifier: ViewModifier {
    let delay: Double
    let animation: Animation

    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.95)
            .offset(y: isVisible ? 0 : 10)
            .onAppear {
                withAnimation(animation.delay(delay)) {
                    isVisible = true
                }
            }
    }
}

extension View {
    func revealAnimation(delay: Double = 0, animation: Animation = .spring(response: 0.4, dampingFraction: 0.8)) -> some View {
        modifier(RevealAnimationModifier(delay: delay, animation: animation))
    }
}

// MARK: - Staggered Reveal Modifier

struct StaggeredRevealModifier: ViewModifier {
    let index: Int
    let baseDelay: Double

    func body(content: Content) -> some View {
        content
            .revealAnimation(delay: baseDelay + (Double(index) * Theme.revealStagger))
    }
}

extension View {
    func staggeredReveal(index: Int, baseDelay: Double = 0.2) -> some View {
        modifier(StaggeredRevealModifier(index: index, baseDelay: baseDelay))
    }
}

// MARK: - Enhanced Press Feedback Button Style

struct InstrumentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .brightness(configuration.isPressed ? 0.05 : 0)
            .animation(.easeOut(duration: Theme.animationFast), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == InstrumentButtonStyle {
    static var instrument: InstrumentButtonStyle { InstrumentButtonStyle() }
}

// MARK: - Atmospheric Background

struct AtmosphericBackground: View {
    var ambientColor: Color = Theme.glowAmber

    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.1),
                    Theme.surfaceInstrument
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Ambient glow from top
            RadialGradient(
                colors: [
                    ambientColor.opacity(0.03),
                    Color.clear
                ],
                center: .top,
                startRadius: 0,
                endRadius: 400
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - Section Header with Rule

struct InstrumentSectionHeader: View {
    let title: String

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Text(title)
                .instrumentSectionStyle()

            Rectangle()
                .fill(Theme.gridLine)
                .frame(height: 1)
        }
    }
}
