import SwiftUI

struct SanityWarningRow: View {
    let message: String

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.statusDueSoon)

            Text(message.uppercased())
                .font(.brutalistLabel)
                .foregroundStyle(Theme.statusDueSoon)
                .tracking(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Spacing.md)
        .background(Theme.statusDueSoon.opacity(0.08))
        .overlay(
            Rectangle()
                .strokeBorder(Theme.statusDueSoon.opacity(0.4), lineWidth: Theme.borderWidth)
        )
        .accessibilityLabel(message)
    }
}

#Preview {
    ZStack {
        Theme.backgroundPrimary.ignoresSafeArea()
        VStack(spacing: Spacing.lg) {
            SanityWarningRow(message: "Lower than your last logged mileage (32,500 on this vehicle). Typo?")
            SanityWarningRow(message: "Much higher than past oil change entries. Typo?")
        }
        .padding(Spacing.screenHorizontal)
    }
    .preferredColorScheme(.dark)
}
