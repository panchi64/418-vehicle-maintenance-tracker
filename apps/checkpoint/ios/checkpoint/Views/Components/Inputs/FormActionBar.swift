//
//  FormActionBar.swift
//  checkpoint
//
//  Single bottom action bar shared by every data-entry form (G1): one
//  primary action, an optional secondary action, and a success flash for
//  forms that stay open after saving (e.g. "Save & add another").
//

import SwiftUI

struct FormActionBar: View {
    let primaryTitle: String
    let isPrimaryEnabled: Bool
    let onPrimary: () -> Void
    var onDisabledPrimaryTap: (() -> Void)? = nil
    var secondaryTitle: String? = nil
    var onSecondary: (() -> Void)? = nil
    var successFlash: Binding<String?> = .constant(nil)
    var isKeyboardVisible: Bool = false

    var body: some View {
        if isKeyboardVisible {
            EmptyView()
        } else {
            content
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.vertical, Spacing.sm)
                .background(Theme.backgroundElevated)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Theme.gridLine)
                        .frame(height: Theme.borderWidth)
                }
                .animation(.easeInOut(duration: Theme.animationMedium), value: successFlash.wrappedValue)
                .task(id: successFlash.wrappedValue) {
                    guard successFlash.wrappedValue != nil else { return }
                    try? await Task.sleep(for: .seconds(1.5))
                    if !Task.isCancelled {
                        successFlash.wrappedValue = nil
                    }
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if let flashMessage = successFlash.wrappedValue {
            Text(flashMessage.uppercased())
                .font(.brutalistBody)
                .textCase(.uppercase)
                .tracking(1)
                .foregroundStyle(Theme.statusGood)
                .frame(maxWidth: .infinity)
                .frame(minHeight: Theme.buttonHeight)
                .transition(.opacity)
                .accessibilityLabel(flashMessage)
        } else {
            HStack(spacing: Spacing.sm) {
                if let secondaryTitle, let onSecondary {
                    Button(secondaryTitle, action: onSecondary)
                        .buttonStyle(.secondary)
                }

                Button {
                    if isPrimaryEnabled {
                        onPrimary()
                    } else {
                        onDisabledPrimaryTap?()
                    }
                } label: {
                    Text(primaryTitle)
                }
                .buttonStyle(.primary)
                .opacity(isPrimaryEnabled ? 1.0 : 0.4)
            }
        }
    }
}

#Preview {
    VStack {
        Spacer()
        Text("Form content scrolls above")
            .foregroundStyle(Theme.textPrimary)
        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Theme.backgroundPrimary)
    .safeAreaInset(edge: .bottom) {
        FormActionBar(
            primaryTitle: "SAVE",
            isPrimaryEnabled: false,
            onPrimary: {},
            secondaryTitle: "SAVE & ADD ANOTHER",
            onSecondary: {}
        )
    }
    .preferredColorScheme(.dark)
}
