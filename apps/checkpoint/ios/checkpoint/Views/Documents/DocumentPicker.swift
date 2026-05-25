//
//  DocumentPicker.swift
//  checkpoint
//
//  Standalone vehicle-library add-document flow.
//
//  Three sources (Scan / Photo / Files) → review screen (filename, type,
//  notes, cross-vehicle links) → Save inserts a Document into the model
//  context and dismisses.
//
//  The legacy `DocumentPicker` `UIDocumentPickerViewController` wrapper in
//  `Components/Attachments/AttachmentPicker.swift` is still used by the
//  in-line service-log attachment row; this file deliberately uses a
//  different name (`FilePickerRepresentable`) to avoid colliding.
//

import SwiftUI
import SwiftData
import PhotosUI
import UniformTypeIdentifiers
import os

private let documentPickerLogger = Logger(category: "Documents")

// MARK: - Document Picker Sheet

struct DocumentPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let currentVehicle: Vehicle
    let availableVehicles: [Vehicle]
    let serviceLog: ServiceLog?
    let onSave: (Document) -> Void

    @State private var pendingPayload: PendingDocument?

    // Source pickers
    @State private var showPhotoPicker = false
    @State private var showFilePicker = false
    @State private var showScanner = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphericBackground()

                if let payload = pendingPayload {
                    DocumentReviewForm(
                        payload: payload,
                        currentVehicle: currentVehicle,
                        availableVehicles: availableVehicles,
                        showsLinkingControls: serviceLog == nil,
                        onUpdate: { updated in
                            pendingPayload = updated
                        },
                        onCancel: {
                            pendingPayload = nil
                        },
                        onSave: { final in
                            save(payload: final)
                        }
                    )
                } else {
                    sourceChooser
                }
            }
            .navigationTitle(L10n.documentsAdd)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.surfaceInstrument, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .toolbarButtonStyle()
                }
            }
            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoItem, matching: .images)
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    await loadPhoto(from: newItem)
                    selectedPhotoItem = nil
                }
            }
            .sheet(isPresented: $showFilePicker) {
                FilePickerRepresentable { url in
                    loadFile(from: url)
                }
            }
            .sheet(isPresented: $showScanner) {
                ReceiptScannerView(
                    onImagesScanned: { images in
                        handleScannedImages(images)
                    },
                    onCancel: {},
                    onError: { error in
                        documentPickerLogger.error("Scanner failed: \(error.localizedDescription)")
                    }
                )
            }
        }
    }

    // MARK: - Source Chooser

    private var sourceChooser: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                sourceButton(
                    icon: "doc.viewfinder",
                    label: L10n.documentsSourceCamera,
                    action: { showScanner = true }
                )

                sourceButton(
                    icon: "photo.on.rectangle",
                    label: L10n.documentsSourcePhotos,
                    action: { showPhotoPicker = true }
                )

                sourceButton(
                    icon: "folder",
                    label: L10n.documentsSourceFiles,
                    action: { showFilePicker = true }
                )
            }
            .padding(Spacing.screenHorizontal)
            .padding(.top, Spacing.lg)
        }
    }

    private func sourceButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 32)

                Text(label.uppercased())
                    .font(.brutalistBody)
                    .tracking(1)
                    .foregroundStyle(Theme.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity)
            .background(Theme.surfaceInstrument)
            .brutalistBorder()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    // MARK: - Photo Loading

    @MainActor
    private func loadPhoto(from item: PhotosPickerItem) async {
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                return
            }

            let fileName = "photo_\(Int(Date.now.timeIntervalSince1970)).jpg"
            pendingPayload = PendingDocument(
                source: .image(image),
                fileName: fileName,
                documentType: DocumentType.suggestedType(forFileName: fileName),
                notes: "",
                linkedVehicleIDs: defaultLinkedVehicleIDs()
            )
        } catch {
            documentPickerLogger.error("Failed loading photo: \(error.localizedDescription)")
        }
    }

    // MARK: - File Loading

    private func loadFile(from url: URL) {
        let fileName = url.lastPathComponent
        let ext = url.pathExtension.lowercased()
        let defaultType = defaultDocumentType(for: fileName)
        let defaultVehicleIDs = defaultLinkedVehicleIDs()

        // Read the file off the main thread — picked files can be tens of MB
        // (vehicle manuals especially) and a synchronous read risks the
        // iOS watchdog terminating the app.
        Task.detached {
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }

            let data: Data
            do {
                data = try Data(contentsOf: url)
            } catch {
                let message = error.localizedDescription
                await MainActor.run {
                    documentPickerLogger.error("Failed loading file: \(message)")
                }
                return
            }

            let payload: PendingDocument?
            if ext == "pdf" {
                payload = PendingDocument(
                    source: .pdf(data),
                    fileName: fileName,
                    documentType: defaultType,
                    notes: "",
                    linkedVehicleIDs: defaultVehicleIDs
                )
            } else if let image = UIImage(data: data) {
                payload = PendingDocument(
                    source: .image(image),
                    fileName: fileName,
                    documentType: defaultType,
                    notes: "",
                    linkedVehicleIDs: defaultVehicleIDs
                )
            } else {
                payload = nil
            }

            if let payload {
                await MainActor.run { pendingPayload = payload }
            }
        }
    }

    // MARK: - Scanner

    private func handleScannedImages(_ images: [UIImage]) {
        guard !images.isEmpty else { return }

        // Multi-page scans: render every page into a single PDF so nothing is
        // silently dropped. Single-page scans stay as a JPEG image.
        if images.count > 1, let pdfData = multiPagePDF(from: images) {
            let fileName = "scan_\(Int(Date.now.timeIntervalSince1970)).pdf"
            pendingPayload = PendingDocument(
                source: .pdf(pdfData),
                fileName: fileName,
                documentType: defaultDocumentType(for: fileName),
                notes: "",
                linkedVehicleIDs: defaultLinkedVehicleIDs()
            )
            return
        }

        guard let first = images.first else { return }
        let fileName = "scan_\(Int(Date.now.timeIntervalSince1970)).jpg"
        pendingPayload = PendingDocument(
            source: .image(first),
            fileName: fileName,
            documentType: defaultDocumentType(for: fileName),
            notes: "",
            linkedVehicleIDs: defaultLinkedVehicleIDs()
        )
    }

    private func multiPagePDF(from images: [UIImage]) -> Data? {
        // US Letter at 72 dpi — matches the document scanner's default page.
        let pageBounds = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageBounds)
        return renderer.pdfData { context in
            for image in images {
                context.beginPage()
                let target = aspectFitRect(for: image.size, in: pageBounds)
                image.draw(in: target)
            }
        }
    }

    private func aspectFitRect(for imageSize: CGSize, in container: CGRect) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else { return container }
        let scale = min(container.width / imageSize.width, container.height / imageSize.height)
        let scaledSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let origin = CGPoint(
            x: container.midX - scaledSize.width / 2,
            y: container.midY - scaledSize.height / 2
        )
        return CGRect(origin: origin, size: scaledSize)
    }

    private func defaultDocumentType(for fileName: String) -> DocumentType {
        if serviceLog != nil { return .receipt }
        return DocumentType.suggestedType(forFileName: fileName)
    }

    private func defaultLinkedVehicleIDs() -> Set<UUID> {
        [currentVehicle.id]
    }

    // MARK: - Save

    private func save(payload: PendingDocument) {
        let linkedVehicles = availableVehicles.filter { payload.linkedVehicleIDs.contains($0.id) }
        let resolvedVehicles = linkedVehicles.isEmpty ? [currentVehicle] : linkedVehicles

        let document: Document?
        if let serviceLog {
            switch payload.source {
            case .image(let image):
                guard let data = ServiceAttachment.compressedImageData(from: image) else {
                    document = nil
                    break
                }
                let thumbnail = ServiceAttachment.generateThumbnailData(from: data, mimeType: "image/jpeg")
                document = ServiceAttachment(
                    serviceLog: serviceLog,
                    data: data,
                    thumbnailData: thumbnail,
                    fileName: payload.fileName,
                    mimeType: "image/jpeg",
                    documentType: payload.documentType,
                    notes: payload.notes.isEmpty ? nil : payload.notes,
                    vehicles: resolvedVehicles
                )
            case .pdf(let data):
                let thumbnail = ServiceAttachment.generateThumbnailData(from: data, mimeType: "application/pdf")
                document = ServiceAttachment(
                    serviceLog: serviceLog,
                    data: data,
                    thumbnailData: thumbnail,
                    fileName: payload.fileName,
                    mimeType: "application/pdf",
                    documentType: payload.documentType,
                    notes: payload.notes.isEmpty ? nil : payload.notes,
                    vehicles: resolvedVehicles
                )
            }
        } else {
            switch payload.source {
            case .image(let image):
                document = Document.fromImage(
                    image,
                    fileName: payload.fileName,
                    documentType: payload.documentType,
                    notes: payload.notes.isEmpty ? nil : payload.notes,
                    vehicles: resolvedVehicles
                )
            case .pdf(let data):
                document = Document.fromPDF(
                    data,
                    fileName: payload.fileName,
                    documentType: payload.documentType,
                    notes: payload.notes.isEmpty ? nil : payload.notes,
                    vehicles: resolvedVehicles
                )
            }
        }

        guard let document else {
            documentPickerLogger.error("Failed to construct document from payload")
            return
        }

        modelContext.insert(document)
        try? modelContext.save()
        onSave(document)
        dismiss()
    }
}

