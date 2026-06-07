//
//  AccessoryInlineView.swift
//  CheckpointWidget
//
//  Inline lock screen widget showing next service
//  Brutalist-Tech-Modernist aesthetic: uppercase monospace
//

import SwiftUI
import WidgetKit

struct AccessoryInlineView: View {
    let entry: ServiceEntry

    var body: some View {
        if let service = entry.services.first {
            Label {
                Text("\(service.name.uppercased()) \u{2022} \(formatDue(service.dueDescription))")
                    .font(.system(.caption, design: .monospaced))
            } icon: {
                Image(systemName: statusIcon(for: service.status))
            }
        } else {
            Text("— —")
                .font(.system(.caption, design: .monospaced))
        }
    }

    /// Abbreviate due description for inline: "500 miles remaining" → "500 MI" or "500 KM"
    private func formatDue(_ description: String) -> String {
        let unit = entry.distanceUnit
        let upper = description.uppercased()
        if upper.contains("MILES") || upper.contains("KILOMETERS") {
            // Extract number
            let number = upper.components(separatedBy: CharacterSet.decimalDigits.inverted)
                .filter { !$0.isEmpty }
                .first ?? ""
            if upper.contains("OVERDUE") {
                return "\(number) \(unit.uppercaseAbbreviation) OVER"
            } else if upper.contains("REMAINING") {
                return "\(number) \(unit.uppercaseAbbreviation)"
            } else {
                return "\(number) \(unit.uppercaseAbbreviation)"
            }
        }
        // Date-based items read as an abstracted period ("DUE MID MAY"); drop the
        // leading verb so the compact inline slot shows just "MID MAY".
        return upper
            .replacingOccurrences(of: "DUE ", with: "")
            .replacingOccurrences(of: "EXPIRES ", with: "")
    }

    private func statusIcon(for status: WidgetServiceStatus) -> String {
        switch status {
        case .overdue: return "exclamationmark.triangle"
        case .dueSoon: return "clock"
        case .good: return "checkmark.circle"
        case .neutral: return "minus.circle"
        }
    }
}

#Preview(as: .accessoryInline) {
    CheckpointWidget()
} timeline: {
    ServiceEntry.placeholder
    ServiceEntry.empty
}
