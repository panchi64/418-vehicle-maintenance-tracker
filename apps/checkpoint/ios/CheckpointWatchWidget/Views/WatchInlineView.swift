//
//  WatchInlineView.swift
//  CheckpointWatchWidget
//
//  Inline Watch complication: "OVERDUE OIL CHANGE • 500 MI OVER"
//  Brutalist: monospace, uppercase
//

import SwiftUI
import WidgetKit

struct WatchInlineView: View {
    let entry: WatchWidgetEntry

    var body: some View {
        if let service = entry.service {
            let name = service.name.uppercased()
            let nameAndDue = "\(name) \u{2022} \(WatchWidgetDisplay.compactDue(for: service, entry: entry))"
            let word = service.status.label
            // Inline renders only text and one image: the symbol mirrors the
            // status shape, and the word leads when there is room.
            ViewThatFits {
                line(word.isEmpty ? nameAndDue : "\(word) \(nameAndDue)", status: service.status)
                line(nameAndDue, status: service.status)
                line(name, status: service.status)
            }
        } else {
            Text("NO SERVICES DUE")
        }
    }

    private func line(_ text: String, status: WatchWidgetStatus) -> some View {
        Label {
            Text(verbatim: text)
                .font(.system(.body, design: .monospaced))
        } icon: {
            Image(systemName: status.symbolName)
        }
    }
}
