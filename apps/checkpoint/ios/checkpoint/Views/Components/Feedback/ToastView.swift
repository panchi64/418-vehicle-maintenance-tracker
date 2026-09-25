//
//  ToastView.swift
//  checkpoint
//
//  Brutalist toast notification with icon, style, and optional action button
//

import SwiftUI

struct ToastView: View {
    let toast: ToastService.Toast

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Icon
            if let icon = toast.icon {
                Image(systemName: icon)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(toast.style.iconColor)
                    .accessibilityHidden(true)
            }

            // Message
            Text(toast.message.uppercased())
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textPrimary)
                .tracking(1.5)
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
                        .frame(minHeight: TouchTarget.minimum)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.instrument)
                .accessibilityLabel(action.label)
            }

            // Dismiss button
            Button {
                ToastService.shared.dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.textTertiary)
                    .minimumTouchTarget()
            }
            .buttonStyle(.instrument)
            .accessibilityLabel(L10n.commonDismiss)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Theme.surfaceInstrument)
        .brutalistBorder()
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    if value.translation.height > 40 {
                        ToastService.shared.dismiss()
                    }
                }
        )
        .onTapGesture {
            ToastService.shared.dismiss()
        }
    }
}

#Preview {
    ZStack {
        Theme.backgroundPrimary
            .ignoresSafeArea()

        VStack(spacing: Spacing.lg) {
            ToastView(toast: ToastService.Toast(
                message: "Service logged",
                icon: "checkmark",
                style: .success,
                action: nil
            ))

            ToastView(toast: ToastService.Toast(
                message: "Daily Driver deleted",
                icon: "trash",
                style: .info,
                action: ToastService.ToastAction(label: "UNDO", handler: { print("Undo") })
            ))

            ToastView(toast: ToastService.Toast(
                message: "Sync issue — data saved locally",
                icon: "exclamationmark.triangle",
                style: .error,
                action: nil
            ))
        }
        .padding(Spacing.screenHorizontal)
    }
    .preferredColorScheme(.dark)
}
