//
//  BrutalistSearchField.swift
//  checkpoint
//
//  The search field at the top of the Services tab and the Documents library.
//  Tour-target annotation is applied at the call site (ServicesTab) so this
//  component stays onboarding-agnostic and can be reused without publishing a
//  duplicate `.servicesSearch` anchor.
//
//  Was `ServiceSearchField`, despite the doc comment inviting reuse — so
//  Documents grew its own identical copy rather than import a type named after
//  another feature. The name is the reason the duplicate existed.
//

import SwiftUI

struct BrutalistSearchField: View {
    @Binding var text: String
    var placeholder: String = "Search services, notes, receipts..."
    var onSearchStarted: () -> Void = {}

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Theme.textTertiary)

            TextField(placeholder, text: $text)
                .font(.brutalistBody)
                .foregroundStyle(Theme.textPrimary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($isFocused)
                // Results filter as you type, so Return has nothing left to do
                // but get the keyboard out of the way of them.
                .submitLabel(.search)
                .onSubmit { isFocused = false }
                .onChange(of: text) { oldValue, _ in
                    if oldValue.isEmpty {
                        onSearchStarted()
                    }
                }

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.textTertiary)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(Spacing.md)
        .background(Theme.surfaceInstrument)
        .brutalistBorder()
    }
}

#Preview {
    ZStack {
        AtmosphericBackground()

        VStack(spacing: Spacing.lg) {
            BrutalistSearchField(text: .constant(""))
            BrutalistSearchField(text: .constant("oil"))
        }
        .padding(Spacing.screenHorizontal)
    }
    .preferredColorScheme(.dark)
}
