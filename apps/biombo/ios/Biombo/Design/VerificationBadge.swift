import SwiftUI

/// A verification label on its own (PRODUCT.md §4.5): symbol plus word in
/// the label's ink, never colour alone. "Oficial · LUMA", "Dueño verificado".
struct VerificationBadge: View {
    let label: VerificationLabel
    var role: TextRole = .footnote

    var body: some View {
        Label { Text(label.title) } icon: { Image(systemName: label.symbol).accessibilityHidden(true) }
            .textRole(role)
            .fontWeight(.medium)
            .foregroundStyle(Color(label.ink))
    }
}
