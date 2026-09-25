//
//  AccessoryInlineView.swift
//  CheckpointWidget
//
//  Inline Lock Screen widget: "■ OVERDUE OIL CHANGE • 500 MI OVER"
//  Brutalist-Tech-Modernist aesthetic: uppercase monospace
//

import SwiftUI
import WidgetKit

struct AccessoryInlineView: View {
    let entry: ServiceEntry

    var body: some View {
        if let service = entry.services.first {
            let name = service.name.uppercased()
            let due = WidgetDisplayHelpers.compactDue(for: service, currentMileage: entry.currentMileage, distanceUnit: entry.distanceUnit)
            // Inline renders only text and one image. The SF Symbol mirrors the
            // status shape; the word leads when there is room for it.
            let nameAndDue = "\(name) \u{2022} \(due)"
            let word = service.status.label
            ViewThatFits {
                line(word.isEmpty ? nameAndDue : "\(word) \(nameAndDue)", status: service.status)
                line(nameAndDue, status: service.status)
                line(name, status: service.status)
            }
        } else {
            Text(entry.vehicleID == nil ? "TAP TO SET UP" : "NO SERVICES DUE")
        }
    }

    private func line(_ text: String, status: WidgetServiceStatus) -> some View {
        Label {
            Text(verbatim: text)
                .font(.system(.body, design: .monospaced))
        } icon: {
            Image(systemName: status.symbolName)
        }
    }
}

#Preview(as: .accessoryInline) {
    CheckpointWidget()
} timeline: {
    ServiceEntry.placeholder
    ServiceEntry.empty
}
