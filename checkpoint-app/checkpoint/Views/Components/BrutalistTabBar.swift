//
//  BrutalistTabBar.swift
//  checkpoint
//
//  Custom tab bar with brutalist monospace aesthetic
//  Following AESTHETIC.md: underline indicators, no animations
//

import SwiftUI

struct BrutalistTabBar: View {
    @Binding var selectedTab: AppState.Tab

    var body: some View {
        VStack(spacing: 0) {
            // Top border
            Rectangle()
                .fill(Theme.gridLine)
                .frame(height: 2)

            // Tab buttons
            HStack(spacing: 0) {
                ForEach(AppState.Tab.allCases, id: \.self) { tab in
                    tabButton(for: tab)
                }
            }
            .frame(height: 44)
        }
        .background(Theme.surfaceInstrument.ignoresSafeArea(edges: .bottom))
    }

    private func tabButton(for tab: AppState.Tab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 0) {
                Spacer()

                Text(tab.title)
                    .font(.brutalistLabel)
                    .foregroundStyle(isSelected ? Theme.accent : Theme.textTertiary)
                    .tracking(2)

                Spacer()

                // Underline indicator at bottom
                Rectangle()
                    .fill(isSelected ? Theme.accent : Color.clear)
                    .frame(height: 2)
            }
            .frame(maxWidth: .infinity)
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
                AtmosphericBackground()

                VStack {
                    Spacer()
                    BrutalistTabBar(selectedTab: $selectedTab)
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    return PreviewWrapper()
}
