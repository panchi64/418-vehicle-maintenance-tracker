import SwiftUI

/// A sheet section title (SF `.headline` in sheets, §N9) with an optional
/// trailing mini-answer or unit ("por litro", "2 avisos").
struct SectionHeader: View {
    let title: LocalizedStringResource
    var aside: LocalizedStringResource?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .textRole(.headline)
                .foregroundStyle(Color(.ink))
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: Spacing.s2)
            if let aside {
                Text(aside)
                    .textRole(.footnote)
                    .foregroundStyle(Color(.ink3))
            }
        }
    }
}

/// A section: its header, then its rows in one full-width inset group.
struct SectionGroup<Content: View>: View {
    let title: LocalizedStringResource
    var aside: LocalizedStringResource?
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            SectionHeader(title: title, aside: aside)
            VStack(alignment: .leading, spacing: 0) { content }
                .frame(maxWidth: .infinity, alignment: .leading)
                .insetGroup()
        }
    }
}

/// Rows with a hairline between each, for inside an inset group.
struct RowList<Element, Row: View>: View {
    let elements: [Element]
    /// Rows led by a pin inset their hairline past it.
    var isInset = false
    @ViewBuilder let row: (Element) -> Row

    var body: some View {
        ForEach(Array(elements.enumerated()), id: \.offset) { index, element in
            if index > 0 { RowDivider(isInset: isInset) }
            row(element)
        }
    }
}

/// "Ver todas (N)" and "Ver reportes anteriores (N)": a quiet tinted line.
/// The trailing mark says what the row does: go deeper, or open or fold in place.
/// The label alone, for navigation links; `DisclosureRow` wraps it in a button.
struct DisclosureLabel: View {
    enum Accessory {
        case forward
        case expand
        case collapse

        var symbol: String {
            switch self {
            case .forward: "chevron.forward"
            case .expand: "chevron.down"
            case .collapse: "chevron.up"
            }
        }
    }

    let title: LocalizedStringResource
    var symbol: String?
    var accessory: Accessory = .forward

    var body: some View {
        HStack(spacing: Spacing.s2) {
            if let symbol {
                Image(systemName: symbol)
                    .accessibilityHidden(true)
            }
            Text(title)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: Spacing.s2)
            Image(systemName: accessory.symbol)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color(.ink3))
                .accessibilityHidden(true)
        }
        .textRole(.body)
        .foregroundStyle(.tint)
        .frame(minHeight: Size.target)
        .contentShape(.rect)
    }
}

struct DisclosureRow: View {
    let title: LocalizedStringResource
    var symbol: String?
    var accessory: DisclosureLabel.Accessory = .forward
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            DisclosureLabel(title: title, symbol: symbol, accessory: accessory)
        }
        .buttonStyle(.plain)
    }
}

extension View {
    /// Rows sit on `paper-raised` inside the glass sheet; -hc adds the strong hairline.
    func insetGroup() -> some View {
        padding(.horizontal, Spacing.s4)
            .padding(.vertical, Spacing.s1)
            .background(Color(.paperRaised), in: .rect(cornerRadius: Radius.medium))
            .contrastEdge()
    }

    /// The strong hairline a raised surface gains with Increase Contrast, or
    /// always when `always` is set (bordered buttons).
    func contrastEdge(always: Bool = false) -> some View {
        modifier(ContrastEdge(always: always))
    }
}

private struct ContrastEdge: ViewModifier {
    let always: Bool
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        content.overlay {
            if always || contrast == .increased {
                RoundedRectangle(cornerRadius: Radius.medium).strokeBorder(Color(.borderStrong), lineWidth: 1)
            }
        }
    }
}

/// Hairline between rows inside an inset group; inset past the leading pin
/// in rows that have one.
struct RowDivider: View {
    var isInset = true
    @ScaledMetric(relativeTo: .body) private var inset = Size.listPin + Spacing.s3

    var body: some View {
        Divider()
            .overlay(Color(.separator))
            .padding(.leading, isInset ? inset : 0)
    }
}
