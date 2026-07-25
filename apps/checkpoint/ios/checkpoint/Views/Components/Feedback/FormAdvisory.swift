//
//  FormAdvisory.swift
//  checkpoint
//
//  The one advisory component for data-entry surfaces (F12).
//
//  Why this exists: forms previously stacked four kinds of advisory —
//  validation errors, sanity warnings, countdowns, and projections — as
//  visually interchangeable 11pt uppercase rows. A message meaning "this
//  reminder will never fire" looked exactly like one meaning "42 days out",
//  so severity was invisible and the important ones were scrolled past.
//
//  The ladder differentiates on THREE channels, not just color, because a
//  single channel fails under theming, color blindness, and sunlight:
//
//    severity        type                enclosure              color
//    .blocking       15 Medium           filled + full border   statusOverdue
//    .contradiction  15 Medium + buttons filled + full border   accent
//    .caution        13 Regular          tinted, leading rule   statusDueSoon
//    .info           13 Regular          none                   textTertiary
//
//  Messages are sentence case, not uppercased: these are sentences, and
//  uppercasing prose destroys word-shape recognition (see AESTHETIC.md,
//  "Typography → Hierarchy").
//
//  NOT in this ladder: `SuggestedValueRow` (an offer with an action) and
//  `OriginalValueHint` (inline change transparency, F6). Those are
//  field-adjacent affordances rather than statements about a condition, and
//  folding them in would recreate the uniform-treatment problem in reverse.
//

import SwiftUI

struct FormAdvisory: View {
    enum Severity {
        /// This will not work as configured. Render adjacent to the control
        /// that resolves it — a blocker the user must hunt for is not a
        /// blocker, it's a complaint.
        case blocking

        /// The app cannot determine which of two inputs is wrong, so the user
        /// must choose. Requires `outcomes`.
        case contradiction

        /// Probably a typo, possibly deliberate. Never blocks saving.
        case caution

        /// A consequence or projection. This is how a form says what saving
        /// will also change — e.g. adopting an odometer reading.
        case info
    }

    /// A labeled resolution for `.contradiction`. Two of these replace prose
    /// like "either the date or the mileage is wrong" with something actionable.
    struct Outcome: Identifiable {
        let id = UUID()
        let label: String
        let action: () -> Void

        init(label: String, action: @escaping () -> Void) {
            self.label = label
            self.action = action
        }
    }

    let severity: Severity
    let message: String
    var onDismiss: (() -> Void)? = nil
    var outcomes: [Outcome] = []

    // MARK: - Initializers
    //
    // Severity-specific inits so the call site can't build an invalid
    // combination (a .contradiction with no outcomes, or an .info with a
    // dismiss button it doesn't need).

    static func blocking(_ message: String) -> FormAdvisory {
        FormAdvisory(severity: .blocking, message: message)
    }

    static func contradiction(_ message: String, outcomes: [Outcome]) -> FormAdvisory {
        FormAdvisory(severity: .contradiction, message: message, outcomes: outcomes)
    }

    static func caution(_ message: String, onDismiss: (() -> Void)? = nil) -> FormAdvisory {
        FormAdvisory(severity: .caution, message: message, onDismiss: onDismiss)
    }

