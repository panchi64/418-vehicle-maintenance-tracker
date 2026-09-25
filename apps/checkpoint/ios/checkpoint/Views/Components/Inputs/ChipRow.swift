import SwiftUI

/// One tap-to-select chip. Two variants, because two different jobs were
/// previously rendered identically.
///
/// TWO FAULTS ARE BEING CORRECTED HERE.
///
/// **Enclosure.** The service form rendered every control as an outlined
/// rectangle — eight quick-service chips, seven timing chips, six category
/// chips, three boxed fields. Twenty-four identical enclosures, so none of them
/// read as the decision. Enclosure is a budget; a `.decision` chip spends it and
/// a `.plain` chip does not.
///
/// **Type.** Every chip was 11pt Medium caps at 1.5 tracking, which is exactly
/// the FIELD-LABEL treatment. Measured across the whole form, 25 of 36 text
/// elements were 11pt: the decision was set in the smallest, most label-like
/// type in the system, and only its border said otherwise. Caps and heavy
/// tracking also make a phrase read as metadata — "PICK A DATE…" is shouted
/// where "Pick a date…" is offered.
struct Chip: View {
    enum Variant {
        /// The choice a surface exists to capture. Outlined, and set in 15
        /// Medium sentence case (`brutalistBodyEmphasis`), which the type scale
        /// defines as "the one primary datum". A timing chip IS that datum.
        case decision

        /// A shortcut that fills a field. No enclosure, 13 Regular sentence case.
        case plain
    }

    let label: String
    var variant: Variant = .decision
    var isSelected: Bool = false
    let action: () -> Void

    private var isPlain: Bool { variant == .plain }

    var body: some View {
        Button(action: action) {
            content
                .frame(minHeight: TouchTarget.minimum)
                .padding(.horizontal, isPlain ? Spacing.xs : Spacing.md)
                .background(!isPlain && isSelected ? Theme.accent : Color.clear)
                .overlay {
                    if !isPlain {
                        Rectangle()
                            .strokeBorder(
                                isSelected ? Theme.accent : Theme.borderSubtle,
                                lineWidth: Theme.borderWidth
                            )
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: Theme.animationFast), value: isSelected)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    @ViewBuilder
    private var content: some View {
        if isPlain {
            // Selection is color + WEIGHT, never a rule. An accent underline was
            // tried first and is the same visual device as a field's bottom
            // rule — so the input and the shortcuts beneath it read as the same
            // kind of control, and since tapping a chip copies its text into the
            // field, the same words appeared twice in the same treatment.
            //
            // 13pt sentence case, not 11pt tracked caps: caps made a shortcut
            // read as a field label, and shouted a phrase that is on offer.
            // Wraps rather than truncates at large type.
            Text(label)
                .font(.brutalistSecondary)
                .bold(isSelected)
                .foregroundStyle(isSelected ? Theme.accent : Theme.textSecondary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            // No line limit: `FlowLayout` only narrows a chip that can't fit
            // the row, and then the label must wrap rather than truncate.
            Text(label)
                .font(.brutalistBodyEmphasis)
                .foregroundStyle(isSelected ? Theme.backgroundPrimary : Theme.textPrimary)
        }
    }
}

// MARK: - Rows

/// Chips that wrap onto as many lines as they need.
///
/// Wrapping rather than scrolling is the default because a horizontally
/// scrolling option set HIDES options off the right edge — a filter or a choice
/// you must scroll to discover fails recognition-over-recall. Reach for
/// `ScrollingChipRow` only where the items are shortcuts the user loses nothing
/// by never seeing.
struct WrappingChipRow<Item: Hashable>: View {
    let items: [Item]
    let label: (Item) -> String
    var variant: Chip.Variant = .decision
    var isSelected: (Item) -> Bool = { _ in false }
    let onTap: (Item) -> Void

    var body: some View {
        FlowLayout(spacing: Spacing.sm) {
            ForEach(items, id: \.self) { item in
                Chip(
                    label: label(item),
                    variant: variant,
                    isSelected: isSelected(item)
                ) {
                    onTap(item)
                }
            }
        }
    }
}

/// Horizontal scroller, for shortcut strips only. See `WrappingChipRow`.
struct ScrollingChipRow<Item: Hashable>: View {
    let items: [Item]
    let label: (Item) -> String
    var variant: Chip.Variant = .plain
    var isSelected: (Item) -> Bool = { _ in false }
    let onTap: (Item) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(items, id: \.self) { item in
                    Chip(
                        label: label(item),
                        variant: variant,
                        isSelected: isSelected(item)
                    ) {
                        onTap(item)
                    }
                }
            }
        }
    }
}

// MARK: - Flow layout

/// Line-wrapping layout for chips. `Layout` rather than a hand-rolled VStack of
/// HStacks so the wrap point tracks Dynamic Type instead of a guessed
/// chips-per-row count.
struct FlowLayout: Layout {
    var spacing: CGFloat = Spacing.sm

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = arrange(subviews: subviews, maxWidth: maxWidth)
        let height = rows.reduce(CGFloat.zero) { $0 + $1.height } +
            spacing * CGFloat(max(0, rows.count - 1))
        return CGSize(width: maxWidth == .infinity ? rows.map(\.width).max() ?? 0 : maxWidth,
                      height: height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let rows = arrange(subviews: subviews, maxWidth: bounds.width)
        var y = bounds.minY

        for row in rows {
            var x = bounds.minX
            for index in row.indices {
                let size = fittedSize(of: subviews[index], maxWidth: bounds.width)
                subviews[index].place(
                    at: CGPoint(x: x, y: y),
                    proposal: ProposedViewSize(size)
                )
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    /// A chip's single-line size, unless that is wider than the row — then it is
    /// offered the row's width and wraps its label. At accessibility sizes one
    /// long chip can exceed the screen, and an unbounded proposal drew it off
    /// the edge.
    private func fittedSize(of subview: LayoutSubview, maxWidth: CGFloat) -> CGSize {
        let ideal = subview.sizeThatFits(.unspecified)
        guard ideal.width > maxWidth, maxWidth.isFinite else { return ideal }
        return subview.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
    }

    private func arrange(subviews: Subviews, maxWidth: CGFloat) -> [Row] {
        var rows: [Row] = []
        var current = Row()

        for index in subviews.indices {
            let size = fittedSize(of: subviews[index], maxWidth: maxWidth)
            let needed = current.indices.isEmpty ? size.width : current.width + spacing + size.width

            if needed > maxWidth, !current.indices.isEmpty {
                rows.append(current)
                current = Row()
                current.indices = [index]
                current.width = size.width
                current.height = size.height
            } else {
                current.indices.append(index)
                current.width = needed
                current.height = max(current.height, size.height)
            }
        }

        if !current.indices.isEmpty {
            rows.append(current)
        }
        return rows
    }
}

#Preview {
    ZStack {
        AtmosphericBackground()

        VStack(alignment: .leading, spacing: Spacing.xl) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("COMMON")
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.textTertiary)
                    .tracking(1.5)

                ScrollingChipRow(
                    items: ["Oil change", "Tire rotation", "Brake pads", "Air filter"],
                    label: { $0 },
                    isSelected: { $0 == "Oil change" },
                    onTap: { _ in }
                )
            }

            WrappingChipRow(
                items: ["Today", "Yesterday", "Earlier…", "In 3 months", "In 6 months", "At mileage…"],
                label: { $0 },
                isSelected: { $0 == "Today" },
                onTap: { _ in }
            )
        }
        .padding(Spacing.screenHorizontal)
    }
    .preferredColorScheme(.dark)
}
