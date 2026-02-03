//
//  ErrorMessageRow.swift
//  checkpoint
//
//  Reusable inline error message component with dismiss action
//

import SwiftUI

struct ErrorMessageRow: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.statusOverdue)

            Text(message.uppercased())
                .font(.brutalistLabel)
                .foregroundStyle(Theme.statusOverdue)
                .tracking(1)

            Spacer()

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.textTertiary)
                    .minimumTouchTarget()
            }
        }
        .padding(Spacing.md)
        .background(Theme.statusOverdue.opacity(0.1))
        .overlay(
            Rectangle()
                .strokeBorder(Theme.statusOverdue.opacity(0.5), lineWidth: Theme.borderWidth)
        )
    }
}

#Preview {
    ZStack {
        Theme.backgroundPrimary
            .ignoresSafeArea()

        VStack(spacing: Spacing.lg) {
            ErrorMessageRow(message: L10n.errorInvalidVINFormat) {
                print("Dismissed")
            }

            ErrorMessageRow(message: L10n.errorCouldNotReadOdometer) {
                print("Dismissed")
            }

            ErrorMessageRow(message: L10n.errorNetworkConnectionFailed) {
                print("Dismissed")
            }
        }
        .padding(Spacing.screenHorizontal)
    }
    .preferredColorScheme(.dark)
}
