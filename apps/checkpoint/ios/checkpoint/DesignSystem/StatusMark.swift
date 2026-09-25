//
//  StatusMark.swift
//  checkpoint
//
//  The one way status is drawn. Each status has its own *shape* as well as its
//  color, so the signal survives color blindness, sunlight, and the tinted
//  widget/glass renderings where hue is gone (AESTHETIC.md: meaning in color
//  alone is a [REQUIREMENT] violation):
//
//    overdue  — filled square
//    due soon — outlined square
//    good     — short rule
//    neutral  — nothing
//

import SwiftUI

/// The status shape alone. Use where the status *word* is already on screen
/// nearby (e.g. a row under a section header that names the status).
struct StatusMark: View {
    let status: ServiceStatus

    @ScaledMetric(relativeTo: .caption2) private var size: CGFloat = 8

    var body: some View {
        Group {
            switch status {
            case .overdue:
                Rectangle().fill(status.color)
                    .frame(width: size, height: size)
            case .dueSoon:
                Rectangle().strokeBorder(status.color, lineWidth: max(1.5, size / 5))
                    .frame(width: size, height: size)
            case .good:
                Rectangle().fill(status.color)
                    .frame(width: size * 1.5, height: max(2, size / 4))
                    .frame(height: size)
            case .neutral:
                EmptyView()
            }
        }
        .accessibilityHidden(true)
    }
}

/// Shape + word. The default way to state a status.
struct StatusTag: View {
    let status: ServiceStatus

    var body: some View {
        if status != .neutral {
            HStack(spacing: Spacing.xs) {
                StatusMark(status: status)
                Text(status.label)
                    .font(.brutalistLabelBold)
                    .tracking(1.5)
                    .foregroundStyle(status.color)
            }
            .accessibilityElement(children: .combine)
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: Spacing.md) {
        StatusTag(status: .overdue)
        StatusTag(status: .dueSoon)
        StatusTag(status: .good)
    }
    .padding()
    .background(Theme.backgroundPrimary)
}
