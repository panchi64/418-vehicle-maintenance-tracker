//
//  ServiceEventRow.swift
//  checkpoint
//
//  The one row for "something happened to this vehicle" — service history,
//  recent activity, and expense lists.
//
//  Why this exists: four near-identical implementations of
//  `[indicator] [title + metadata] [amount] [chevron]` had drifted apart —
//  `ServicesTab.historyRow`, `HomeTab.activityRow`, `ExpenseRow`, and
//  `VisitExpenseRow`. They disagreed on which element was primary (cost at
//  brutalistBody in two of them, brutalistHeading in another), on date format,
//  and on whether a chevron appeared. Per the repo's own rule, cosmetic
//  differences are props, not separate abstractions.
//
//  Hierarchy (rule 1 — exactly one primary):
//    - With an amount, the amount is primary. These rows live in expense
//      contexts where "how much" is the question being asked.
//    - Without an amount, the title is primary.
//  This settles the previous inconsistency rather than preserving both.
//
//  `MaintenanceTimeline`'s row is deliberately NOT folded in: its connector
//  geometry (node + vertical rule spanning between rows) is structural rather
//  than cosmetic, and forcing it through this shell would mean a prop that
//  changes the layout rather than its appearance.
//

import SwiftUI

struct ServiceEventRow: View {

    /// Leading status/type mark. Carries meaning, so it is paired with the
    /// title rather than being the only signal (never color alone).
    struct Indicator {
        let systemImage: String
        let color: Color

        static func completed() -> Indicator {
            Indicator(systemImage: "checkmark", color: Theme.statusGood)
        }

        static func bundledVisit(_ color: Color) -> Indicator {
            Indicator(systemImage: "checkmark.rectangle.stack", color: color)
        }

        static func category(_ category: CostCategory?) -> Indicator {
            guard let category else {
                return Indicator(systemImage: "dollarsign.circle", color: Theme.accent)
            }
            return Indicator(systemImage: category.icon, color: category.color)
        }
    }

    /// One fragment of the supporting metadata line. Fragments are joined with
    /// the house `//` separator by the row, so callers never assemble a display
    /// string themselves (rule 11).
    struct Metadatum: Identifiable {
        let id = UUID()
        let text: String
        let color: Color
        let isTagged: Bool

        /// Ordinary supporting detail — a date, a mileage.
        static func detail(_ text: String) -> Metadatum {
            Metadatum(text: text, color: Theme.textTertiary, isTagged: false)
        }

        /// A classification worth tinting — a cost category, an outlier flag.
        static func tag(_ text: String, color: Color) -> Metadatum {
            Metadatum(text: text, color: color, isTagged: true)
        }
    }

    struct Amount {
        let text: String
        let color: Color
    }

    let indicator: Indicator
    let title: String
    var metadata: [Metadatum] = []
    var amount: Amount?
    var isHighlighted: Bool = false
    /// Overrides the spoken value. Defaults to the amount, or a stated absence.
    var accessibilityValueText: String?
    var accessibilityLabelText: String?
    var onTap: (() -> Void)?

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    /// Indicator column width, scaled with its glyph so titles stay aligned
    /// down the list without the glyph overflowing its column at large sizes.
    @ScaledMetric(relativeTo: .subheadline) private var indicatorWidth: CGFloat = 20

    private var hasAmount: Bool { amount != nil }
    private var isAccessibilitySize: Bool { dynamicTypeSize.isAccessibilitySize }

    var body: some View {
        if let onTap {
            Button(action: onTap) { content }
                .buttonStyle(.plain)
        } else {
            content
        }
    }

    private var content: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: indicator.systemImage)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(indicator.color)
                .frame(width: indicatorWidth)
                .accessibilityHidden(true)

            // Title block and amount sit side by side; at accessibility
            // sizes the amount drops beneath the title instead of squeezing
            // it to a few characters.
            AdaptiveStack(spacing: Spacing.sm) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(title)
                        // Primary only when there's no amount to outrank it.
                        .font(hasAmount ? .brutalistBody : .brutalistBodyEmphasis)
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(isAccessibilitySize ? nil : 1)

                    if !metadata.isEmpty {
                        metadataLine
                    }
                }

                Spacer(minLength: Spacing.sm)

                if let amount {
                    Text(amount.text)
                        .font(.brutalistHeading)
                        .foregroundStyle(amount.color)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }

            if onTap != nil {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.textTertiary)
                    .accessibilityHidden(true)
            }
        }
        // Vertical only — see ServiceRow. The horizontal inset was interior
        // padding for a card these rows no longer sit inside.
        .padding(.vertical, Spacing.listItem)
        .background(isHighlighted ? Theme.accent.opacity(0.12) : Color.clear)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabelText ?? title)
        .accessibilityValue(accessibilityValueText ?? amount?.text ?? "")
        .accessibilityHint(onTap != nil ? L10n.rowViewDetailsHint : "")
    }

    /// One line of `//`-separated details at standard sizes; one detail per
    /// line at accessibility sizes, where the separators have nothing left
    /// to separate.
    private var metadataLine: some View {
        AdaptiveStack(spacing: Spacing.xs) {
            ForEach(Array(metadata.enumerated()), id: \.element.id) { index, datum in
                if index > 0 && !isAccessibilitySize {
                    Text(verbatim: "//")
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.gridLine)
                        .accessibilityHidden(true)
                }

                Text(datum.text)
                    .font(datum.isTagged ? .brutalistLabel : .brutalistSecondary)
                    .foregroundStyle(datum.color)
                    .tracking(datum.isTagged ? 0.5 : 0)
                    .lineLimit(isAccessibilitySize ? nil : 1)
            }
        }
    }
}

#Preview {
    ZStack {
        AtmosphericBackground()

        VStack(spacing: 0) {
            ServiceEventRow(
                indicator: .category(.maintenance),
                title: "Oil Change",
                metadata: [.detail("Mar 12, 2026"), .tag("MAINTENANCE", color: CostCategory.maintenance.color)],
                amount: .init(text: "$125.50", color: CostCategory.maintenance.color),
                onTap: {}
            )

            ListDivider()

            ServiceEventRow(
                indicator: .bundledVisit(CostCategory.repair.color),
                title: "Brakes + Rotors + Fluid",
                metadata: [.detail("Feb 2, 2026"), .tag("OUTLIER", color: Theme.statusOverdue)],
                amount: .init(text: "$980.00", color: CostCategory.repair.color),
                onTap: {}
            )

            ListDivider()

            // No amount: the title becomes the primary.
            ServiceEventRow(
                indicator: .completed(),
                title: "Tire Rotation",
                metadata: [.detail("Jan 8, 2026"), .detail("32,500 mi")],
                onTap: {}
            )
        }
        .background(Theme.surfaceInstrument)
        .brutalistBorder()
        .padding(Spacing.screenHorizontal)
    }
    .preferredColorScheme(.dark)
}