// MARK: - Pending Document

struct PendingDocument {
    enum Source {
        case image(UIImage)
        case pdf(Data)
    }

    var source: Source
    var fileName: String
    var documentType: DocumentType
    var notes: String
    var linkedVehicleIDs: Set<UUID>
}

// MARK: - Review Form

private struct DocumentReviewForm: View {
    let payload: PendingDocument
    let currentVehicle: Vehicle
    let availableVehicles: [Vehicle]
    let showsLinkingControls: Bool
    let onUpdate: (PendingDocument) -> Void
    let onCancel: () -> Void
    let onSave: (PendingDocument) -> Void

    @State private var fileName: String
    @State private var documentType: DocumentType
    @State private var notes: String
    @State private var linkedVehicleIDs: Set<UUID>
    @State private var showVehiclePicker = false

    init(
        payload: PendingDocument,
        currentVehicle: Vehicle,
        availableVehicles: [Vehicle],
        showsLinkingControls: Bool,
        onUpdate: @escaping (PendingDocument) -> Void,
        onCancel: @escaping () -> Void,
        onSave: @escaping (PendingDocument) -> Void
    ) {
        self.payload = payload
        self.currentVehicle = currentVehicle
        self.availableVehicles = availableVehicles
        self.showsLinkingControls = showsLinkingControls
        self.onUpdate = onUpdate
        self.onCancel = onCancel
        self.onSave = onSave
        _fileName = State(initialValue: payload.fileName)
        _documentType = State(initialValue: payload.documentType)
        _notes = State(initialValue: payload.notes)
        _linkedVehicleIDs = State(initialValue: payload.linkedVehicleIDs)
    }

