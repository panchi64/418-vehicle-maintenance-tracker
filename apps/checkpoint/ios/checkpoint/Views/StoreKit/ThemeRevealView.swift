//
//  ThemeRevealView.swift
//  checkpoint
//
//  Reveal animation when a rare theme is unlocked
//

import SwiftUI

struct ThemeRevealView: View {
    @Environment(\.dismiss) private var dismiss
    let theme: ThemeDefinition

    @State private var isRevealed = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundPrimary.ignoresSafeArea()

                VStack(spacing: Spacing.lg) {
                    Spacer()

                    // Theme unlock header
                    VStack(spacing: Spacing.md) {
                        Text("THEME UNLOCKED")
                            .font(.brutalistLabel)
                            .foregroundStyle(Theme.accent)
                            .tracking(2)

                        Text(theme.displayName)
                            .font(.brutalistTitle)
                            .foregroundStyle(Theme.textPrimary)

                        // Color swatches
                        HStack(spacing: Spacing.sm) {
                            ForEach(theme.previewColors, id: \.self) { hex in
                                Rectangle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Rectangle()
                                            .strokeBorder(Theme.gridLine, lineWidth: 1)
                                    )
                            }
                        }

                        Text(theme.description)
                            .font(.brutalistSecondary)
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.lg)
                    }
                    .opacity(isRevealed ? 1 : 0)

                    Spacer()

                    // Action buttons
                    VStack(spacing: Spacing.md) {
                        Button {
                            ThemeManager.shared.activateTheme(theme.id)
                            AnalyticsService.shared.capture(.themeActivated(themeID: theme.id))
                            dismiss()
                        } label: {
                            Text("APPLY NOW")
                        }
                        .buttonStyle(.primary)

                        Button {
                            dismiss()
                        } label: {
                            Text("Later")
                                .font(.brutalistSecondary)
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.bottom, Spacing.lg)
                    .opacity(isRevealed ? 1 : 0)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .toolbarButtonStyle()
                }
            }
        }
        .presentationDetents([.medium])
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                isRevealed = true
            }
        }
    }
}
