//
//  StatsCard.swift
//  checkpoint
//
//  Compact stat card with label and value, used in stats rows
//

import SwiftUI

struct StatsCard: View {
    let label: String
    let value: String
    let valueColor: Color
    let subvalue: String?
    let subvalueColor: Color

    init(
        label: String,
        value: String,
        valueColor: Color = Theme.textPrimary,
        subvalue: String? = nil,
        subvalueColor: Color = Theme.textTertiary
    ) {
        self.label = label
        self.value = value
        self.valueColor = valueColor
        self.subvalue = subvalue
        self.subvalueColor = subvalueColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1)

            Text(value)
                .font(.brutalistHeading)
                .foregroundStyle(valueColor)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            if let subvalue {
                Text(subvalue)
                    .font(.brutalistLabel)
                    .foregroundStyle(subvalueColor)
                    .tracking(0.5)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(Theme.surfaceInstrument)
        .brutalistBorder()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)\(subvalue.map { ", \($0)" } ?? "")")
    }
}

#Preview {
    ZStack {
        AtmosphericBackground()

        VStack(spacing: Spacing.lg) {
            HStack(spacing: Spacing.md) {
                StatsCard(label: "SERVICES", value: "12")
                StatsCard(label: "AVG COST", value: "$87")
                StatsCard(label: "PER MILE", value: "$0.15/mi", valueColor: Theme.accent)
            }

            HStack(spacing: Spacing.md) {
                StatsCard(label: "TOTAL", value: "$1,234", valueColor: Theme.accent)
                StatsCard(label: "COUNT", value: "45")
            }
        }
        .padding(Spacing.screenHorizontal)
    }
    .preferredColorScheme(.dark)
}
