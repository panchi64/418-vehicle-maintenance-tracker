import SwiftUI
import DesignKit

struct FreshnessIndicator: View {
    @Environment(\.theme) private var theme
    let freshness: CachedFuelPrice.Freshness
    let source: String

    var body: some View {
        HStack(spacing: 6) {
            Rectangle()
                .fill(dotColor)
                .frame(width: 8, height: 8)

            Text(label)
                .font(theme.font(.caption2))
                .foregroundStyle(theme.textTertiary)
                .tracking(1.5)
                .textCase(.uppercase)
        }
    }

    private var label: LocalizedStringKey {
        switch freshness {
        case .fresh: return "freshness.fresh"
        case .aging: return "freshness.aging"
        case .stale: return "freshness.stale"
        }
    }

    private var dotColor: Color {
        switch freshness {
        case .fresh: return theme.accent
        case .aging: return theme.accentMuted
        case .stale: return theme.textTertiary
        }
    }
}
