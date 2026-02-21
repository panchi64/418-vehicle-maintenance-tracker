//
//  InstrumentSection.swift
//  checkpoint
//
//  Reusable section wrapper: header + content with brutalist card styling
//

import SwiftUI

struct InstrumentSection<Content: View, Trailing: View>: View {
    let title: String
    let trailing: Trailing?
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) where Trailing == EmptyView {
        self.title = title
        self.trailing = nil
        self.content = content()
    }

    init(title: String, @ViewBuilder trailing: () -> Trailing, @ViewBuilder content: () -> Content) {
        self.title = title
        self.trailing = trailing()
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if let trailing {
                InstrumentSectionHeader(title: title) { trailing }
            } else {
                InstrumentSectionHeader(title: title)
            }

            content
                .background(Theme.surfaceInstrument)
                .clipShape(Rectangle())
                .brutalistBorder()
        }
    }
}
