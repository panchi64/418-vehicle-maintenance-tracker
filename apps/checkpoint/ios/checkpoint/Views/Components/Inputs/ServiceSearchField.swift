//
//  ServiceSearchField.swift
//  checkpoint
//
//  Search field used at the top of the Services tab. Tour-target annotation
//  is applied at the call site (ServicesTab) so this component stays
//  onboarding-agnostic and can be reused safely elsewhere without
//  publishing a duplicate `.servicesSearch` anchor.
//

import SwiftUI

struct ServiceSearchField: View {
    @Binding var text: String
    var placeholder: String = "Search services, notes, receipts..."
    var onSearchStarted: () -> Void = {}

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
            ServiceSearchField(text: .constant(""))
            ServiceSearchField(text: .constant("oil"))
        }
        .padding(Spacing.screenHorizontal)
    }
    .preferredColorScheme(.dark)
}
