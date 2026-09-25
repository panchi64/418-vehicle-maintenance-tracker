//
//  ConfidenceIndicator.swift
//  checkpoint
//
//  Shared confidence level enum and bar components
//  Used for OCR confidence and pace data quality indication
//

import SwiftUI

// MARK: - Confidence Level

/// Shared confidence level enum for various quality indicators
enum ConfidenceLevel {
    case high
    case medium
    case low

    var color: Color {
        switch self {
        case .high: return Theme.statusGood
        case .medium: return Theme.statusDueSoon
        case .low: return Theme.statusOverdue
        }
    }

    var label: String {
        switch self {
        case .high: return L10n.cameraConfidenceHigh
        case .medium: return L10n.cameraConfidenceMedium
        case .low: return L10n.cameraConfidenceLow
        }
    }

    /// What VoiceOver hears. The bar's color and fill carry the level visually;
    /// this carries it in words.
    var accessibilityLabel: String {
        switch self {
        case .high: return L10n.a11yConfidenceHigh
        case .medium: return L10n.a11yConfidenceMedium
        case .low: return L10n.a11yConfidenceLow
        }
    }
}

// MARK: - Confidence Bar

/// Brutalist-style segmented confidence bar (10 segments)
struct ConfidenceBar: View {
    let confidence: Float
    let level: ConfidenceLevel

    /// Number of segments in the bar
    private let segmentCount = 10

    /// How many segments should be filled
    private var filledSegments: Int {
        Int(ceil(confidence * Float(segmentCount)))
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<segmentCount, id: \.self) { index in
                Rectangle()
                    .fill(index < filledSegments ? level.color : Theme.gridLine)
                    .frame(height: 8)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(level.accessibilityLabel)
        .accessibilityValue(Double(confidence).formatted(.percent.precision(.fractionLength(0))))
    }
}

// MARK: - Compact Confidence Bar

/// Compact confidence bar for metadata-style display (5 segments)
struct CompactConfidenceBar: View {
    let level: ConfidenceLevel

    private let segmentCount = 5

    private var filledSegments: Int {
        switch level {
        case .high: return 5
        case .medium: return 3
        case .low: return 1
        }
    }

    var body: some View {
        HStack(spacing: 1) {
            ForEach(0..<segmentCount, id: \.self) { index in
                Rectangle()
                    .fill(index < filledSegments ? level.color : Theme.gridLine)
                    .frame(width: 6, height: 4)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(level.accessibilityLabel)
    }
}

// MARK: - Previews

#Preview("Confidence Levels") {
    ZStack {
        Theme.backgroundPrimary
            .ignoresSafeArea()

        VStack(spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("HIGH CONFIDENCE")
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.textTertiary)
                ConfidenceBar(confidence: 0.95, level: .high)
            }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("MEDIUM CONFIDENCE")
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.textTertiary)
                ConfidenceBar(confidence: 0.65, level: .medium)
            }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("LOW CONFIDENCE")
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.textTertiary)
                ConfidenceBar(confidence: 0.35, level: .low)
            }

            ListDivider(leadingPadding: 0)

            HStack(spacing: Spacing.xl) {
                VStack(spacing: Spacing.xs) {
                    CompactConfidenceBar(level: .high)
                    Text("HIGH")
                        .font(.brutalistLabel)
                        .foregroundStyle(ConfidenceLevel.high.color)
                }

                VStack(spacing: Spacing.xs) {
                    CompactConfidenceBar(level: .medium)
                    Text("MEDIUM")
                        .font(.brutalistLabel)
                        .foregroundStyle(ConfidenceLevel.medium.color)
                }

                VStack(spacing: Spacing.xs) {
                    CompactConfidenceBar(level: .low)
                    Text("LOW")
                        .font(.brutalistLabel)
                        .foregroundStyle(ConfidenceLevel.low.color)
                }
            }
        }
        .padding(Spacing.screenHorizontal)
    }
    .preferredColorScheme(.dark)
}
