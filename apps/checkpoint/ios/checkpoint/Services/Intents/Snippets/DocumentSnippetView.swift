//
//  DocumentSnippetView.swift
//  checkpoint
//
//  The card under "show my insurance card": the document itself is the one
//  primary element — it's what the person has to hold up — with its name and
//  type under it, stepped down in size and colour. A PDF shows its first
//  page. The image is downscaled first: a snippet is drawn out of process
//  with a tight memory budget.
//

import SwiftUI
import UIKit

struct DocumentSnippetView: View {
    let image: UIImage?
    let title: String
    /// "Insurance · Daily Driver".
    let caption: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 320)
                    .accessibilityLabel(title)
            }
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(caption)
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(Spacing.md)
    }

    /// The document's picture, at most `maxDimension` points on its long side.
    @MainActor
    static func preview(of document: Document, maxDimension: CGFloat = 900) -> UIImage? {
        guard let data = document.data, let image = DocumentImport.image(from: data) else { return nil }
        let scale = min(1, maxDimension / max(image.size.width, image.size.height, 1))
        guard scale < 1 else { return image }
        return image.preparingThumbnail(of: CGSize(width: image.size.width * scale, height: image.size.height * scale)) ?? image
    }
}
