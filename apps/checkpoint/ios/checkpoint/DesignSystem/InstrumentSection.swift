//
//  InstrumentSection.swift
//  checkpoint
//
//  Reusable section wrapper: header + content with brutalist card styling
//

import SwiftUI

struct InstrumentSection<Content: View, Trailing: View>: View {
    /// `.boxed` gives the content a bordered instrument-panel background;
    /// `.plain` renders header + content with no extra chrome, for use where
    /// the content's own fields (Instrument*) already carry their own borders
    /// and boxing would double them up.
    enum Chrome {
        case boxed
        case plain
    }

    let title: String
    let trailing: Trailing?
    /// Uppercase-tracked tag rendered in the header's trailing slot, e.g. "OPTIONAL" (G6).
    let tag: String?
    let chrome: Chrome
    let content: Content

    init(
        title: String,
        tag: String? = nil,
        chrome: Chrome = .boxed,
        @ViewBuilder content: () -> Content
    ) where Trailing == EmptyView {
        self.title = title
        self.trailing = nil
        self.tag = tag
        self.chrome = chrome
        self.content = content()
    }

    init(
        title: String,
        tag: String? = nil,
        chrome: Chrome = .boxed,
        @ViewBuilder trailing: () -> Trailing,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.trailing = trailing()
        self.tag = tag
        self.chrome = chrome
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            InstrumentSectionHeader(title: title) {
                HStack(spacing: Spacing.sm) {
                    if let tag {
                        Text(tag.uppercased())
                            .font(.brutalistLabel)
                            .foregroundStyle(Theme.textTertiary)
                            .tracking(1.5)
                    }
                    if let trailing {
                        trailing
                    }
                }
            }

            switch chrome {
            case .boxed:
                content
                    .background(Theme.surfaceInstrument)
                    .clipShape(Rectangle())
                    .brutalistBorder()
            case .plain:
                content
            }
        }
    }
}
