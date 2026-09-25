//
//  AttachmentThumbnail.swift
//  checkpoint
//
//  60x60 thumbnail display for service attachments
//

import SwiftUI

/// Fixed thumbnail edge. The tile is an image slot, not text, so it stays put
/// under Dynamic Type — which is why the placeholders inside it are glyphs
/// rather than captions.
let attachmentThumbnailSize: CGFloat = 60

struct AttachmentThumbnail: View {
    let attachment: ServiceAttachment

    var body: some View {
        ZStack {
            if let image = attachment.thumbnailImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: attachmentThumbnailSize, height: attachmentThumbnailSize)
                    .clipped()
                    .accessibilityLabel(L10n.a11yPhotoAttachment)
            } else if attachment.isPDF {
                AttachmentPlaceholderTile(isPDF: true)
            } else {
                AttachmentPlaceholderTile(isPDF: false)
            }
        }
        .overlay(
            Rectangle()
                .strokeBorder(Theme.gridLine, lineWidth: 1)
        )
    }
}

/// The tile shown when an attachment has no image thumbnail.
///
/// Glyph only: a scaling caption would overflow the fixed 60pt tile at larger
/// text sizes. VoiceOver gets the word from the label instead.
struct AttachmentPlaceholderTile: View {
    let isPDF: Bool

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Theme.surfaceInstrument)

            Image(systemName: isPDF ? "doc.fill" : "doc")
                .font(.title3)
                .foregroundStyle(isPDF ? Theme.accent : Theme.textTertiary)
        }
        .frame(width: attachmentThumbnailSize, height: attachmentThumbnailSize)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isPDF ? L10n.a11yPDFAttachment : L10n.a11yFileAttachment)
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

    // Create a sample image attachment
    let sampleImage = UIImage(systemName: "car.fill")!
    let attachment = ServiceAttachment.fromImage(sampleImage, serviceLog: log)!

    return ZStack {
        AtmosphericBackground()

        HStack(spacing: Spacing.sm) {
            AttachmentThumbnail(attachment: attachment)
            AttachmentPlaceholderTile(isPDF: true)
            AttachmentPlaceholderTile(isPDF: false)
        }
        .padding(Spacing.screenHorizontal)
    }
    .preferredColorScheme(.dark)
}
