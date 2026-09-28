import PhotosUI
import SwiftUI
import UIKit

/// "Tomar foto" and "Elegir foto": the camera where the device has one, and
/// the photo library. Hands back the image data, stripped of EXIF and GPS
/// (`PriceSignPhoto.stripped`), so nothing with a location leaves this view.
/// Used for price signs and an owner's business document.
struct PhotoSourceButtons: View {
    let cameraTitle: LocalizedStringResource
    let libraryTitle: LocalizedStringResource
    let onPhoto: (Data) -> Void

    @State private var pickedItem: PhotosPickerItem?
    @State private var isCameraOpen = false

    var body: some View {
        HStack(spacing: Spacing.s2) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button { isCameraOpen = true } label: {
                    SourceLabel(title: cameraTitle, symbol: "camera")
                }
                .buttonStyle(.plain)
            }
            PhotosPicker(selection: $pickedItem, matching: .images, photoLibrary: .shared()) {
                SourceLabel(title: libraryTitle, symbol: "photo.on.rectangle")
            }
            .buttonStyle(.plain)
        }
        .onChange(of: pickedItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self), let clean = await PriceSignPhoto.stripped(data) {
                    onPhoto(clean)
                }
                pickedItem = nil
            }
        }
        .fullScreenCover(isPresented: $isCameraOpen) {
            CameraPicker { data in
                Task {
                    if let clean = await PriceSignPhoto.stripped(data) { onPhoto(clean) }
                }
            }
            .ignoresSafeArea()
        }
    }
}

/// A bordered source button's face.
private struct SourceLabel: View {
    let title: LocalizedStringResource
    let symbol: String

    var body: some View {
        Label { Text(title) } icon: { Image(systemName: symbol) }
            .textRole(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.tint)
            .frame(maxWidth: .infinity, minHeight: Size.target)
            .background(Color(.paperRaised), in: .rect(cornerRadius: Radius.medium))
            .contrastEdge(always: true)
            .contentShape(.rect)
    }
}

/// The system camera, returning a JPEG.
private struct CameraPicker: UIViewControllerRepresentable {
    let onCapture: (Data) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture, dismiss: { dismiss() })
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (Data) -> Void
        let dismiss: () -> Void

        init(onCapture: @escaping (Data) -> Void, dismiss: @escaping () -> Void) {
            self.onCapture = onCapture
            self.dismiss = dismiss
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage, let data = image.jpegData(compressionQuality: 0.9) {
                onCapture(data)
            }
            dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}
