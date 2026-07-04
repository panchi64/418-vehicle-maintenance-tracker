//
//  CollapsibleDetailsSection.swift
//  checkpoint
//
//  Collapsed "Details" disclosure for secondary form fields. Expansion state
//  is remembered per form+mode via the caller-supplied storage key.
//

import SwiftUI

struct CollapsibleDetailsSection<Content: View>: View {
    let filledCount: Int
    let autoExpandWhenFilled: Bool
    let content: Content

    @AppStorage private var isExpanded: Bool

    init(
        storageKey: String,
        filledCount: Int = 0,
        autoExpandWhenFilled: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.filledCount = filledCount
        self.autoExpandWhenFilled = autoExpandWhenFilled
        self.content = content()
        self._isExpanded = AppStorage(wrappedValue: false, storageKey)
    }

    private var headerTitle: String {
        filledCount > 0 ? L10n.formDetailsCount(filledCount) : L10n.formDetails
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Button {
                withAnimation(.easeInOut(duration: Theme.animationMedium)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: Spacing.sm) {
                    Text(headerTitle.uppercased())
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.textTertiary)
                        .tracking(1.5)

                    Rectangle()
                        .fill(Theme.gridLine)
                        .frame(height: Theme.borderWidth)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.textTertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(headerTitle)
            .accessibilityHint(isExpanded ? "Collapses details" : "Expands details")

            if isExpanded {
                content
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .onAppear {
            if autoExpandWhenFilled && filledCount > 0 {
                isExpanded = true
            }
        }
    }
}

#Preview {
    ZStack {
        Theme.backgroundPrimary.ignoresSafeArea()
        ScrollView {
            VStack(spacing: Spacing.lg) {
                CollapsibleDetailsSection(storageKey: "preview.detailsCollapsed") {
                    Text("Collapsed by default")
                        .foregroundStyle(Theme.textPrimary)
                }

                CollapsibleDetailsSection(storageKey: "preview.detailsFilled", filledCount: 2, autoExpandWhenFilled: true) {
                    Text("Auto-expanded because filledCount > 0")
                        .foregroundStyle(Theme.textPrimary)
                }
            }
            .padding(Spacing.screenHorizontal)
        }
    }
    .preferredColorScheme(.dark)
}