    private var canShowLinkPicker: Bool {
        showsLinkingControls && availableVehicles.count > 1
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                InstrumentTextField(
                    label: "File Name",
                    text: $fileName,
                    placeholder: "document.pdf",
                    isRequired: true
                )

                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.documentsTypeLabel.uppercased())
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.textTertiary)
                        .tracking(1.5)

                    Menu {
                        ForEach(DocumentType.listOrder) { type in
                            Button {
                                documentType = type
                            } label: {
                                Label(type.displayName, systemImage: type.icon)
                            }
                        }
                    } label: {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: documentType.icon)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(documentType.accentColor)

                            Text(documentType.displayName.uppercased())
                                .font(.brutalistBody)
                                .tracking(1)
                                .foregroundStyle(Theme.textPrimary)

                            Spacer()

                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Theme.textTertiary)
                        }
                        .padding(Spacing.md)
                        .background(Theme.surfaceInstrument)
                        .brutalistBorder()
                    }
                }

                RichNotesEditor(
                    label: L10n.documentsNotesLabel,
                    text: $notes,
                    placeholder: L10n.documentsNotesPlaceholder,
                    minHeight: 100
                )

                if canShowLinkPicker {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        InstrumentSectionHeader(title: L10n.documentsLinkToOtherVehicles)

                        Button {
                            showVehiclePicker = true
                        } label: {
                            HStack {
                                Text(linkedVehicleSummary)
                                    .font(.brutalistBody)
                                    .foregroundStyle(Theme.textPrimary)
                                    .lineLimit(1)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Theme.textTertiary)
                            }
                            .padding(Spacing.md)
                            .background(Theme.surfaceInstrument)
                            .brutalistBorder()
                        }
                        .buttonStyle(.plain)
                    }
                }

                HStack(spacing: Spacing.sm) {
                    Button("Back") { onCancel() }
                        .buttonStyle(.secondary)

                    Button("Save") {
                        var updated = payload
                        updated.fileName = fileName.isEmpty ? payload.fileName : fileName
                        updated.documentType = documentType
                        updated.notes = notes
                        updated.linkedVehicleIDs = linkedVehicleIDs
                        onSave(updated)
                    }
                    .buttonStyle(.primary)
                    .disabled(fileName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .padding(Spacing.screenHorizontal)
            .padding(.vertical, Spacing.lg)
        }
        .sheet(isPresented: $showVehiclePicker) {
            VehicleMultiPicker(
                allVehicles: availableVehicles,
                selection: $linkedVehicleIDs,
                lockedVehicleIDs: [currentVehicle.id]
            )
        }
        .onChange(of: documentType) { _, newValue in
            var updated = payload
            updated.documentType = newValue
            onUpdate(updated)
        }
    }

    private var linkedVehicleSummary: String {
        let linked = availableVehicles.filter { linkedVehicleIDs.contains($0.id) }
        if linked.count <= 1 {
            return currentVehicle.displayName
        }
        return L10n.documentsLinkedCount(linked.count)
    }
}

// MARK: - File Picker Representable

struct FilePickerRepresentable: UIViewControllerRepresentable {
    let onFilePicked: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf, UTType.image])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onFilePicked: onFilePicked)
    }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onFilePicked: (URL) -> Void

        init(onFilePicked: @escaping (URL) -> Void) {
            self.onFilePicked = onFilePicked
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onFilePicked(url)
        }
    }
}
