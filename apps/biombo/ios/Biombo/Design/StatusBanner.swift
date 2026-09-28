import SwiftUI

/// A state the whole app is in, above the answer: "Modo emergencia",
/// "Sin conexión", "Señal débil" (V2-Crisis, Crisis-Offline). Symbol plus
/// words, never colour alone; the chevron says it opens what it means.
/// A label only: callers wrap it in a `NavigationLink`.
struct StatusBanner: View {
    let symbol: String
    let title: LocalizedStringResource
    var detail: LocalizedStringResource?

    @Environment(\.theme) private var theme

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.s3) {
            Image(systemName: symbol)
                .foregroundStyle(theme.accent)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .textRole(.headline)
                    .foregroundStyle(Color(.ink))
                if let detail {
                    Text(detail)
                        .textRole(.subheadline)
                        .foregroundStyle(Color(.ink2))
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: Spacing.s2)
            Image(systemName: "chevron.forward")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color(.ink3))
                .accessibilityHidden(true)
        }
        .padding(.horizontal, Spacing.s4)
        .padding(.vertical, Spacing.s3)
        .frame(maxWidth: .infinity, minHeight: Size.target, alignment: .leading)
        .background(Color(.paperRaised), in: .rect(cornerRadius: Radius.medium))
        .contrastEdge()
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}
