//
//  PhotoPickerButton.swift
//  checkpoint
//
//  Photo picker button using PhotosUI for vehicle photo selection
//

import SwiftUI
import PhotosUI

struct PhotoPickerButton: View {
    @Binding var selectedImageData: Data?
    var currentImage: Image?
    var size: CGFloat = 100

    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $selectedItem, matching: .images) {
            ZStack {
                if let data = selectedImageData,
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size, height: size)
                        .clipped()
                } else if let currentImage = currentImage {
                    currentImage
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size, height: size)
                        .clipped()
                } else {
                    // Placeholder
                    Rectangle()
                        .fill(Theme.surfaceInstrument)

                    VStack(spacing: Spacing.xs) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(Theme.accent)

                        Text("ADD_PHOTO")
                            .font(.brutalistLabel)
                            .foregroundStyle(Theme.textTertiary)
                            .tracking(1)
                    }
                }

                // Edit overlay when image exists
                if selectedImageData != nil || currentImage != nil {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "camera.fill")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Theme.surfaceInstrument)
                                .padding(6)
                                .background(Theme.accent)
                        }
                    }
                }
            }
            .frame(width: size, height: size)
            .overlay(
                Rectangle()
                    .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
            )
        }
        .buttonStyle(.plain)
        .onChange(of: selectedItem) { _, newItem in
            Task {
                await loadImage(from: newItem)
            }
        }
    }

    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item = item else { return }

        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                // Compress the image to reduce storage size
                if let compressedData = compressImage(data: data, maxSize: 500) {
                    await MainActor.run {
                        selectedImageData = compressedData
                    }
                }
            }
        } catch {
            print("Failed to load image: \(error)")
        }
    }

    /// Compress image data to target size while maintaining aspect ratio
    private func compressImage(data: Data, maxSize: CGFloat) -> Data? {
        guard let image = UIImage(data: data) else { return nil }

        // Calculate new size maintaining aspect ratio
        let scale = min(maxSize / image.size.width, maxSize / image.size.height)
        let newSize = CGSize(
            width: image.size.width * scale,
            height: image.size.height * scale
        )

        // Resize image
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        // Compress to JPEG with 0.8 quality
        return resizedImage?.jpegData(compressionQuality: 0.8)
    }
}

// MARK: - Remove Photo Button

struct RemovePhotoButton: View {
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .medium))
                Text("Remove Photo")
                    .font(.brutalistSecondary)
            }
            .foregroundStyle(Theme.statusOverdue)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var imageData: Data?

        var body: some View {
            ZStack {
                AtmosphericBackground()

                VStack(spacing: Spacing.lg) {
                    PhotoPickerButton(
                        selectedImageData: $imageData,
                        currentImage: nil
                    )

                    if imageData != nil {
                        RemovePhotoButton {
                            imageData = nil
                        }
                    }
                }
            }
        }
    }

    return PreviewWrapper()
        .preferredColorScheme(.dark)
}
