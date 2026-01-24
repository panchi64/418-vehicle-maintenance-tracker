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
