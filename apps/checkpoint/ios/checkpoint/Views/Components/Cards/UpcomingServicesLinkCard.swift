import SwiftUI

struct UpcomingServicesLinkCard: View {
    let nextServiceName: String
    let additionalCount: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 20)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.costsUpcomingTitle.uppercased())
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.textTertiary)
                        .tracking(1.5)

                    Text(body(name: nextServiceName, more: additionalCount))
                        .font(.brutalistBody)
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(Spacing.md)
            .background(Theme.surfaceInstrument)
            .brutalistBorder()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Coming up: \(body(name: nextServiceName, more: additionalCount))")
        .accessibilityHint("Double tap to view services")
    }

    private func body(name: String, more: Int) -> String {
        more <= 0
            ? L10n.costsUpcomingBodySingular(name)
            : L10n.costsUpcomingBodyPlural(name, more)
    }
}
