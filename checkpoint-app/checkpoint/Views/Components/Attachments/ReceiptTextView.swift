//
//  ReceiptTextView.swift
//  checkpoint
//
//  Display view for OCR-extracted text from receipts/invoices
//

import SwiftUI

struct ReceiptTextView: View {
    @Environment(\.dismiss) private var dismiss

    let text: String
    let image: UIImage?

    @State private var showCopiedFeedback = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Receipt image preview
                        if let image = image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .overlay(
                                    Rectangle()
                                        .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
                                )
                        }

                        // Extracted text section
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            HStack {
                                InstrumentSectionHeader(title: "Extracted Text")

                                Spacer()

                                Button {
                                    copyToClipboard()
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: showCopiedFeedback ? "checkmark" : "doc.on.doc")
                                            .font(.system(size: 12, weight: .medium))
                                        Text(showCopiedFeedback ? "COPIED" : "COPY")
                                            .font(.brutalistLabel)
                                            .tracking(1)
                                    }
                                    .foregroundStyle(showCopiedFeedback ? Theme.statusGood : Theme.accent)
                                    .padding(.horizontal, Spacing.sm)
                                    .padding(.vertical, 6)
                                    .background(Theme.surfaceInstrument)
                                    .overlay(
                                        Rectangle()
                                            .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
                                    )
                                }
                                .disabled(showCopiedFeedback)
                            }

                            // Text content in monospace
                            Text(text)
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(Theme.textPrimary)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(Spacing.md)
                                .background(Theme.surfaceInstrument)
                                .overlay(
                                    Rectangle()
                                        .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
                                )
                        }

                        // Reference note
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 12, weight: .medium))
                            Text("TEXT IS FOR REFERENCE ONLY")
                                .font(.brutalistLabel)
                                .tracking(1)
                        }
                        .foregroundStyle(Theme.textTertiary)

                        Spacer(minLength: Spacing.xl)
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.vertical, Spacing.lg)
                }
            }
            .navigationTitle("Receipt Text")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(.brutalistBody)
                }
            }
        }
    }

    private func copyToClipboard() {
        UIPasteboard.general.string = text
        showCopiedFeedback = true

        // Reset feedback after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showCopiedFeedback = false
        }
    }
}

#Preview {
    ReceiptTextView(
        text: """
        AUTO SERVICE CENTER
        123 Main Street
        San Juan, PR 00901

        Date: 01/15/2026
        Invoice #: 12345

        Oil Change - Synthetic    $89.99
        Labor                     $35.00
        Tax                        $9.37
        -------------------------------
        TOTAL                    $134.36

        Thank you for your business!
        """,
        image: nil
    )
    .preferredColorScheme(.dark)
}
