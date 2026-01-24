//
//  BrutalistTabBar.swift
//  checkpoint
//
//  Custom tab bar with brutalist monospace aesthetic
//

import SwiftUI

struct BrutalistTabBar: View {
    @Binding var selectedTab: AppState.Tab

    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppState.Tab.allCases, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.top, Spacing.sm)
        .padding(.bottom, Spacing.md)
        .background(Theme.surfaceInstrument)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Theme.gridLine)
                .frame(height: Theme.borderWidth)
        }
    }

    private func tabButton(for tab: AppState.Tab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: Spacing.xs) {
                // Icon
                Image(systemName: tab.icon)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Theme.accent : Theme.textTertiary)

                // Label
                Text(tab.title)
                    .font(.brutalistLabel)
                    .foregroundStyle(isSelected ? Theme.accent : Theme.textTertiary)
                    .tracking(1)

                // Selection indicator
                Rectangle()
                    .fill(isSelected ? Theme.accent : Color.clear)
                    .frame(width: 24, height: 2)
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
