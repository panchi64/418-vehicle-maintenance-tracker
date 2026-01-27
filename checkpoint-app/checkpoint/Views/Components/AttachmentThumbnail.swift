//
//  AttachmentThumbnail.swift
//  checkpoint
//
//  60x60 thumbnail display for service attachments
//

import SwiftUI

struct AttachmentThumbnail: View {
    let attachment: ServiceAttachment

    var body: some View {
        ZStack {
            if let image = attachment.thumbnailImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipped()
            } else if attachment.isPDF {
                // PDF placeholder
                ZStack {
                    Rectangle()
                        .fill(Theme.surfaceInstrument)

                    VStack(spacing: 2) {
                        Image(systemName: "doc.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Theme.accent)

                        Text("PDF")
                            .font(.brutalistLabel)
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
                .frame(width: 60, height: 60)
            } else {
                // Generic file placeholder
                ZStack {
                    Rectangle()
                        .fill(Theme.surfaceInstrument)

                    Image(systemName: "doc")
                        .font(.system(size: 24))
                        .foregroundStyle(Theme.textTertiary)
                }
                .frame(width: 60, height: 60)
            }
        }
        .overlay(
            Rectangle()
                .strokeBorder(Theme.gridLine, lineWidth: 1)
        )
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

            // PDF placeholder demo
            ZStack {
                Rectangle()
                    .fill(Theme.surfaceInstrument)
                    .frame(width: 60, height: 60)

                VStack(spacing: 2) {
                    Image(systemName: "doc.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Theme.accent)

                    Text("PDF")
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .overlay(
                Rectangle()
                    .strokeBorder(Theme.gridLine, lineWidth: 1)
            )
        }
        .padding(Spacing.screenHorizontal)
    }
    .preferredColorScheme(.dark)
}
