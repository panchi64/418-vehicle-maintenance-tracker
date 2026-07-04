//
//  OriginalValueHint.swift
//  checkpoint
//
//  Shows a field's original value while editing, only for as long as the
//  current value differs from it (G8). Never a permanent badge.
//

import SwiftUI

struct OriginalValueHint: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.brutalistLabel)
            .foregroundStyle(Theme.textTertiary)
            .tracking(0.5)
            .accessibilityLabel(text)
    }
}

extension OriginalValueHint {
    static func value(forDate date: Date?) -> String {
        date.map { Formatters.shortDate.string(from: $0) } ?? L10n.impactNone
    }

    static func value(forMileage mileage: Int?) -> String {
        mileage.map { Formatters.mileage($0) } ?? L10n.impactNone
    }

    static func value(forMonths months: Int?) -> String {
        months.map { "\($0) mo" } ?? L10n.impactNone
    }
}

#Preview {
    ZStack {
        Theme.backgroundPrimary.ignoresSafeArea()
        OriginalValueHint(text: L10n.editWas("48,000 MI"))
            .padding(Spacing.screenHorizontal)
    }
    .preferredColorScheme(.dark)
}
