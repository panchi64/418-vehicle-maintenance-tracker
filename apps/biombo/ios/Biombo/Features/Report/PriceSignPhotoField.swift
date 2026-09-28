import SwiftUI
import UIKit

/// The optional sign photo under a typed price (PRODUCT.md §6.1, open
/// decision 26): take or pick one, see it, remove it. Says plainly that it
/// stays private and carries no location.
struct PriceSignPhotoField: View {
    @Binding var photo: Data?
    /// What reading the sign found, once a photo is in.
    let readNote: LocalizedStringResource?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            if let photo, let image = UIImage(data: photo) {
                HStack(spacing: Spacing.s3) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 64, height: 64)
                        .clipShape(.rect(cornerRadius: Radius.small))
                        .accessibilityLabel(Text("Foto del letrero", comment: "VoiceOver: the price sign photo"))
                    VStack(alignment: .leading, spacing: 2) {
                        if let readNote {
                            Text(readNote)
                                .textRole(.footnote)
                                .foregroundStyle(Color(.ink))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Button(role: .destructive) { self.photo = nil } label: {
                            Text("Quitar foto", comment: "Price report: remove the sign photo")
                                .textRole(.subheadline)
                                .frame(minHeight: Size.target)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(Color(.statusCritical))
                    }
                    Spacer(minLength: 0)
                }
            } else {
                PhotoSourceButtons(
                    cameraTitle: LocalizedStringResource("Retratar el letrero", comment: "Price report: take a photo of the price sign"),
                    libraryTitle: LocalizedStringResource("Elegir foto", comment: "Pick a photo from the library")
                ) { photo = $0 }
            }
            Label {
                Text("La foto es opcional y privada hasta que otros confirmen el precio. Le quitamos la ubicación.", comment: "Price report: the sign photo is optional, private until confirmed, and has its location removed")
            } icon: {
                Image(systemName: "lock").accessibilityHidden(true)
            }
            .textRole(.footnote)
            .foregroundStyle(Color(.ink2))
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}
