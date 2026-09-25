import SwiftUI

struct UpcomingServicesLinkCard: View {
    let nextServiceName: String
    let additionalCount: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "calendar.badge.clock")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.costsUpcomingTitle.uppercased())
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.textTertiary)
                        .tracking(1.5)

                    Text(body(name: nextServiceName, more: additionalCount))
                        .font(.brutalistBody)
                        .foregroundStyle(Theme.textPrimary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.textTertiary)
                    .accessibilityHidden(true)
            }
            .padding(Spacing.md)
            .background(Theme.surfaceInstrument)
            .brutalistBorder()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // The button's label reads the title then the service line.
        .accessibilityElement(children: .combine)
    }

    private func body(name: String, more: Int) -> String {
        more <= 0
            ? L10n.costsUpcomingBodySingular(name)
            : L10n.costsUpcomingBodyPlural(name, more)
    }
}
