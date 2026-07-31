//
//  BrutalistTabBar.swift
//  checkpoint
//
//  Custom tab bar with brutalist monospace aesthetic + Liquid Glass
//  Following AESTHETIC.md: sharp corners, underline indicators, fade-only transitions
//

import SwiftUI

struct BrutalistTabBar: View {
    @Binding var selectedTab: Tab
    /// Opens the unified service form. There is no second action.
    var onAddTapped: (() -> Void)?

    var body: some View {
        HStack(alignment: .bottom, spacing: Spacing.sm) {
            // Tab buttons in glass container
            HStack(spacing: 0) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    tabButton(for: tab)
                }
            }
            .frame(height: 48)
            .glassEffect(.clear.tint(Theme.surfaceInstrument), in: Rectangle())

            // ONE add action, going straight to the form.
            //
            // `[+]` used to expand into `[LOG]` and `[SCHEDULE]`, which made the
            // user classify their own intent before the app would let them
            // describe anything — and did it in the tab bar, before they had
            // even seen the form. The form now derives that from "when", so the
            // fork has nothing left to choose between: it was one extra tap
            // guarding a question with no answer yet.
            if let onAddTapped {
                Button {
                    HapticService.shared.lightImpact()
                    onAddTapped()
                } label: {
                    Text("[+]")
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.backgroundPrimary)
                        .tracking(1)
                        .padding(.horizontal, Spacing.md)
                        .frame(maxHeight: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .frame(height: 48)
                .glassEffect(.clear.tint(Theme.textPrimary), in: Rectangle())
                .accessibilityLabel(L10n.tabBarAddService)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.bottom, Spacing.sm)
    }

    private func tabButton(for tab: Tab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            selectedTab = tab
            HapticService.shared.tabChanged()
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: tab.icon)
                    .font(.system(size: 14, weight: .semibold))

                Text(tab.title)
                    .font(.brutalistLabel)
                    .tracking(2)
                    .fixedSize()
            }
            .foregroundStyle(isSelected ? Theme.accent : Theme.textTertiary)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.listItem)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) {
                if isSelected {
                    Rectangle()
                        .fill(Theme.accent)
                        .frame(height: Theme.borderWidth)
                        .padding(.horizontal, Spacing.xs)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedTab: Tab = .home

        var body: some View {
            ZStack {
                // Sample content to show glass transparency
                LinearGradient(
                    colors: [Theme.backgroundPrimary, Theme.accent.opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack {
                    Spacer()

                    // Sample content behind tab bar
                    Text("Content shows through glass")
                        .font(.brutalistBody)
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.bottom, 100)
                }
            }
            .overlay(alignment: .bottom) {
                BrutalistTabBar(
                    selectedTab: $selectedTab,
                    onAddTapped: {}
                )
            }
            .preferredColorScheme(.dark)
        }
    }

    return PreviewWrapper()
}
