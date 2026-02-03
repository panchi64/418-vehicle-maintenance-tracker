//
//  ToastView.swift
//  checkpoint
//
//  Brutalist toast notification with optional action button
//

import SwiftUI

struct ToastView: View {
    let toast: ToastService.Toast

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Message
            Text(toast.message)
                .font(.brutalistBody)
                .foregroundStyle(Theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Optional action button
            if let action = toast.action {
                Button {
                    action.handler()
                    ToastService.shared.dismiss()
                } label: {
                    Text(action.label.uppercased())
                        .font(.brutalistLabelBold)
                        .foregroundStyle(Theme.accent)
                        .tracking(1.5)
                }
                .buttonStyle(.instrument)
            }

            // Dismiss button
            Button {
                ToastService.shared.dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.textTertiary)
            }
            .buttonStyle(.instrument)
        }
        .padding(Spacing.md)
        .background(Theme.surfaceInstrument)
        .overlay(
            Rectangle()
                .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
        )
    }
}

#Preview {
    ZStack {
        Theme.backgroundPrimary
            .ignoresSafeArea()

        VStack(spacing: Spacing.lg) {
            ToastView(toast: ToastService.Toast(
                message: "Daily Driver deleted",
                action: ToastService.ToastAction(label: "UNDO", handler: { print("Undo") })
            ))

            ToastView(toast: ToastService.Toast(
                message: "Service completed successfully",
                action: nil
            ))
        }
        .padding(Spacing.screenHorizontal)
    }
    .preferredColorScheme(.dark)
}
