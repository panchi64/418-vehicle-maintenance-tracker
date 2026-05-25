//
//  OdometerCameraView.swift
//  checkpoint
//
//  Camera capture UI for photographing odometer displays
//  Uses UIImagePickerController for camera access
//

import SwiftUI

/// Camera view for capturing odometer photos
struct OdometerCameraView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss

    /// Callback when an image is captured
    let onImageCaptured: (UIImage) -> Void

    /// Callback when the user cancels
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.cameraDevice = .rear
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onImageCaptured: onImageCaptured,
            onCancel: onCancel
        )
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImageCaptured: (UIImage) -> Void
        let onCancel: () -> Void

        init(onImageCaptured: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
            self.onImageCaptured = onImageCaptured
            self.onCancel = onCancel
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                onImageCaptured(image)
            } else {
                onCancel()
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCancel()
        }
    }
}

// MARK: - Camera Availability Check

extension OdometerCameraView {
    /// Checks if the device has a camera available
    static var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }
}

// MARK: - Odometer Camera Sheet

/// Full-featured camera sheet using custom viewfinder on device, fallback on simulator
struct OdometerCameraSheet: View {
    @Environment(\.dismiss) private var dismiss

    /// Callback when an image is captured
    let onImageCaptured: (UIImage) -> Void

    /// Guide text shown below the viewfinder
    var guideText: String = "ALIGN ODOMETER HERE"

    /// Viewfinder aspect ratio (width / height)
    var viewfinderAspectRatio: CGFloat = 3.0

    var body: some View {
        #if targetEnvironment(simulator)
        // Simulator fallback: use UIImagePickerController
        OdometerCameraView(
            onImageCaptured: { image in
                onImageCaptured(image)
                dismiss()
            },
            onCancel: {
                dismiss()
            }
        )
        .ignoresSafeArea()
        #else
        // Device: use custom capture view with viewfinder guide
        OdometerCaptureView(
            onImageCaptured: { image in
                onImageCaptured(image)
                dismiss()
            },
            onCancel: {
                dismiss()
            },
            guideText: guideText,
            viewfinderAspectRatio: viewfinderAspectRatio
        )
        .ignoresSafeArea()
        #endif
    }
}

#Preview {
    // Note: Camera preview requires a physical device
    ZStack {
        AtmosphericBackground()

        VStack(spacing: Spacing.lg) {
            Text("Camera Preview")
                .font(.brutalistTitle)
                .foregroundStyle(Theme.textPrimary)

            Text("Camera requires physical device")
                .font(.brutalistSecondary)
                .foregroundStyle(Theme.textTertiary)

            Text("Camera available: \(OdometerCameraView.isCameraAvailable ? "YES" : "NO")")
                .font(.brutalistLabel)
                .foregroundStyle(OdometerCameraView.isCameraAvailable ? Theme.statusGood : Theme.statusOverdue)
                .tracking(1)
        }
    }
    .preferredColorScheme(.dark)
}
