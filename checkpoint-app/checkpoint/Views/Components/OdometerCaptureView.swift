//
//  OdometerCaptureView.swift
//  checkpoint
//
//  Custom camera view with viewfinder guide for capturing odometer photos
//  Uses AVCaptureSession for direct camera control and guided framing
//

import SwiftUI
import AVFoundation

// MARK: - SwiftUI Wrapper

/// SwiftUI representable for the custom odometer capture camera
struct OdometerCaptureView: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> OdometerCaptureViewController {
        let controller = OdometerCaptureViewController()
        controller.onImageCaptured = onImageCaptured
        controller.onCancel = onCancel
        return controller
    }

    func updateUIViewController(_ uiViewController: OdometerCaptureViewController, context: Context) {}
}

// MARK: - View Controller

/// Camera view controller with viewfinder overlay for odometer capture
class OdometerCaptureViewController: UIViewController {

    var onImageCaptured: ((UIImage) -> Void)?
    var onCancel: (() -> Void)?

    private let captureSession = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?

    // Viewfinder guide rect in view coordinates
    private var viewfinderRect: CGRect = .zero

    // Theme colors (matches cerulean design system)
    private let ceruleanPrimary = UIColor(red: 0.0, green: 0.2, blue: 0.745, alpha: 1.0)
    private let accentOffWhite = UIColor(red: 0.961, green: 0.941, blue: 0.863, alpha: 1.0)

    // UI elements
    private let viewfinderBorder = CAShapeLayer()
    private let maskLayer = CAShapeLayer()
    private let guideLabel = UILabel()
    private let captureButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
        setupViewfinderOverlay()
        setupControls()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
        updateViewfinderLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession.stopRunning()
    }

    override var prefersStatusBarHidden: Bool { true }

    // MARK: - Camera Setup

    private func setupCamera() {
        captureSession.sessionPreset = .photo

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            return
        }

        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }

        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }

        let preview = AVCaptureVideoPreviewLayer(session: captureSession)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        view.layer.addSublayer(preview)
        self.previewLayer = preview
    }

    // MARK: - Viewfinder Overlay

    private func setupViewfinderOverlay() {
        // Semi-transparent cerulean mask
        maskLayer.fillRule = .evenOdd
        maskLayer.fillColor = ceruleanPrimary.withAlphaComponent(0.75).cgColor
        view.layer.addSublayer(maskLayer)

        // Accent border rectangle
        viewfinderBorder.strokeColor = accentOffWhite.cgColor
        viewfinderBorder.fillColor = UIColor.clear.cgColor
        viewfinderBorder.lineWidth = 2
        view.layer.addSublayer(viewfinderBorder)

        // Guide label
        guideLabel.text = "ALIGN ODOMETER HERE"
        guideLabel.textColor = accentOffWhite
        guideLabel.font = .systemFont(ofSize: 13, weight: .bold)
        guideLabel.textAlignment = .center
        guideLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(guideLabel)
    }

    private func updateViewfinderLayout() {
        let bounds = view.bounds

        // 80% screen width, ~3:1 aspect ratio, center-lower third
        let width = bounds.width * 0.80
        let height = width / 3.0
        let x = (bounds.width - width) / 2
        let y = bounds.height * 0.5 - height / 2 + bounds.height * 0.05

        viewfinderRect = CGRect(x: x, y: y, width: width, height: height)

        // Update mask (full screen with cutout)
        let fullPath = UIBezierPath(rect: bounds)
        let cutoutPath = UIBezierPath(rect: viewfinderRect)
        fullPath.append(cutoutPath)
        maskLayer.path = fullPath.cgPath

        // Update border
        viewfinderBorder.path = UIBezierPath(rect: viewfinderRect).cgPath

        // Update label position
        guideLabel.frame = CGRect(
            x: viewfinderRect.origin.x,
            y: viewfinderRect.maxY + 12,
            width: viewfinderRect.width,
            height: 20
        )
    }

    // MARK: - Controls

    private func setupControls() {
        // Capture button
        captureButton.setTitle("CAPTURE", for: .normal)
        captureButton.setTitleColor(ceruleanPrimary, for: .normal)
        captureButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
        captureButton.backgroundColor = accentOffWhite
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        captureButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        view.addSubview(captureButton)

        // Cancel button
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(accentOffWhite, for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.addTarget(self, action: #selector(cancelCapture), for: .touchUpInside)
        view.addSubview(cancelButton)

        NSLayoutConstraint.activate([
            // Capture button: bottom center
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -32),
            captureButton.widthAnchor.constraint(equalToConstant: 160),
            captureButton.heightAnchor.constraint(equalToConstant: 52),

            // Cancel button: top-left
            cancelButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            cancelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
        ])
    }

    // MARK: - Actions

    @objc private func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    @objc private func cancelCapture() {
        onCancel?()
    }

    // MARK: - Cropping

    /// Crops the captured image to the viewfinder guide region
    /// - Parameters:
    ///   - image: The full captured image
    ///   - viewfinderRect: The viewfinder rectangle in view coordinates
    ///   - previewLayerSize: The size of the preview layer
    /// - Returns: Cropped UIImage, or original if cropping fails
    static func cropToViewfinder(
        image: UIImage,
        viewfinderRect: CGRect,
        previewLayerSize: CGSize
    ) -> UIImage {
        // Normalize the image so pixel layout matches the displayed orientation.
        // Camera sensor captures in landscape; portrait photos have .right orientation.
        // Without normalizing, the crop maps portrait screen coordinates onto a
        // landscape pixel buffer, cutting a vertical strip instead of horizontal.
        let normalized = Self.normalizeOrientation(image)
        guard let cgImage = normalized.cgImage else { return image }

        let imageWidth = CGFloat(cgImage.width)
        let imageHeight = CGFloat(cgImage.height)

        // Convert viewfinder rect from preview coordinates to image coordinates
        let scaleX = imageWidth / previewLayerSize.width
        let scaleY = imageHeight / previewLayerSize.height

        // Use the larger scale for aspect-fill behavior
        let scale = max(scaleX, scaleY)

        // Calculate offset for centering (aspect-fill crops edges)
        let scaledPreviewWidth = imageWidth / scale
        let scaledPreviewHeight = imageHeight / scale
        let offsetX = (previewLayerSize.width - scaledPreviewWidth) / 2
        let offsetY = (previewLayerSize.height - scaledPreviewHeight) / 2

        // Map viewfinder rect to image space
        let cropRect = CGRect(
            x: (viewfinderRect.origin.x - offsetX) * scale,
            y: (viewfinderRect.origin.y - offsetY) * scale,
            width: viewfinderRect.width * scale,
            height: viewfinderRect.height * scale
        )

        // Clamp to image bounds
        let clampedRect = cropRect.intersection(CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight))

        guard !clampedRect.isEmpty, let cropped = cgImage.cropping(to: clampedRect) else {
            return image
        }

        return UIImage(cgImage: cropped)
    }

    /// Renders the UIImage into a new bitmap with orientation applied,
    /// so the CGImage pixel layout matches the visual display.
    private static func normalizeOrientation(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }

        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        return renderer.image { _ in
            image.draw(at: .zero)
        }
    }
}

// MARK: - Photo Capture Delegate

extension OdometerCaptureViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let fullImage = UIImage(data: data) else {
            onCancel?()
            return
        }

        let previewSize = previewLayer?.frame.size ?? view.bounds.size
        let croppedImage = Self.cropToViewfinder(
            image: fullImage,
            viewfinderRect: viewfinderRect,
            previewLayerSize: previewSize
        )

        onImageCaptured?(croppedImage)
    }
}
