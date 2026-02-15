//
//  BrutalistTabBar.swift
//  checkpoint
//
//  Custom tab bar with brutalist monospace aesthetic + Liquid Glass
//  Following AESTHETIC.md: sharp corners, underline indicators, fade-only transitions
//

import SwiftUI

struct BrutalistTabBar: View {
    @Binding var selectedTab: AppState.Tab
    var onLogTapped: (() -> Void)?
    var onScheduleTapped: (() -> Void)?

    @State private var isAddExpanded = false

    private var hasAddActions: Bool {
        onLogTapped != nil || onScheduleTapped != nil
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: Spacing.sm) {
            // Tab buttons in glass container
            HStack(spacing: 0) {
                ForEach(AppState.Tab.allCases, id: \.self) { tab in
                    tabButton(for: tab)
                }
            }
            .frame(height: 48)
            .glassEffect(.clear.tint(Theme.surfaceInstrument), in: Rectangle())

            // Add actions
            if hasAddActions {
                if isAddExpanded {
                    VStack(spacing: Spacing.xs) {
                        if onScheduleTapped != nil {
                            Button {
                                HapticService.shared.lightImpact()
                                withAnimation(.easeOut(duration: Theme.animationFast)) {
                                    isAddExpanded = false
                                }
                                onScheduleTapped?()
                            } label: {
                                Text("[SCHEDULE]")
                                    .font(.brutalistLabel)
                                    .foregroundStyle(Theme.backgroundPrimary)
                                    .tracking(1)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, Spacing.md)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .glassEffect(.clear.tint(Theme.textPrimary), in: Rectangle())
                            .transition(.opacity)
                            .accessibilityLabel("Schedule service")
                        }

                        if onLogTapped != nil {
                            Button {
                                HapticService.shared.lightImpact()
                                withAnimation(.easeOut(duration: Theme.animationFast)) {
                                    isAddExpanded = false
                                }
                                onLogTapped?()
                            } label: {
                                Text("[LOG]")
                                    .font(.brutalistLabel)
                                    .foregroundStyle(Theme.backgroundPrimary)
                                    .tracking(1)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, Spacing.md)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .glassEffect(.clear.tint(Theme.textPrimary), in: Rectangle())
                            .transition(.opacity)
                            .accessibilityLabel("Log service")
                        }
                    }
                    .animation(.easeOut(duration: Theme.animationFast), value: isAddExpanded)
                } else {
                    Button {
                        HapticService.shared.lightImpact()
                        withAnimation(.easeOut(duration: Theme.animationFast)) {
                            isAddExpanded = true
                        }
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
                    .transition(.opacity)
                    .accessibilityLabel("Add service")
                    .accessibilityHint("Expands to show log and schedule options")
                    .animation(.easeOut(duration: Theme.animationFast), value: isAddExpanded)
                }
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.bottom, Spacing.sm)
    }

    private func tabButton(for tab: AppState.Tab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            if isAddExpanded {
                withAnimation(.easeOut(duration: Theme.animationFast)) {
                    isAddExpanded = false
                }
            }
            selectedTab = tab
            HapticService.shared.tabChanged()
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: tab.icon)
                    .font(.system(size: 14, weight: .semibold))

                if !isAddExpanded {
                    Text(tab.title)
                        .font(.brutalistLabel)
                        .tracking(2)
                        .fixedSize()
                        .transition(.opacity)
                }
            }
            .foregroundStyle(isSelected ? Theme.accent : Theme.textTertiary)
            .padding(.horizontal, isAddExpanded ? Spacing.xs : Spacing.sm)
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
            .animation(.easeOut(duration: Theme.animationFast), value: isAddExpanded)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
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
                    onLogTapped: { print("Log tapped") },
                    onScheduleTapped: { print("Schedule tapped") }
                )
            }
            .preferredColorScheme(.dark)
        }
    }

    return PreviewWrapper()
}
