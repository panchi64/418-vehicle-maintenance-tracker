//
//  BrutalistTabBar.swift
//  checkpoint
//
//  Custom tab bar with brutalist monospace aesthetic + Liquid Glass
//  Following AESTHETIC.md: underline indicators, minimal animations
//

import SwiftUI

struct BrutalistTabBar: View {
    @Binding var selectedTab: AppState.Tab
    var onAddTapped: (() -> Void)?

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Tab buttons in glass container
            HStack(spacing: 0) {
                ForEach(AppState.Tab.allCases, id: \.self) { tab in
                    tabButton(for: tab)
                }
            }
            .frame(height: 48)
            .glassEffect(.clear.tint(Theme.surfaceInstrument), in: RoundedRectangle(cornerRadius: 6))

            // Circular FAB to the right
            if let onAddTapped {
                Button {
                    HapticService.shared.lightImpact()
                    onAddTapped()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Theme.backgroundPrimary)
                        .frame(width: 48, height: 48)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)
                .buttonBorderShape(.circle)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.bottom, Spacing.sm)
    }

    private func tabButton(for tab: AppState.Tab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            selectedTab = tab
            HapticService.shared.tabChanged()
        } label: {
            Text(tab.title)
                .font(.brutalistLabel)
                .foregroundStyle(isSelected ? Theme.accent : Theme.textTertiary)
                .tracking(2)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.listItem)
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Theme.textPrimary.opacity(0.1))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedTab: AppState.Tab = .home

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
                    onAddTapped: { print("Add tapped") }
                )
            }
            .preferredColorScheme(.dark)
        }
    }

    return PreviewWrapper()
}
