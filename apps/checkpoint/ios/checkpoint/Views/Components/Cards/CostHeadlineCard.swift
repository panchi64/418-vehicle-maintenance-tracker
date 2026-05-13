import SwiftUI

struct CostHeadlineCard: View {
    let formattedTotal: String
    let periodLabel: String
    let deltaAmount: Decimal?
    let deltaDirection: TrendDirection
    let priorPeriodLabel: String
    let reactiveShare: Int
    let preventiveShare: Int
    let discretionaryShare: Int
    let projection: Decimal?
    let shareSummary: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            topRow

            Text(formattedTotal)
                .font(.brutalistHero)
                .foregroundStyle(Theme.accent)
                .contentTransition(.numericText())
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            Text(periodLabel)
                .font(.brutalistSecondary)
                .foregroundStyle(Theme.textTertiary)

            if let delta = deltaAmount {
                deltaRow(delta: delta)
                    .padding(.top, Spacing.xs)
            }

            if hasSplit {
                splitRow
                    .padding(.top, Spacing.xs)
            }

            if let projection {
                projectionRow(projection: projection)
                    .padding(.top, Spacing.xs)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .background(Theme.surfaceInstrument)
        .brutalistBorder()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Total spent \(formattedTotal), \(periodLabel)")
    }

    // MARK: - Subviews

    private var topRow: some View {
        HStack(alignment: .top) {
            Text(L10n.costsHeadlineTotal.uppercased())
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(2)

            Spacer()

            ShareLink(
                item: shareSummary,
                subject: Text(L10n.costsShareSubject),
                message: nil
            ) {
                Text(L10n.costsHeadlineShare)
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.textPrimary)
                    .tracking(1.5)
                    .underline(true, color: Theme.textPrimary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Share cost summary")
        }
    }

    private func deltaRow(delta: Decimal) -> some View {
        let absAmount = Formatters.currencyWhole(abs(delta))
        let text: String
        switch deltaDirection {
        case .up:
            text = L10n.costsHeadlineDeltaUp(absAmount, priorPeriodLabel)
        case .down:
            text = L10n.costsHeadlineDeltaDown(absAmount, priorPeriodLabel)
        case .flat:
            text = L10n.costsHeadlineDeltaFlat(priorPeriodLabel)
        }
        return Text(text)
            .font(.brutalistSecondary)
            .foregroundStyle(deltaColor)
    }

    private var splitRow: some View {
        Text(L10n.costsHeadlineSplit(reactiveShare, preventiveShare, discretionaryShare))
            .font(.brutalistLabel)
            .foregroundStyle(Theme.textTertiary)
            .tracking(1.5)
            .lineLimit(2)
            .minimumScaleFactor(0.8)
    }

    private func projectionRow(projection: Decimal) -> some View {
        Text(L10n.costsHeadlineProjection(Formatters.currencyWhole(projection)))
            .font(.brutalistLabel)
            .foregroundStyle(Theme.accentMuted)
            .tracking(1.5)
    }

    // MARK: - Helpers

    private var deltaColor: Color {
        switch deltaDirection {
        case .up: return Theme.statusOverdue
        case .down: return Theme.statusGood
        case .flat: return Theme.textTertiary
        }
    }

    private var hasSplit: Bool {
        reactiveShare + preventiveShare + discretionaryShare > 0
    }
}

#Preview {
    ZStack {
        AtmosphericBackground()

        ScrollView {
            VStack(spacing: Spacing.lg) {
                CostHeadlineCard(
                    formattedTotal: "$1,234",
                    periodLabel: "Last 12 months",
                    deltaAmount: 420,
                    deltaDirection: .up,
                    priorPeriodLabel: "vs prior 12 mo",
                    reactiveShare: 55,
                    preventiveShare: 35,
                    discretionaryShare: 10,
                    projection: nil,
                    shareSummary: "Sample share text"
                )

                CostHeadlineCard(
                    formattedTotal: "$867",
                    periodLabel: "Year to date",
                    deltaAmount: -180,
                    deltaDirection: .down,
                    priorPeriodLabel: "vs YTD 2025",
                    reactiveShare: 20,
                    preventiveShare: 70,
                    discretionaryShare: 10,
                    projection: 1450,
                    shareSummary: "Sample share text"
                )

                CostHeadlineCard(
                    formattedTotal: "$0",
                    periodLabel: "All time",
                    deltaAmount: nil,
                    deltaDirection: .flat,
                    priorPeriodLabel: "",
                    reactiveShare: 0,
                    preventiveShare: 0,
                    discretionaryShare: 0,
                    projection: nil,
                    shareSummary: ""
                )
            }
            .padding(Spacing.screenHorizontal)
        }
    }
    .preferredColorScheme(.dark)
}
