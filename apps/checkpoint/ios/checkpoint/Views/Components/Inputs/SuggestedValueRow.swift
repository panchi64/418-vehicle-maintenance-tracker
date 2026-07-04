import SwiftUI

/// A muted suggestion strip rendered below an input. Shows a value the form
/// could prefill from history, with an explicit `USE` action so the value is
/// only committed when the user agrees. Hidden once the underlying field has
/// a non-empty value — typing manually dismisses the suggestion implicitly.
struct SuggestedValueRow: View {
    let label: String
    let onUse: () -> Void

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.accent.opacity(0.7))
                .accessibilityHidden(true)

            Text(label.uppercased())
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1)

            Spacer()

            Button(action: onUse) {
                Text(L10n.formUse)
                    .textCase(.uppercase)
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.accent)
                    .tracking(1)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .overlay(
                        Rectangle()
                            .strokeBorder(Theme.accent.opacity(0.5), lineWidth: Theme.borderWidth)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.formUseSuggestedValue(label))
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.xs)
    }
}
