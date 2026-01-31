//
//  ReceiptScannerView.swift
//  checkpoint
//
//  VisionKit document scanner wrapper for capturing receipts and invoices
//

import SwiftUI
import VisionKit

/// SwiftUI wrapper for VNDocumentCameraViewController
struct ReceiptScannerView: UIViewControllerRepresentable {
    /// Callback with scanned images (one per page)
    let onImagesScanned: ([UIImage]) -> Void
    /// Callback when user cancels scanning
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImagesScanned: onImagesScanned, onCancel: onCancel)
    }

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onImagesScanned: ([UIImage]) -> Void
        let onCancel: () -> Void

        init(onImagesScanned: @escaping ([UIImage]) -> Void, onCancel: @escaping () -> Void) {
            self.onImagesScanned = onImagesScanned
            self.onCancel = onCancel
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            // Extract images from all scanned pages
            var images: [UIImage] = []
            for pageIndex in 0..<scan.pageCount {
                images.append(scan.imageOfPage(at: pageIndex))
            }

            controller.dismiss(animated: true) {
                self.onImagesScanned(images)
            }
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true) {
                self.onCancel()
            }
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            controller.dismiss(animated: true) {
                self.onCancel()
            }
        }
    }
}
