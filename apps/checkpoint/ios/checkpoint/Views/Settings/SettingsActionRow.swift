import SwiftUI

struct SettingsActionRow: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey?
    let systemImage: String
    let iconColor: Color
    let action: () -> Void

    init(
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        systemImage: String,
        iconColor: Color = Theme.accent,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.iconColor = iconColor
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.brutalistBody)
                        .foregroundStyle(Theme.textPrimary)
                    if let subtitle {
                        Text(subtitle)
                            .font(.brutalistLabel)
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
                Spacer()
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(iconColor)
            }
            .padding(Spacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
