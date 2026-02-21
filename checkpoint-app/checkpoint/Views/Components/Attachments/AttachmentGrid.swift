//
//  AttachmentGrid.swift
//  checkpoint
//
//  Horizontal scrolling grid of attachment thumbnails
//

import SwiftUI
import QuickLook
import os

private let attachmentGridLogger = Logger(subsystem: "com.418-studio.checkpoint", category: "Attachments")

struct AttachmentGrid: View {
    let attachments: [ServiceAttachment]
    @State private var selectedAttachment: ServiceAttachment?
    @State private var previewURL: URL?
    @State private var selectedForOCRView: ServiceAttachment?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if !attachments.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.sm) {
                        ForEach(attachments) { attachment in
                            Button {
                                openAttachment(attachment)
                            } label: {
                                AttachmentThumbnail(attachment: attachment)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .quickLookPreview($previewURL)
        .sheet(item: $selectedForOCRView) { attachment in
            if let text = attachment.extractedText {
                ReceiptTextView(
                    text: text,
                    image: attachment.data.flatMap { UIImage(data: $0) }
                )
            }
        }
    }

    private func openAttachment(_ attachment: ServiceAttachment) {
        // If attachment has extracted text, show the OCR view
        if attachment.extractedText != nil {
            selectedForOCRView = attachment
            return
        }

        guard let data = attachment.data else { return }

        // Create temporary file for QuickLook
        let tempDir = FileManager.default.temporaryDirectory
        let fileExtension = attachment.isPDF ? "pdf" : "jpg"
        let tempURL = tempDir.appendingPathComponent("\(attachment.id).\(fileExtension)")

        do {
            try data.write(to: tempURL)
            previewURL = tempURL
        } catch {
            attachmentGridLogger.error("Error writing temp file for preview: \(error.localizedDescription)")
        }
    }
}

// MARK: - Attachment Section for Detail Views

struct AttachmentSection: View {
    let attachments: [ServiceAttachment]

    var body: some View {
        if !attachments.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                InstrumentSectionHeader(title: "Attachments")

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "paperclip")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.textTertiary)

                        Text("\(attachments.count) attachment\(attachments.count == 1 ? "" : "s")")
                            .font(.brutalistSecondary)
                            .foregroundStyle(Theme.textTertiary)
                    }

                    AttachmentGrid(attachments: attachments)
                }
                .padding(Spacing.md)
                .background(Theme.surfaceInstrument)
                .brutalistBorder()
            }
        }
    }
}

#Preview {
    let vehicle = Vehicle(
        name: "Test Car",
        make: "Toyota",
        model: "Camry",
        year: 2022,
        currentMileage: 32500
    )

    let log = ServiceLog(
        vehicle: vehicle,
        performedDate: Date.now,
        mileageAtService: 32500
    )

    // Create sample attachments
    let sampleImage = UIImage(systemName: "car.fill")!
    let attachment1 = ServiceAttachment.fromImage(sampleImage, fileName: "receipt.jpg", serviceLog: log)!
    let attachment2 = ServiceAttachment(
        serviceLog: log,
        data: Data(),
        fileName: "invoice.pdf",
        mimeType: "application/pdf"
    )

    return ZStack {
        AtmosphericBackground()

        ScrollView {
            VStack(spacing: Spacing.lg) {
                AttachmentSection(attachments: [attachment1, attachment2])
            }
            .padding(Spacing.screenHorizontal)
        }
    }
    .preferredColorScheme(.dark)
}
