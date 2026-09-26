//
//  ServiceLogForm+Receipt.swift
//  checkpoint
//
//  Reading a receipt into the form: from the first-row Scan, from the
//  attachment row's Receipt button, or handed over from Visual Intelligence.
//  Every scanned page is attached (with its text, so it is searchable), and
//  the first page is read for values (`ReceiptExtractionService`). A photo
//  that can't be read is still attached, and the form says so.
//

import SwiftUI

extension ServiceLogForm {

    /// Whether the receipt row shows: a new or completed entry that
    /// happened, on a device with the document camera. Not for "Not done
    /// yet", and not when editing history.
    var offersReceipt: Bool {
        !model.mode.isEdit && model.isLogging && ReceiptScannerView.isAvailable
    }

    func readReceipt(_ images: [UIImage]) {
        guard let first = images.first else { return }
        isReadingReceipt = true
        let context = ReceiptExtractionService.context(for: vehicle)

        Task {
            defer { isReadingReceipt = false }
            var firstPageText: String?
            do {
                let result = try await ReceiptExtractionService().extract(from: first, context: context)
                firstPageText = result.scan.transcript
                if result.draft.isEmpty {
                    ToastService.shared.show(L10n.receiptNothingRead, icon: "doc.text.magnifyingglass", style: .info)
                } else {
                    withAnimation(.easeOut(duration: Theme.animationMedium)) {
                        model.apply(receipt: result.draft)
                    }
                    HapticService.shared.success()
                }
            } catch ReceiptOCRService.OCRError.tooBlurry {
                ToastService.shared.show(L10n.receiptTooBlurry, icon: "camera.metering.unknown", style: .error)
            } catch {
                ToastService.shared.show(L10n.receiptNothingRead, icon: "doc.text.magnifyingglass", style: .info)
            }

            for (index, image) in images.enumerated() {
                let text = index == 0
                    ? firstPageText
                    : try? await ReceiptOCRService.shared.extractText(from: image).text
                if let attachment = AttachmentPicker.AttachmentData.scannedReceipt(image, page: index + 1, extractedText: text) {
                    model.pendingAttachments.append(attachment)
                }
            }
        }
    }

    /// The outside doors, once each: Visual Intelligence hands over a
    /// receipt to read; the Scan Receipt Control asks for the scanner.
    func readHandedOverReceipt() {
        if opensReceiptScanner, !didOpenRequestedScanner, offersReceipt {
            didOpenRequestedScanner = true
            showReceiptScanner = true
        }
        guard let receiptImage, model.receipt == nil, !isReadingReceipt, model.pendingAttachments.isEmpty else { return }
        readReceipt([receiptImage])
    }
}
