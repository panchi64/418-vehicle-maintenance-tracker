//
//  Theme.swift
//  checkpoint
//
//  Brutalist-Tech-Modernist design system
//  Structural honesty, terminal aesthetics, geometric clarity
//

import SwiftUI

enum Theme {
    // MARK: - Backgrounds
    static let backgroundPrimary = Color("BackgroundPrimary")
    static let backgroundElevated = Color("BackgroundElevated")
    static let backgroundSubtle = Color("BackgroundSubtle")

    // MARK: - Surfaces
    static let surfaceInstrument = Color("SurfaceInstrument")
    static let glow = Color("GlowAmber")
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

    // MARK: - Brutalist Layout Constants
    static let screenHorizontalPadding: CGFloat = 16
    static let cardCornerRadius: CGFloat = 0      // Sharp corners - brutalist
    static let buttonCornerRadius: CGFloat = 0    // Sharp corners
    static let cardPadding: CGFloat = 16
    static let buttonHeight: CGFloat = 48
    static let instrumentCornerRadius: CGFloat = 0
    static let borderWidth: CGFloat = 1

    // MARK: - Animation Timing (minimal, functional)
    static let animationFast: Double = 0.1
    static let animationMedium: Double = 0.2
    static let animationSlow: Double = 0.3
    static let revealStagger: Double = 0.05
    static let pulseAnimationDuration: Double = 1.5

    // MARK: - Removed (brutalism doesn't use glows)
    static let glowRadius: CGFloat = 0
    static let glowOpacity: Double = 0
    static let statusGlowRadius: CGFloat = 0
    static let statusGlowOpacity: Double = 0
}

// MARK: - Brutalist Card Style

struct CardStyle: ViewModifier {
    var padding: CGFloat = Theme.cardPadding

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Theme.surfaceInstrument)
            .overlay(
                Rectangle()
                    .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
            )
    }
}

extension View {
    func cardStyle(padding: CGFloat = Theme.cardPadding) -> some View {
        modifier(CardStyle(padding: padding))
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
            .frame(maxWidth: .infinity)
            .frame(height: Theme.buttonHeight)
            .background(Theme.surfaceInstrument)
            .overlay(
                Rectangle()
                    .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
            )
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeOut(duration: Theme.animationFast), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

// MARK: - Brutalist Instrument Card

struct InstrumentCardStyle: ViewModifier {
    var padding: CGFloat = Theme.cardPadding
    var glowColor: Color? = nil  // Ignored in brutalist style

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Theme.surfaceInstrument)
            .overlay(
                Rectangle()
                    .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
            )
    }
}

extension View {
    func instrumentCardStyle(padding: CGFloat = Theme.cardPadding, glowColor: Color? = nil) -> some View {
        modifier(InstrumentCardStyle(padding: padding, glowColor: glowColor))
    }
}

// MARK: - Status Indicator (no glow in brutalist)

struct StatusGlowModifier: ViewModifier {
    let color: Color
    let isActive: Bool

    func body(content: Content) -> some View {
        content
        // No glow effects in brutalist design - structural honesty
    }
}

extension View {
    func statusGlow(color: Color, isActive: Bool = true) -> some View {
        modifier(StatusGlowModifier(color: color, isActive: isActive))
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

// MARK: - Brutalist Background (pure black)

struct AtmosphericBackground: View {
    var body: some View {
        Theme.surfaceInstrument
            .ignoresSafeArea()
    }
}

// MARK: - Brutalist Section Header

struct InstrumentSectionHeader: View {
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .textCase(.uppercase)
                .tracking(2)

            Rectangle()
                .fill(Theme.gridLine)
                .frame(height: Theme.borderWidth)
        }
    }
}

// MARK: - Terminal-style Data Row

struct BrutalistDataRow: View {
    let label: String
    let value: String
    var valueColor: Color = Theme.textPrimary

    var body: some View {
        HStack {
            Text(label)
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .textCase(.uppercase)
                .tracking(1)

            Spacer()

            Text(value)
                .font(.brutalistBody)
                .foregroundStyle(valueColor)
        }
    }
}

// MARK: - Grid Structure Overlay

struct GridOverlay: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                // Vertical lines every 16pt
                let spacing: CGFloat = 16
                for x in stride(from: 0, to: geo.size.width, by: spacing) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geo.size.height))
                }
            }
            .stroke(Theme.gridLine.opacity(0.3), lineWidth: 0.5)
        }
        .allowsHitTesting(false)
    }
}
