//
//  ThemePickerView.swift
//  checkpoint
//
//  Theme selection view accessible from Settings
//

import SwiftUI

struct ThemePickerView: View {
    /// Local rather than the root router's `.proPaywall`: this screen lives
    /// inside the Settings sheet, and the root can show one sheet at a time —
    /// routing it there would close Settings to make room.
    @State private var showProPaywall = false

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
                    Text(L10n.settingsThemeRareHint)
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.textTertiary)
                        .padding(.top, Spacing.sm)
                }
                .padding(Spacing.screenHorizontal)
                .padding(.top, Spacing.lg)
            }
        }
        .navigationTitle(L10n.settingsTheme)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showProPaywall) {
            ProPaywallSheet()
        }
    }

    private func handleThemeTap(_ theme: ThemeDefinition) {
        if themeManager.isOwned(theme) {
            themeManager.activateTheme(theme.id)
            AnalyticsService.shared.capture(.themeActivated(themeID: theme.id))
            HapticService.shared.selectionChanged()
        } else if theme.tier == .pro {
            showProPaywall = true
        } else if theme.tier == .rare {
            // Rare locked themes: show toast directing user to Tip Jar
            ToastService.shared.show(
                L10n.settingsThemeUnlockInTipJar,
                icon: "lock.open.fill",
                style: .info
            )
            HapticService.shared.selectionChanged()
        }
    }
}
