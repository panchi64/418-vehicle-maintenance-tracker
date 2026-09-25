//
//  ServiceRowView.swift
//  CheckpointWatch
//
//  Individual service row in Watch services list
//  Brutalist: status shape + word, monospace, ALL CAPS
//

import SwiftUI

struct ServiceRowView: View {
    let service: WatchService

    var body: some View {
        VStack(alignment: .leading, spacing: WatchSpacing.xs) {
            Text(service.name.uppercased())
                .font(.watchLabel)
                .foregroundStyle(WatchColors.textPrimary)
                .lineLimit(2)

            WatchStatusTag(status: service.status)

            Text(service.dueDescription.uppercased())
                .font(.watchCaption)
                .foregroundStyle(WatchColors.textSecondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
