import SwiftUI
import DesignKit

struct EmptyStateView: View {
    @Environment(\.theme) private var theme
    let code: String
    let title: LocalizedStringKey
    let message: LocalizedStringKey

    var body: some View {
        VStack(spacing: DKSpacing.sm) {
            Text(code)
                .font(theme.font(.caption2, weight: .bold))
                .foregroundStyle(theme.textTertiary)
                .tracking(1.5)

            Text(title)
                .font(theme.font(.title3, weight: .bold))
                .foregroundStyle(theme.textPrimary)
                .textCase(.uppercase)
                .tracking(2)
                .multilineTextAlignment(.center)

            Text(message)
                .font(theme.font(.caption))
                .foregroundStyle(theme.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, DKSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
    }
}
