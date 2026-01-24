//
//  FloatingActionButton.swift
//  checkpoint
//
//  Quick-add floating action button for creating new services
//

import SwiftUI

struct FloatingActionButton: View {
    var action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Theme.backgroundPrimary)
                .frame(width: 56, height: 56)
                .background(Theme.accent)
        }
    }
}

#Preview {
    ZStack {
        AtmosphericBackground()

        VStack {
            Spacer()
            HStack {
                Spacer()
                FloatingActionButton {
                    print("FAB tapped")
                }
                .padding(.trailing, Spacing.screenHorizontal)
                .padding(.bottom, Spacing.lg)
            }
        }
    }
    .preferredColorScheme(.dark)
}
