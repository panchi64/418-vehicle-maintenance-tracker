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
                Text("\(entry.vehicleName.uppercased()): \(service.name.uppercased()) \u{2022} \(formatDue(service.dueDescription))")
                    .font(.system(.caption, design: .monospaced))
            } icon: {
                Image(systemName: statusIcon(for: service.status))
            }
        } else {
            Text("— —")
                .font(.system(.caption, design: .monospaced))
        }
    }

    /// Abbreviate due description for inline: "500 miles remaining" → "500 MI"
    private func formatDue(_ description: String) -> String {
        let upper = description.uppercased()
        if upper.contains("MILES") {
            // Extract number
            let number = upper.components(separatedBy: CharacterSet.decimalDigits.inverted)
                .filter { !$0.isEmpty }
                .first ?? ""
            if upper.contains("OVERDUE") {
                return "\(number) MI OVER"
            } else if upper.contains("REMAINING") {
                return "\(number) MI"
            } else {
                return "\(number) MI"
            }
        }
        // Fallback: abbreviate days
        return upper
            .replacingOccurrences(of: "DUE IN ", with: "")
            .replacingOccurrences(of: " DAYS", with: "D")
            .replacingOccurrences(of: " DAY", with: "D")
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
