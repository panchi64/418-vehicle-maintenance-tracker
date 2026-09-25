//
//  DocumentTypeMenu.swift
//  checkpoint
//
//  The labelled document-type menu shared by the add flow (DocumentPicker)
//  and the detail screen — previously two copies of the same markup.
//

import SwiftUI

struct DocumentTypeMenu: View {
    @Binding var selection: DocumentType

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L10n.documentsTypeLabel.uppercased())
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1.5)
                .accessibilityHidden(true)

            Menu {
                ForEach(DocumentType.listOrder) { type in
                    Button {
                        selection = type
                    } label: {
                        Label(type.displayName, systemImage: type.icon)
                    }
                }
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: selection.icon)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(selection.accentColor)
                        .accessibilityHidden(true)

                    Text(selection.displayName.uppercased())
                        .font(.brutalistBody)
                        .tracking(1)
                        .foregroundStyle(Theme.textPrimary)

                    Spacer()

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.textTertiary)
                        .accessibilityHidden(true)
                }
                .padding(Spacing.md)
                .frame(minHeight: TouchTarget.minimum)
                .background(Theme.surfaceInstrument)
                .brutalistBorder()
            }
            .accessibilityLabel(L10n.documentsTypeLabel)
            .accessibilityValue(selection.displayName)
        }
    }
}
