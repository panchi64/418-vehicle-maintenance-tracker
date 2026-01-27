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

/// Full-featured camera sheet with tips overlay
struct OdometerCameraSheet: View {
    @Environment(\.dismiss) private var dismiss

    /// Callback when an image is captured
    let onImageCaptured: (UIImage) -> Void

    @State private var showTips = true

    var body: some View {
        ZStack {
            // Camera view
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

            // Tips overlay (dismisses after first tap or auto-hides)
            if showTips {
                cameraTipsOverlay
                    .transition(.opacity)
                    .onTapGesture {
                        withAnimation(.easeOut(duration: Theme.animationMedium)) {
                            showTips = false
                        }
                    }
                    .onAppear {
                        // Auto-hide after 3 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation(.easeOut(duration: Theme.animationMedium)) {
                                showTips = false
                            }
                        }
                    }
            }
        }
    }

    private var cameraTipsOverlay: some View {
        VStack {
            Spacer()

            VStack(spacing: Spacing.sm) {
                Text("TIPS FOR BEST RESULTS")
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.accent)
                    .tracking(2)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    tipRow(icon: "lightbulb.fill", text: "Ensure good lighting")
                    tipRow(icon: "camera.viewfinder", text: "Center the odometer in frame")
                    tipRow(icon: "hand.raised.fill", text: "Hold steady to avoid blur")
                }
            }
            .padding(Spacing.md)
            .background(Theme.surfaceInstrument.opacity(0.95))
            .overlay(
                Rectangle()
                    .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
            )
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.bottom, Spacing.xxl)
        }
    }

    private func tipRow(icon: String, text: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.accent)
                .frame(width: 16)

            Text(text)
                .font(.brutalistSecondary)
                .foregroundStyle(Theme.textPrimary)
        }
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
