import SwiftUI

struct RepairClusterWarningCard: View {
    let count: Int
    let formattedTotal: String

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Rectangle()
                .fill(Theme.statusOverdue)
                .frame(width: 8, height: 8)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.costsClusterTitle)
                    .font(.brutalistLabelBold)
                    .foregroundStyle(Theme.statusOverdue)
                    .tracking(1.5)

                Text(L10n.costsClusterBody(count, formattedTotal))
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(Spacing.md)
        .background(Theme.surfaceInstrument)
        .brutalistBorder(color: Theme.statusOverdue.opacity(0.4))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(L10n.costsClusterTitle): \(L10n.costsClusterBody(count, formattedTotal))")
    }
}

#Preview {
    ZStack {
        AtmosphericBackground()

        VStack(spacing: Spacing.lg) {
            RepairClusterWarningCard(count: 3, formattedTotal: "$2,400")
            RepairClusterWarningCard(count: 2, formattedTotal: "$1,150")
        }
        .padding(Spacing.screenHorizontal)
    }
    .preferredColorScheme(.dark)
}