    static func info(_ message: String) -> FormAdvisory {
        FormAdvisory(severity: .info, message: message)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            messageRow

            if severity == .contradiction, !outcomes.isEmpty {
                outcomeRow
            }
        }
        .padding(padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background)
        .overlay(alignment: .leading) { leadingRule }
        .overlay { border }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(accessibilityPrefix): \(message)")
    }

    private var messageRow: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            if let iconName {
                Image(systemName: iconName)
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundStyle(tint)
                    .accessibilityHidden(true)
            }

            Text(message)
                .font(messageFont)
                .foregroundStyle(messageColor)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.textTertiary)
                        .minimumTouchTarget()
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.commonDismiss)
            }
        }
    }

    /// Outcomes are equal-width so neither reads as the safe default — the
    /// point of a contradiction is that the app genuinely doesn't know.
    private var outcomeRow: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(outcomes) { outcome in
                Button(outcome.label, action: outcome.action)
                    .buttonStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Severity styling

    private var tint: Color {
        switch severity {
        case .blocking: return Theme.statusOverdue
        case .contradiction: return Theme.accent
        case .caution: return Theme.statusDueSoon
        case .info: return Theme.textTertiary
        }
    }

    /// Channel 1 — type. Blocking and contradiction read at body-emphasis
    /// weight; caution and info recede to secondary.
    private var messageFont: Font {
        switch severity {
        case .blocking, .contradiction: return .brutalistBodyEmphasis
        case .caution, .info: return .brutalistSecondary
        }
    }

    private var messageColor: Color {
        switch severity {
        case .blocking: return Theme.statusOverdue
        case .contradiction: return Theme.textPrimary
        case .caution: return Theme.statusDueSoon
        case .info: return Theme.textSecondary
        }
    }

    private var iconName: String? {
        switch severity {
        case .blocking: return "exclamationmark.octagon.fill"
        case .contradiction: return "questionmark.diamond.fill"
        case .caution: return "exclamationmark.circle"
        case .info: return nil
        }
    }

    private var iconSize: CGFloat {
        switch severity {
        case .blocking, .contradiction: return 15
        case .caution, .info: return 13
        }
    }

    /// Channel 2 — enclosure. Filled + bordered for the two levels that
    /// demand action; a leading rule for caution; nothing at all for info.
    @ViewBuilder
    private var background: some View {
        switch severity {
        case .blocking, .contradiction:
            tint.opacity(0.14)
        case .caution:
            tint.opacity(0.07)
        case .info:
            Color.clear
        }
    }

    @ViewBuilder
    private var border: some View {
        switch severity {
        case .blocking, .contradiction:
            Rectangle()
                .strokeBorder(tint.opacity(0.65), lineWidth: Theme.borderWidth)
        case .caution, .info:
            EmptyView()
        }
    }

    @ViewBuilder
    private var leadingRule: some View {
        if severity == .caution {
            Rectangle()
                .fill(tint.opacity(0.7))
                .frame(width: Theme.borderWidth)
        }
    }

    private var padding: EdgeInsets {
        switch severity {
        case .blocking, .contradiction:
            return EdgeInsets(top: Spacing.md, leading: Spacing.md, bottom: Spacing.md, trailing: Spacing.md)
        case .caution:
            return EdgeInsets(top: Spacing.sm, leading: Spacing.listItem, bottom: Spacing.sm, trailing: Spacing.sm)
        case .info:
            return EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        }
    }

    /// Channel 3 for non-visual users: severity is spoken, since weight and
    /// enclosure don't survive VoiceOver.
    private var accessibilityPrefix: String {
        switch severity {
        case .blocking: return L10n.advisoryBlocking
        case .contradiction: return L10n.advisoryDecision
        case .caution: return L10n.advisoryCaution
        case .info: return L10n.advisoryInfo
        }
    }
}

#Preview("Severity ladder") {
    ZStack {
        Theme.backgroundPrimary.ignoresSafeArea()

        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                FormAdvisory.blocking(
                    "Set a due date, mileage, or interval — this reminder won't fire yet."
                )

                FormAdvisory.contradiction(
                    "This service is dated 2023 but its mileage is above the current odometer. Which is right?",
                    outcomes: [
                        .init(label: "Keep odometer") {},
                        .init(label: "Update odometer") {}
                    ]
                )

                FormAdvisory.caution(
                    "Lower than your last logged mileage (32,500 on this vehicle). Typo?"
                ) {}

                FormAdvisory.info("Also updates odometer — 32,500 → 33,100")

                FormAdvisory.info("42 days ahead · 1,200 mi ahead")
            }
            .padding(Spacing.screenHorizontal)
        }
    }
    .preferredColorScheme(.dark)
}
