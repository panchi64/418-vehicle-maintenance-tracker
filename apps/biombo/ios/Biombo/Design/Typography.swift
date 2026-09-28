import SwiftUI

/// Type roles. Every role is a Dynamic Type text style, so it scales through the
/// accessibility sizes. SF Pro for rows, labels and anything in crisis; New York
/// (serif) for editorial moments only — the wordmark, place and barrio names on
/// postcards, one serif element per section; SF Rounded with tabular digits for
/// prices, counts, times and distances.
nonisolated enum TextRole: CaseIterable, Sendable {
    /// Root screen titles.
    case largeTitle
    /// The answer sentence: first and heaviest element of every sheet.
    case answer
    /// A section's mini-answer and the Capas title answer.
    case answerSmall
    /// The one primary of an event row; button labels.
    case headline
    /// The primary of a place row; menu items; reading copy.
    case body
    /// An official alert's sentence.
    case callout
    /// The one secondary line of a row.
    case subheadline
    case footnote
    case caption

    /// Serif: the wordmark.
    case wordmark
    /// Serif: a place or barrio name on its postcard.
    case placeName
    /// Serif: a section title on a postcard surface.
    case sectionTitle

    /// Rounded: the hero answer value ("$0.99").
    case hero
    /// Rounded: the one trailing value of a place row.
    case value
    /// Rounded: counts on Tu aporte.
    case metric
    /// Rounded: ladder, bar and chart labels.
    case viz

    var font: Font {
        switch self {
        case .largeTitle: .system(.largeTitle, weight: .bold)
        case .answer: .system(.title2, weight: .semibold)
        case .answerSmall: .system(.headline)
        case .headline: .system(.headline)
        case .body: .system(.body)
        case .callout: .system(.callout)
        case .subheadline: .system(.subheadline)
        case .footnote: .system(.footnote)
        case .caption: .system(.caption)
        case .wordmark, .placeName: .system(.title, design: .serif, weight: .semibold)
        case .sectionTitle: .system(.title3, design: .serif, weight: .semibold)
        case .hero: .system(.largeTitle, design: .rounded, weight: .semibold).monospacedDigit()
        case .value: .system(.body, design: .rounded, weight: .semibold).monospacedDigit()
        case .metric: .system(.title2, design: .rounded, weight: .semibold).monospacedDigit()
        case .viz: .system(.caption, design: .rounded, weight: .medium).monospacedDigit()
        }
    }
}

extension View {
    func textRole(_ role: TextRole) -> some View {
        font(role.font)
    }
}
