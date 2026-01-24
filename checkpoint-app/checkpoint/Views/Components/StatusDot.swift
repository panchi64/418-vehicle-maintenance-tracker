//
//  StatusDot.swift
//  checkpoint
//
//  8x8 square status indicator (brutalist)
//

import SwiftUI

struct StatusDot: View {
    let status: ServiceStatus
    var showGlow: Bool = false

    var body: some View {
        Rectangle()
            .fill(status.color)
            .frame(width: 8, height: 8)
            .statusGlow(color: status.color, isActive: showGlow)
            .accessibilityLabel(status.label.isEmpty ? "No status" : status.label)
    }
}

#Preview {
    HStack(spacing: 20) {
        StatusDot(status: .overdue, showGlow: true)
        StatusDot(status: .dueSoon, showGlow: true)
        StatusDot(status: .good)
        StatusDot(status: .neutral)
    }
    .padding()
    .background(Theme.backgroundPrimary)
}
