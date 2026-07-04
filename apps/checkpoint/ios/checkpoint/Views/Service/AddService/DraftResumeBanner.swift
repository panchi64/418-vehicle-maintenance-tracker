import SwiftUI

/// Shown at the top of Add Service when a saved draft is found and no
/// explicit prefill (seasonal / post-record) is already driving the form (R9).
struct DraftResumeBanner: View {
    let savedAt: Date
    let onResume: () -> Void
    let onDiscard: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(L10n.formDraftResumeTitle)
                .font(.brutalistBody)
                .foregroundStyle(Theme.textPrimary)

            Text(L10n.formDraftFrom(TimeSinceFormatter.full(from: savedAt)))
                .font(.brutalistSecondary)
                .foregroundStyle(Theme.textTertiary)

            HStack(spacing: Spacing.sm) {
                Button(L10n.formDraftResume, action: onResume)
                    .buttonStyle(.primary)

                Button(L10n.formDraftDiscard, action: onDiscard)
                    .buttonStyle(.secondary)
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.accent.opacity(0.08))
        .overlay(
            Rectangle()
                .strokeBorder(Theme.accent.opacity(0.3), lineWidth: Theme.borderWidth)
        )
    }
}
