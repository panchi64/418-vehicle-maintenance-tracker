//
//  DestructiveFormButton.swift
//  checkpoint
//
//  The destructive action at the bottom of an edit form or detail screen
//  (Delete Vehicle, Delete Entry). Lives at the end of the scroll, never in
//  `FormActionBar` — Save and Delete must not sit side by side (F1).
//

import SwiftUI

struct DestructiveFormButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "trash")
                    .accessibilityHidden(true)
                Text(title)
            }
            .font(.body.weight(.semibold))
            .foregroundStyle(Theme.statusOverdue)
            .padding(.vertical, Spacing.sm)
            .frame(maxWidth: .infinity)
            .frame(minHeight: Theme.buttonHeight)
            .background(Theme.statusOverdue.opacity(0.1))
            .clipShape(Rectangle())
            .overlay(
                Rectangle()
                    .strokeBorder(Theme.statusOverdue.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

#Preview {
    ZStack {
        Theme.backgroundPrimary.ignoresSafeArea()
        DestructiveFormButton(title: "Delete Entry") {}
            .padding(Spacing.screenHorizontal)
    }
    .preferredColorScheme(.dark)
}
