//
//  WatchInlineView.swift
//  CheckpointWatchWidget
//
//  Inline Watch complication: "SERVICE • DUE_INFO"
//  Brutalist: monospace, uppercase
//

import SwiftUI
import WidgetKit

struct WatchInlineView: View {
    let entry: WatchWidgetEntry

    var body: some View {
        if let service = entry.service {
            Label {
                Text("\(service.name.uppercased()) \u{2022} \(formatDue(service.dueDescription))")
                    .font(.system(.caption, design: .monospaced))
            } icon: {
                Image(systemName: service.status.icon)
            }
        } else {
            Text("— —")
                .font(.system(.caption, design: .monospaced))
        }
    }

    /// Abbreviate due description for inline: "500 miles remaining" → "500 MI"
    private func formatDue(_ description: String) -> String {
        let unitAbbrev = entry.distanceUnit
        let upper = description.uppercased()
        if upper.contains("MILES") || upper.contains("KILOMETERS") {
            let number = upper.components(separatedBy: CharacterSet.decimalDigits.inverted)
                .filter { !$0.isEmpty }
                .first ?? ""
            if upper.contains("OVERDUE") {
                return "\(number) \(unitAbbrev) OVER"
            } else {
                return "\(number) \(unitAbbrev)"
            }
        }
        // Date-based items read as an abstracted period ("DUE MID MAY"); drop the
        // leading verb so the compact inline slot shows just "MID MAY".
        return upper
            .replacingOccurrences(of: "DUE ", with: "")
            .replacingOccurrences(of: "EXPIRES ", with: "")
    }
}
