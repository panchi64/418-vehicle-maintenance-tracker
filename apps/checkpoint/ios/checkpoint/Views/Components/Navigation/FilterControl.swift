//
//  FilterControl.swift
//  checkpoint
//
//  The filter half of a readout tab's single control row.
//
//  WHAT WAS WRONG. Services and Costs each had TWO stacked control rows: a
//  segmented control plus a horizontally-scrolling chip row. Three faults:
//
//    1. The scrolling chip row HID OPTIONS off the right edge. "On track" was
//       cut to "ON TR…" on Services and three of six categories were off-screen
//       on Costs. A filter whose options you must scroll to discover fails
//       recognition-over-recall — you have to already know what is there.
//    2. Two rows of chrome before any content, on a tab whose job is showing
//       content. Costs reached four rows counting both segmented controls.
//    3. Chips and a segmented control are two different visual vocabularies for
//       the same job — pick one of N — and both rendered a filled accent block,
//       so two slabs competed at the top of the screen.
//
//  WHAT THIS DOES INSTEAD. The filter collapses to a single bracket-notation
//  trigger that opens a full list. That means one control row per tab; nothing
//  hidden off an edge, since the list is vertical and scales to six categories
//  as easily as to four statuses; counts beside each option; and no third
//  control vocabulary, because brackets already mean "this text is a control"
//  in `[SELECT]` and `[UPDATE]`.
//
//  Filtering is refinement, not the default path, so it earns a trigger rather
//  than permanent real estate. The segmented control keeps its row because a
//  view or period switch changes what the screen IS, not merely what it shows.
//
//  THE TRIGGER SHOWS THE DIMENSION, NOT THE VALUE — `[CATEGORY ⌄]`, never
//  `[MAINTENANCE ⌄]`. A first attempt labelled it with the selected value, which
//  seemed more informative and broke the row: selecting "Maintenance" widened
//  the trigger, which crushed the segmented control beside it until `ALL`
//  collided with it. Any control whose width depends on its own value cannot
//  share a fixed row with another control. Constant width is the requirement,
//  and the active value is surfaced by `ActiveFilterBar` instead, where it has a
//  whole row and cannot truncate.
//

import SwiftUI

/// A tab's complete chrome: the control row, the filter's expanded band, and the
/// active-filter bar.
///
/// These are one component rather than three because the expanded option band
/// has to span the full screen width — a panel floating under a right-aligned
/// trigger would truncate labels at exactly the moment the user is reading them.
/// Owning the row means the band can be a sibling of it rather than an overlay,
/// so nothing clips and nothing needs a z-index.
struct FilterControlRow<Value: Hashable, Leading: View>: View {
    /// Names the dimension, e.g. "Status". Also the accessible label.
    let name: String
    let options: [PickerOption<Value>]
    @Binding var selection: Value
    /// The value meaning "no filter". Shown as cleared, and clearable in one tap.
    let defaultValue: Value
    /// The control that keeps its row — a view or period switch, which changes
    /// what the screen *is* rather than merely what it shows.
    @ViewBuilder let leading: Leading

    @State private var isExpanded = false

    private var isFiltered: Bool { selection != defaultValue }

    var body: some View {
        VStack(spacing: 0) {
            ControlRow {
                leading
                trigger
            }

            if isExpanded {
                OptionList(options: options, selection: selection) { value in
                    selection = value
                    withAnimation(.easeOut(duration: Theme.animationFast)) {
                        isExpanded = false
                    }
                }
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(Theme.gridLine)
                        .frame(height: Theme.borderWidth)
                }
            }

            ActiveFilterBar(
                name: name,
                options: options,
                selection: selection,
                defaultValue: defaultValue
            ) {
                selection = defaultValue
            }
        }
    }

    private var trigger: some View {
        Button {
            withAnimation(.easeOut(duration: Theme.animationFast)) {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: Spacing.xs) {
                Text("[\(name.uppercased())")
                    .font(.brutalistLabel)
                    .tracking(1)

                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))

                Text("]")
                    .font(.brutalistLabel)
                    .tracking(1)
            }
            .foregroundStyle(isFiltered ? Theme.accent : Theme.textTertiary)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, Spacing.sm)
            .frame(minHeight: TouchTarget.minimum)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: Theme.animationMedium), value: isExpanded)
        .accessibilityLabel(L10n.filterDimension(name))
        .accessibilityValue(options.first { $0.value == selection }?.label ?? "")
        .accessibilityAddTraits(isExpanded ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Active filter bar

/// States the filter currently narrowing the screen, and clears it.
///
/// Renders ONLY when a filter is active, so the default screen still has one row
/// of chrome. This row is a consequence of the user's own action rather than
/// permanent furniture, which is the difference between it and the old
/// always-present filter-indicator row.
///
/// It also earns its space by answering the question the old scrolling chip row
/// couldn't: *what am I currently looking at, and how do I stop?*
struct ActiveFilterBar<Value: Hashable>: View {
    let name: String
    let options: [PickerOption<Value>]
    let selection: Value
    let defaultValue: Value
    let onClear: () -> Void

    var body: some View {
        if selection != defaultValue,
           let active = options.first(where: { $0.value == selection }) {
            HStack(spacing: Spacing.sm) {
                Rectangle()
                    .fill(Theme.accent)
                    .frame(width: Theme.borderWidth, height: 14)
                    .accessibilityHidden(true)

                Text(name.uppercased())
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.textTertiary)
                    .tracking(1.5)

                Text(active.label)
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1)

                if let count = active.count {
                    Text(String(count))
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.textTertiary)
                        .monospacedDigit()
                }

                // Clearing is one tap, not "reopen the list and find All again".
                Button(action: onClear) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                        .frame(width: TouchTarget.minimum, height: TouchTarget.minimum)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.filterClear(name))
            }
            .padding(.leading, Spacing.screenHorizontal)
            .padding(.trailing, Spacing.screenHorizontal - Spacing.sm)
            .frame(minHeight: TouchTarget.minimum)
            .background(Theme.backgroundSubtle)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Theme.gridLine)
                    .frame(height: Theme.borderWidth)
            }
        }
    }
}

// MARK: - Control row

/// The one row of chrome a readout tab is allowed by default.
struct ControlRow<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: Spacing.sm) {
            content
        }
        .padding(.horizontal, Spacing.screenHorizontal)
        .padding(.vertical, Spacing.sm)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Theme.gridLine)
                .frame(height: Theme.borderWidth)
        }
    }
}

#Preview {
    @Previewable @State var status = "overdue"

    let options = [
        PickerOption(value: "all", label: "All", count: 24),
        PickerOption(value: "overdue", label: "Overdue", count: 2),
        PickerOption(value: "dueSoon", label: "Due soon", count: 5),
        PickerOption(value: "onTrack", label: "On track", count: 17)
    ]

    return ZStack {
        AtmosphericBackground()

        VStack(spacing: 0) {
            FilterControlRow(
                name: "Status",
                options: options,
                selection: $status,
                defaultValue: "all"
            ) {
                Text("SEGMENTED CONTROL")
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.textTertiary)
                    .frame(maxWidth: .infinity)
            }

            Spacer()
        }
    }
    .preferredColorScheme(.dark)
}
