//
//  StatusDot.swift
//  checkpoint
//
//  8pt status indicator dot
//

import SwiftUI

struct StatusDot: View {
    let status: ServiceStatus

    var body: some View {
        Circle()
            .fill(status.color)
            .frame(width: 8, height: 8)
            .accessibilityLabel(status.label.isEmpty ? "No status" : status.label)
    }
}

#Preview {
    HStack(spacing: 20) {
        StatusDot(status: .overdue)
        StatusDot(status: .dueSoon)
        StatusDot(status: .good)
        StatusDot(status: .neutral)
    }
    .padding()
    .background(Theme.backgroundPrimary)
}
