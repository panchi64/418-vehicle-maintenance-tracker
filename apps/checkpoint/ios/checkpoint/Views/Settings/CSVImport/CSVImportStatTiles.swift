//
//  CSVImportStatTiles.swift
//  checkpoint
//
//  The services / logs / cost tiles shown by the preview and success steps.
//  Side by side at standard sizes; stacked at accessibility sizes, where
//  three tiles across leave each value a few characters wide.
//

import SwiftUI

struct CSVImportStatTiles: View {
    struct Stat: Identifiable {
        let value: String
        let label: String
        var id: String { label }
    }

    let stats: [Stat]

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: Spacing.sm))
            : AnyLayout(HStackLayout(spacing: Spacing.md))

        layout {
            ForEach(stats) { stat in
                VStack(spacing: Spacing.xs) {
                    Text(stat.value)
                        .font(.brutalistBody)
                        .foregroundStyle(Theme.textPrimary)

                    Text(stat.label)
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.textTertiary)
                        .tracking(1)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(Spacing.md)
                .background(Theme.surfaceInstrument)
                .brutalistBorder()
                .accessibilityElement(children: .combine)
            }
        }
    }
}
