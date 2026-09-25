//
//  InstrumentSegmentedControl.swift
//  checkpoint
//
//  Custom pill selector with amber highlight for instrument cluster aesthetic
//

import SwiftUI

struct InstrumentSegmentedControl<T: Hashable>: View {
    let options: [T]
    @Binding var selection: T
    let labelFor: (T) -> String

    @Namespace private var namespace
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Side by side until accessibility sizes, where even two short labels
    /// can't share a row — the segments stack instead of truncating.
    private var layout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 0))
            : AnyLayout(HStackLayout(spacing: 0))
    }

    var body: some View {
        layout {
            ForEach(options, id: \.self) { option in
                segmentButton(for: option)
            }
        }
        // Every segment takes the tallest one's height, so a label that wraps
        // doesn't leave its neighbours' highlights short.
        .fixedSize(horizontal: false, vertical: true)
        .padding(Spacing.xs)
        .background(Theme.surfaceInstrument)
        .brutalistBorder()
    }

    private func segmentButton(for option: T) -> some View {
        let isSelected = selection == option

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selection = option
            }
            HapticService.shared.selectionChanged()
        } label: {
            Text(labelFor(option).uppercased())
                .font(.brutalistLabel)
                .foregroundStyle(isSelected ? Theme.surfaceInstrument : Theme.textSecondary)
                .tracking(1)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.listItem)
                .padding(.vertical, Spacing.listItem)
                .frame(maxWidth: .infinity, minHeight: TouchTarget.minimum, maxHeight: .infinity)
                .contentShape(Rectangle())
                .background {
                    if isSelected {
                        Rectangle()
                            .fill(Theme.accent)
                            .matchedGeometryEffect(id: "segment", in: namespace)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(labelFor(option))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Convenience for String-based options

extension InstrumentSegmentedControl where T == String {
    init(options: [String], selection: Binding<String>) {
        self.options = options
        self._selection = selection
        self.labelFor = { $0 }
    }
}

#Preview {
    enum Mode: String, CaseIterable {
        case log = "Log"
        case schedule = "Schedule"
    }

    struct PreviewWrapper: View {
        @State private var mode: Mode = .log

        var body: some View {
            ZStack {
                AtmosphericBackground()

                VStack(spacing: Spacing.lg) {
                    InstrumentSegmentedControl(
                        options: Mode.allCases,
                        selection: $mode
                    ) { option in
                        option.rawValue
                    }
                }
                .padding(Spacing.screenHorizontal)
            }
            .preferredColorScheme(.dark)
        }
    }

    return PreviewWrapper()
}
