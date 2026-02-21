//
//  AttachmentPicker.swift
//  checkpoint
//
//  Photo and document picker for service attachments
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import os

private let attachmentLogger = Logger(subsystem: "com.418-studio.checkpoint", category: "Attachments")

struct AttachmentPicker: View {
    @Binding var attachments: [AttachmentData]

    @State private var showPhotoPicker = false
    @State private var showDocumentPicker = false
    @State private var showReceiptScanner = false
    @State private var isProcessingOCR = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    /// Temporary data structure for new attachments before saving
    struct AttachmentData: Identifiable {
        let id = UUID()
        let data: Data
        let fileName: String
        let mimeType: String
        var thumbnailImage: UIImage?
        var extractedText: String?
    }

    var body: some View {
        let labelFont: Font = .brutalistLabel
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Buttons row
            HStack(spacing: Spacing.sm) {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    HStack(spacing: 6) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 14, weight: .medium))
                        Text("PHOTO")
                            .font(labelFont)
                            .tracking(1)
                    }
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(Theme.surfaceInstrument)
                    .brutalistBorder()
                }
                .onChange(of: selectedPhotoItem) { _, newItem in
                    Task {
                        await loadPhoto(from: newItem)
                    }
                }

                Button {
                    showDocumentPicker = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.fill")
                            .font(.system(size: 14, weight: .medium))
                        Text("PDF")
                            .font(.brutalistLabel)
                            .tracking(1)
                    }
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(Theme.surfaceInstrument)
                    .brutalistBorder()
                }
                .sheet(isPresented: $showDocumentPicker) {
                    DocumentPicker(onDocumentPicked: { url in
                        loadDocument(from: url)
                    })
                }

                Button {
                    showReceiptScanner = true
                } label: {
                    HStack(spacing: 6) {
                        if isProcessingOCR {
                            ProgressView()
                                .tint(Theme.textPrimary)
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "receipt")
                                .font(.system(size: 14, weight: .medium))
                        }
                        Text("RECEIPT")
                            .font(.brutalistLabel)
                            .tracking(1)
                    }
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(Theme.surfaceInstrument)
                    .brutalistBorder()
                }
                .disabled(isProcessingOCR)
                .sheet(isPresented: $showReceiptScanner) {
                    ReceiptScannerView(
                        onImagesScanned: { images in
                            Task {
                                await processScannedImages(images)
                            }
                        },
                        onCancel: {},
                        onError: { error in
                            attachmentLogger.error("Receipt scan failed: \(error.localizedDescription)")
                            ToastService.shared.show("Scan failed. Please try again.", icon: "xmark.circle", style: .error)
                        }
                    )
                }

                Spacer()

                if !attachments.isEmpty {
                    Text("\(attachments.count)")
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.accent.opacity(0.2))
                }
            }

            // Preview grid
            if !attachments.isEmpty {
                AttachmentPreviewGrid(
                    attachments: attachments,
                    onRemove: { attachment in
                        attachments.removeAll { $0.id == attachment.id }
                    }
                )
            }
        }
    }

    // MARK: - Photo Loading

    @MainActor
    private func loadPhoto(from item: PhotosPickerItem?) async {
        guard let item = item else { return }

        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                if let uiImage = UIImage(data: data) {
                    // Compress the image
                    if let compressedData = ServiceAttachment.compressedImageData(from: uiImage) {
                        let attachment = AttachmentData(
                            data: compressedData,
                            fileName: "photo_\(Date.now.timeIntervalSince1970).jpg",
                            mimeType: "image/jpeg",
                            thumbnailImage: uiImage
                        )
                        attachments.append(attachment)
                    }
                }
            }
        } catch {
            attachmentLogger.error("Error loading photo: \(error.localizedDescription)")
        }

        selectedPhotoItem = nil
    }

    // MARK: - Document Loading

    private func loadDocument(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let data = try Data(contentsOf: url)
            var thumbnail: UIImage? = nil
            if let thumbData = ServiceAttachment.generateThumbnailData(from: data, mimeType: "application/pdf") {
                thumbnail = UIImage(data: thumbData)
            }
            let attachment = AttachmentData(
                data: data,
                fileName: url.lastPathComponent,
                mimeType: "application/pdf",
                thumbnailImage: thumbnail
            )
            attachments.append(attachment)
        } catch {
            attachmentLogger.error("Error loading document: \(error.localizedDescription)")
        }
    }

    // MARK: - Receipt Scanning

    @MainActor
    private func processScannedImages(_ images: [UIImage]) async {
        isProcessingOCR = true
        defer { isProcessingOCR = false }

        for (index, image) in images.enumerated() {
            // Compress the image
            guard let compressedData = ServiceAttachment.compressedImageData(from: image) else {
                continue
            }

            // Extract text via OCR
            var extractedText: String? = nil
            do {
                let result = try await ReceiptOCRService.shared.extractText(from: image)
                extractedText = result.text
            } catch {
                attachmentLogger.error("OCR failed for page \(index + 1): \(error.localizedDescription)")
                // Continue without extracted text - still save the image
            }

            // Generate thumbnail
            let thumbnailImage: UIImage?
            if let thumbData = ServiceAttachment.generateThumbnailData(from: compressedData, mimeType: "image/jpeg") {
                thumbnailImage = UIImage(data: thumbData)
            } else {
                thumbnailImage = image
            }

            let attachment = AttachmentData(
                data: compressedData,
                fileName: "receipt_\(Date.now.timeIntervalSince1970)_\(index + 1).jpg",
                mimeType: "image/jpeg",
                thumbnailImage: thumbnailImage,
                extractedText: extractedText
            )
            attachments.append(attachment)
        }
    }
}

// MARK: - Attachment Preview Grid

struct AttachmentPreviewGrid: View {
    let attachments: [AttachmentPicker.AttachmentData]
    let onRemove: (AttachmentPicker.AttachmentData) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(attachments) { attachment in
                    AttachmentPreviewItem(
                        attachment: attachment,
                        onRemove: { onRemove(attachment) }
                    )
                }
            }
        }
    }
}

// MARK: - Attachment Preview Item

struct AttachmentPreviewItem: View {
    let attachment: AttachmentPicker.AttachmentData
    let onRemove: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Thumbnail
            if let image = attachment.thumbnailImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipped()
            } else {
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
            }

            // Remove button
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Theme.surfaceInstrument)
                    .padding(4)
                    .background(Theme.statusOverdue)
            }
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
            .offset(x: 4, y: -4)
        }
        .overlay(
            Rectangle()
                .strokeBorder(Theme.gridLine, lineWidth: 1)
        )
    }
}

// MARK: - Document Picker

struct DocumentPicker: UIViewControllerRepresentable {
    let onDocumentPicked: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onDocumentPicked: onDocumentPicked)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onDocumentPicked: (URL) -> Void

        init(onDocumentPicked: @escaping (URL) -> Void) {
            self.onDocumentPicked = onDocumentPicked
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onDocumentPicked(url)
        }
    }
}

#Preview {
    @Previewable @State var attachments: [AttachmentPicker.AttachmentData] = []

    return ZStack {
        AtmosphericBackground()

        VStack(spacing: Spacing.lg) {
            InstrumentSectionHeader(title: "Attachments")

            AttachmentPicker(attachments: $attachments)
        }
        .padding(Spacing.screenHorizontal)
    }
    .preferredColorScheme(.dark)
}
