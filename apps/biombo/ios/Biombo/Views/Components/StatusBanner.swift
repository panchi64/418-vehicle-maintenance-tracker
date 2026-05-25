import SwiftUI
import DesignKit

struct StatusBanner: View {
    @Environment(\.theme) private var theme

    enum Status {
        case offline, syncing, error(LocalizedStringKey)

        var labelKey: LocalizedStringKey {
            switch self {
            case .offline: return "status.offline"
            case .syncing: return "status.syncing"
            case .error(let message): return message
            }
        }

        var code: String {
            switch self {
            case .offline: return "// OFFLINE"
            case .syncing: return "// SYNCING"
            case .error: return "// ERROR"
            }
        }
    }

    let status: Status

    var body: some View {
        HStack(spacing: DKSpacing.sm) {
            Text(status.code)
                .font(theme.font(.caption2, weight: .bold))
                .foregroundStyle(theme.backgroundPrimary)
                .tracking(1.5)

            Text(status.labelKey)
                .font(theme.font(.caption))
                .foregroundStyle(theme.backgroundPrimary)
                .textCase(.uppercase)
                .tracking(1)

            Spacer()
        }
        .padding(.horizontal, DKSpacing.md)
        .padding(.vertical, DKSpacing.xs)
        .background(theme.accent)
    }
}
