//
//  AttachmentGrid.swift
//  checkpoint
//
//  Horizontal scrolling grid of attachment thumbnails
//

import SwiftUI

struct AttachmentGrid: View {
    let attachments: [ServiceAttachment]
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if !attachments.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.sm) {
                        ForEach(attachments) { attachment in
                            Button {
                                appState.selectedDocument = attachment
                            } label: {
                                AttachmentThumbnail(attachment: attachment)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Open document")
                            .accessibilityHint("Opens the document detail view")
                        }
                    }
                }
            }
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
    .environment(AppState())
    .preferredColorScheme(.dark)
}
