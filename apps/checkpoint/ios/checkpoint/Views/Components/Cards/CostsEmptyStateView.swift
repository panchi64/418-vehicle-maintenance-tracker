import SwiftUI

struct CostsEmptyStateView: View {
    let hasLoggedAny: Bool

    var body: some View {
        VStack(spacing: Spacing.lg) {
            EmptyStateView(
                icon: "dollarsign.circle",
                title: hasLoggedAny ? L10n.costsEmptyStartTitle : L10n.costsEmptyNoneTitle,
                message: hasLoggedAny ? L10n.costsEmptyStartMessage : L10n.costsEmptyNoneMessage
            )

            silhouette
        }
    }

    private var silhouette: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            silhouetteHeadline
            silhouetteChart
        }
        .padding(Spacing.lg)
        .background(Theme.surfaceInstrument)
        .brutalistBorder(color: Theme.gridLine.opacity(0.5))
        .opacity(0.35)
        .accessibilityHidden(true)
    }

    private var silhouetteHeadline: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Rectangle()
                .fill(Theme.textTertiary)
                .frame(width: 80, height: 8)

            Rectangle()
                .fill(Theme.accent)
                .frame(maxWidth: 200)
                .frame(height: 36)

            Rectangle()
                .fill(Theme.textTertiary)
                .frame(width: 140, height: 8)
        }
    }

    private var silhouetteChart: some View {
        HStack(alignment: .bottom, spacing: Spacing.xs) {
            ForEach(Self.silhouetteBarHeights, id: \.self) { height in
                Rectangle()
                    .fill(Theme.accent)
                    .frame(maxWidth: .infinity)
                    .frame(height: height)
            }
        }
        .frame(height: 80)
    }

    private static let silhouetteBarHeights: [CGFloat] = [22, 38, 30, 56, 42, 70, 48]
}

#Preview("Empty - no logs") {
    ZStack {
        AtmosphericBackground()
        CostsEmptyStateView(hasLoggedAny: false)
            .padding(Spacing.screenHorizontal)
    }
    .preferredColorScheme(.dark)
}

#Preview("Empty - has logs") {
    ZStack {
        AtmosphericBackground()
        CostsEmptyStateView(hasLoggedAny: true)
            .padding(Spacing.screenHorizontal)
    }
    .preferredColorScheme(.dark)
}
