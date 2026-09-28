import SwiftUI

/// "Ver todas (N)": the whole section, same rows and order, no cap.
struct SectionListView: View {
    let section: NearbySection
    let dacoRange: DacoRange?
    let now: Date
    let onPick: (NearbyItem) -> Void

    @State private var isStaleRevealed = false

    var body: some View {
        ScrollView {
            NearbySectionView(
                section: section,
                cap: .max,
                dacoRange: dacoRange,
                now: now,
                isStaleRevealed: isStaleRevealed,
                showsHeader: false,
                onReveal: { isStaleRevealed = true },
                onPick: onPick
            )
            .padding(.horizontal, Spacing.gutter)
            .padding(.bottom, Spacing.s8)
        }
        .navigationTitle(Text(section.kind.title))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }
}
