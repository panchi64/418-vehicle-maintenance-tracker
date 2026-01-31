//
//  OCRProcessingIndicator.swift
//  checkpoint
//
//  Reusable processing indicator for OCR operations
//  Displays a spinner with status text in brutalist style
//

import SwiftUI

/// Brutalist-style processing indicator for OCR operations
struct OCRProcessingIndicator: View {
    let text: String

    var body: some View {
        HStack(spacing: Spacing.sm) {
            ProgressView()
                .tint(Theme.accent)

            Text(text.uppercased())
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textSecondary)
                .tracking(1)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity)
        .background(Theme.surfaceInstrument)
        .overlay(
            Rectangle()
                .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
        )
    }
}

// MARK: - Previews

#Preview("OCR Processing Indicators") {
    ZStack {
        Theme.backgroundPrimary
            .ignoresSafeArea()

        VStack(spacing: Spacing.lg) {
            OCRProcessingIndicator(text: "Processing VIN...")

            OCRProcessingIndicator(text: "Reading odometer...")

            OCRProcessingIndicator(text: "Scanning document...")
        }
        .padding(Spacing.screenHorizontal)
    }
    .preferredColorScheme(.dark)
}
