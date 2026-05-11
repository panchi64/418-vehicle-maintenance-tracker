import SwiftUI

/// Compact action row that duplicates a prior service log onto the
/// current form. Sits above the service-type picker, visible only when
/// the vehicle has prior history.
struct UseLastEntryButton: View {
    let serviceName: String
    let performedDate: Date
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.accent)

                VStack(alignment: .leading, spacing: 2) {
                    Text("USE LAST ENTRY")
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.accent)
                        .tracking(1)

                    Text("\(serviceName) · \(Formatters.shortDate.string(from: performedDate))")
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }

                Spacer()
            }
            .padding(Spacing.md)
            .background(Theme.surfaceInstrument)
            .brutalistBorder(color: Theme.accent.opacity(0.4))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Use last entry: \(serviceName)")
    }
}
