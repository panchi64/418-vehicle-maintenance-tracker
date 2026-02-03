//
//  FeatureHintView.swift
//  checkpoint
//
//  Lightweight, one-time contextual hint for feature discovery
//  Appears inline near the feature it describes, dismisses permanently on tap
//

import SwiftUI

/// A brutalist-styled hint banner that appears once to help users discover features.
/// Automatically integrates with FeatureDiscovery to track dismissal state.
struct FeatureHintView: View {
    // MARK: - Properties

    let feature: FeatureDiscovery.Feature
    let icon: String
    let message: String

    @State private var isVisible: Bool = true

    // MARK: - Body

    var body: some View {
        if isVisible {
            HStack(spacing: Spacing.sm) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(Theme.accent)

                // Message
                Text(message)
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(2)

                // Dismiss button
                Button {
                    dismissHint()
                } label: {
                    Text("GOT IT")
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.accent)
                        .textCase(.uppercase)
                        .tracking(1)
                }
                .buttonStyle(.plain)
            }
            .padding(Spacing.md)
            .background(
                Theme.surfaceInstrument
                    .opacity(0.8)
            )
            .overlay(
                Rectangle()
                    .strokeBorder(
                        Theme.accent.opacity(0.3),
                        lineWidth: Theme.borderWidth
                    )
            )
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 0.98)),
                removal: .opacity
            ))
            .animation(.easeOut(duration: Theme.animationMedium), value: isVisible)
        }
    }

    // MARK: - Actions

    private func dismissHint() {
        withAnimation(.easeOut(duration: Theme.animationMedium)) {
            isVisible = false
        }

        // Mark as seen after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + Theme.animationMedium) {
            FeatureDiscovery.shared.markHintSeen(feature)
        }
    }
}

// MARK: - Convenience Initializer

extension FeatureHintView {
    /// Create a hint view using the feature's default icon and message
    /// - Parameter feature: The feature to show a hint for
    init(for feature: FeatureDiscovery.Feature) {
        self.feature = feature
        self.icon = feature.icon
        self.message = feature.message
    }
}

// MARK: - Preview

#Preview("VIN Lookup Hint") {
    VStack(spacing: Spacing.lg) {
        Text("VEHICLE DETAILS")
            .font(.brutalistLabel)
            .foregroundStyle(Theme.textTertiary)
            .textCase(.uppercase)
            .tracking(2)

        FeatureHintView(for: .vinLookup)

        Spacer()
    }
    .padding(Spacing.md)
    .background(Theme.backgroundPrimary)
}

#Preview("Odometer OCR Hint") {
    VStack(spacing: Spacing.lg) {
        Text("UPDATE MILEAGE")
            .font(.brutalistLabel)
            .foregroundStyle(Theme.textTertiary)
            .textCase(.uppercase)
            .tracking(2)

        FeatureHintView(for: .odometerOCR)

        Spacer()
    }
    .padding(Spacing.md)
    .background(Theme.backgroundPrimary)
}

#Preview("Service Bundling Hint") {
    VStack(spacing: Spacing.lg) {
        Text("UPCOMING SERVICES")
            .font(.brutalistLabel)
            .foregroundStyle(Theme.textTertiary)
            .textCase(.uppercase)
            .tracking(2)

        FeatureHintView(for: .serviceBundling)

        Spacer()
    }
    .padding(Spacing.md)
    .background(Theme.backgroundPrimary)
}

#Preview("Swipe Navigation Hint") {
    VStack(spacing: Spacing.lg) {
        Text("NAVIGATION")
            .font(.brutalistLabel)
            .foregroundStyle(Theme.textTertiary)
            .textCase(.uppercase)
            .tracking(2)

        FeatureHintView(for: .swipeNavigation)

        Spacer()
    }
    .padding(Spacing.md)
    .background(Theme.backgroundPrimary)
}

#Preview("All Hints") {
    ScrollView {
        VStack(spacing: Spacing.lg) {
            ForEach(FeatureDiscovery.Feature.allCases, id: \.self) { feature in
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(feature.rawValue.uppercased())
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.textTertiary)
                        .textCase(.uppercase)
                        .tracking(2)

                    FeatureHintView(for: feature)
                }
            }
        }
        .padding(Spacing.md)
    }
    .background(Theme.backgroundPrimary)
}
