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

#Preview {
    ZStack {
        Theme.backgroundPrimary.ignoresSafeArea()
        OriginalValueHint(text: L10n.editWas("48,000 MI"))
            .padding(Spacing.screenHorizontal)
    }
    .preferredColorScheme(.dark)
}
