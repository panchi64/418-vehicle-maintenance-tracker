//
//  ThemePickerView.swift
//  checkpoint
//
//  Theme selection view accessible from Settings
//

import SwiftUI

struct ThemePickerView: View {
    @Environment(AppState.self) private var appState

    private var themeManager: ThemeManager { ThemeManager.shared }

    var body: some View {
        ZStack {
            Theme.backgroundPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.md) {
                    ForEach(themeManager.allThemes) { theme in
                        Button {
                            handleThemeTap(theme)
                        } label: {
                            ThemePreviewCard(
                                theme: theme,
                                isActive: themeManager.current.id == theme.id,
                                isOwned: themeManager.isOwned(theme)
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    // Hint for locked rare themes
                    Text("Tip to unlock exclusive rare themes")
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.textTertiary)
                        .padding(.top, Spacing.sm)
                }
                .padding(Spacing.screenHorizontal)
                .padding(.top, Spacing.lg)
            }
        }
        .navigationTitle("Theme")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func handleThemeTap(_ theme: ThemeDefinition) {
        if themeManager.isOwned(theme) {
            themeManager.activateTheme(theme.id)
            AnalyticsService.shared.capture(.themeActivated(themeID: theme.id))
            HapticService.shared.selectionChanged()
        } else if theme.tier == .pro {
            appState.showProPaywall = true
        } else if theme.tier == .rare {
            // Rare locked themes: show toast directing user to Tip Jar
            ToastService.shared.show(
                "Unlock in Tip Jar",
                icon: "lock.open.fill",
                style: .info
            )
            HapticService.shared.selectionChanged()
        }
    }
}
