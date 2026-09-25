//
//  FormActionBar.swift
//  checkpoint
//
//  Single bottom action bar shared by every data-entry form (F1): one
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

    /// F3: the bar must never ride above the keyboard (it would eat
    /// number-pad space and invite accidental saves). Observed here rather
    /// than threaded by every caller, so no form can silently opt out.
    private var isKeyboardVisible: Bool {
        KeyboardVisibility.shared.isVisible
    }

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
            // Two long titles can't share a row at accessibility sizes; the
            // primary stacks under the secondary, staying nearest the thumb.
            AccessibilityAdaptiveStack(verticalSpacing: Spacing.sm) {
                if let secondaryTitle, let onSecondary {
                    Button(secondaryTitle, action: onSecondary)
                        .buttonStyle(.secondary)
                }

                Button {
                    if isPrimaryEnabled {
                        onPrimary()
                    } else {
                        // F2: every form gets the same disabled-save feedback;
                        // callers only supply the scroll-to-field behavior.
                        HapticService.shared.error()
                        onDisabledPrimaryTap?()
                    }
                } label: {
                    Text(primaryTitle)
                }
                .buttonStyle(.primary)
                .opacity(isPrimaryEnabled ? 1.0 : 0.4)
                // Not `.disabled`: that would swallow the F2 tap. VoiceOver
                // still needs to hear that Save won't save yet, and that
                // activating it takes you to what's missing.
                .accessibilityValue(isPrimaryEnabled ? "" : L10n.a11ySaveUnavailable)
                .accessibilityHint(isPrimaryEnabled ? "" : L10n.a11ySaveUnavailableHint)
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
