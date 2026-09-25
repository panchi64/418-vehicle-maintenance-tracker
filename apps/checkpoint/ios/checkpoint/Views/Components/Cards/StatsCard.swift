//
//  StatsCard.swift
//  checkpoint
//
//  Compact stat card with label and value, used in stats rows
//

import SwiftUI

struct StatsCard: View {
    let label: String
    let value: String
    let valueColor: Color
    let subvalue: String?
    let subvalueColor: Color
    /// What the stat describes. The Costs tab is reused across vehicles, so
    /// without this the value would roll from one car's figure to another's as
    /// though a single number had changed. A period change on the same vehicle
    /// still rolls, which is the case the effect is for.
    let subjectID: AnyHashable?

    init(
        label: String,
        value: String,
        valueColor: Color = Theme.textPrimary,
        subvalue: String? = nil,
        subvalueColor: Color = Theme.textTertiary,
        subjectID: AnyHashable? = nil
    ) {
        self.label = label
        self.value = value
        self.valueColor = valueColor
        self.subvalue = subvalue
        self.subvalueColor = subvalueColor
        self.subjectID = subjectID
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Uppercased here rather than relying on the caller passing caps.
            // These labels used to be hardcoded "SERVICES"/"AVG COST"; once
            // they moved to L10n they arrived in sentence case and stopped
            // matching every other label on the screen. Translations shouldn't
            // have to encode casing.
            Text(label)
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .textCase(.uppercase)
                .tracking(1)

            // These recompute whenever the Costs period changes, so all three
            // cards in a row roll together.
            RollingNumberText(value, minimumScaleFactor: 0.7, resetToken: subjectID)
                .font(.brutalistHeading)
                .foregroundStyle(valueColor)

            if let subvalue {
                Text(subvalue)
                    .font(.brutalistLabel)
                    .foregroundStyle(subvalueColor)
                    .tracking(0.5)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        // Stretch to the tallest card in the row before painting the box.
        // Without this each card sized to its own content, so a card carrying a
        // `subvalue` was taller than its neighbours — and an HStack centres by
        // default, so it hung off both the top and the bottom of the row.
        //
        // Top alignment, not centre: the labels then form one line across the
        // row and the values another, which is what makes three stats read as a
        // set. The extra space falls to the bottom, where a missing subvalue is
        // simply absent rather than shifting everything above it.
        //
        // The caller must pair this with `.fixedSize(horizontal: false,
        // vertical: true)` on the row — see `StatsCardRow`.
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.surfaceInstrument)
        .brutalistBorder()
        // Reads label, value, subvalue in order from the children themselves.
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Row

/// The row `StatsCard` is meant to live in.
///
/// It exists to own the `fixedSize` half of the equal-height trick. `StatsCard`
/// asks for `maxHeight: .infinity` so every card matches the tallest one; inside
/// a ScrollView that offers unbounded height, so the row has to resolve it back
/// to the natural height. Leaving that to the caller made a silent, ugly failure
/// one forgotten modifier away.
struct StatsCardRow<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        // Three tiles side by side can't hold AX-size numerals, so the row
        // stacks at accessibility sizes; each tile is then full width.
        AdaptiveStack(verticalAlignment: .top, spacing: Spacing.md) {
            content
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    ZStack {
        AtmosphericBackground()

        VStack(spacing: Spacing.lg) {
            // The middle card carries a subvalue: all three should still be the
            // same height, with their labels and values on shared baselines.
            StatsCardRow {
                StatsCard(label: "SERVICES", value: "12")
                StatsCard(
                    label: "PER MILE",
                    value: "$0.15/mi",
                    valueColor: Theme.accent,
                    subvalue: "↓ $0.17/mi",
                    subvalueColor: Theme.statusGood
                )
                StatsCard(label: "AVG COST", value: "$87")
            }

            StatsCardRow {
                StatsCard(label: "TOTAL", value: "$1,234", valueColor: Theme.accent)
                StatsCard(label: "COUNT", value: "45")
            }
        }
        .padding(Spacing.screenHorizontal)
    }
    .preferredColorScheme(.dark)
}
