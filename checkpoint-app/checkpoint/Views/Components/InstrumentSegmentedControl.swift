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

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                segmentButton(for: option)
            }
        }
        .padding(4)
        .background(Theme.surfaceInstrument)
        .overlay(
            Rectangle()
                .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
        )
    }

    private func segmentButton(for option: T) -> some View {
        let isSelected = selection == option

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selection = option
            }
        } label: {
            Text(labelFor(option).uppercased())
                .font(.instrumentLabel)
                .foregroundStyle(isSelected ? Theme.surfaceInstrument : Theme.textSecondary)
                .tracking(1)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background {
                    if isSelected {
                        Rectangle()
                            .fill(Theme.accent)
                            .matchedGeometryEffect(id: "segment", in: namespace)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Labeled Instrument Segmented Control

struct LabeledInstrumentSegmentedControl<T: Hashable>: View {
    let label: String
    let options: [T]
    @Binding var selection: T
    let labelFor: (T) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Label
            Text(label.uppercased())
                .font(.instrumentLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1.5)

            InstrumentSegmentedControl(
                options: options,
                selection: $selection,
                labelFor: labelFor
            )
        }
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

                    LabeledInstrumentSegmentedControl(
                        label: "Entry Type",
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
