//
//  ServiceRowView.swift
//  CheckpointWatch
//
//  Individual service row in Watch services list
//  Brutalist: status square, monospace, ALL CAPS
//

import SwiftUI

struct ServiceRowView: View {
    let service: WatchService

    var body: some View {
        HStack(spacing: WatchSpacing.md) {
            // Status square (8x8pt, zero radius)
            StatusSquare(status: service.status)

            VStack(alignment: .leading, spacing: WatchSpacing.xs) {
                Text(service.name.uppercased())
                    .font(.watchLabel)
                    .foregroundStyle(WatchColors.textPrimary)
                    .lineLimit(1)

                Text(service.dueDescription.uppercased())
                    .font(.watchCaption)
                    .foregroundStyle(service.status.color)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
    }
}
