//
//  RecallCardStyle.swift
//  checkpoint
//
//  Shared border + background treatment for both the compact RecallAlertCard
//  on Home and each RecallRowCard inside the sheet. Centralized so the
//  brutalist red treatment stays consistent if Theme tokens shift.
//

import SwiftUI

extension View {
    func recallCardStyle() -> some View {
        background(Theme.statusOverdue.opacity(0.08))
            .overlay(
                Rectangle()
                    .strokeBorder(Theme.statusOverdue.opacity(0.5), lineWidth: Theme.borderWidth)
            )
    }
}
