//
//  WatchRectangularView.swift
//  CheckpointWatchWidget
//
//  Rectangular Watch complication: 2px status bar + vehicle + service + due info
//  Brutalist: monospace, uppercase, sharp edges
//

import SwiftUI
import WidgetKit

struct WatchRectangularView: View {
    let entry: WatchWidgetEntry

    var body: some View {
        if let service = entry.service {
            HStack(spacing: 6) {
                // Status bar — 2px wide, sharp rectangle (brutalist)
                Rectangle()
                    .fill(service.status.color)
                    .frame(width: 2)

                VStack(alignment: .leading, spacing: 1) {
                    // Vehicle name — 40% opacity
                    Text(entry.vehicleName.uppercased())
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .opacity(0.4)

                    // Service name — full opacity, bold
                    Text(service.name.uppercased())
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .lineLimit(1)

                    // Due description — status colored
                    Text(service.dueDescription.uppercased())
                        .font(.system(size: 9, weight: .regular, design: .monospaced))
                        .foregroundStyle(service.status.color)
                }

                Spacer(minLength: 0)
            }
        } else {
            HStack(spacing: 6) {
                Rectangle()
                    .fill(.green)
                    .frame(width: 2)
                Text("— NO SERVICES DUE —")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .opacity(0.4)
                Spacer(minLength: 0)
            }
        }
    }
}
