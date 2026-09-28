import SwiftUI

/// Search lives in the sheet, like Maps. Focusing it opens the sheet to full.
struct SearchField: View {
    @Bindable var store: HomeStore
    @FocusState private var isFocused: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        // At accessibility sizes Cancelar goes under the field, so neither is squeezed or hyphenated.
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .trailing, spacing: Spacing.s1))
            : AnyLayout(HStackLayout(spacing: Spacing.s2))
        layout {
            HStack(spacing: Spacing.s2) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color(.ink3))
                    .accessibilityHidden(true)
                TextField(
                    text: $store.query,
                    prompt: store.searchPurpose == .watch
                        ? Text("Busca qué vigilar", comment: "Search field placeholder when picking a place to watch")
                        : Text("Buscar lugar o municipio", comment: "Search field placeholder")
                ) {
                    Text("Buscar", comment: "VoiceOver: the search field")
                }
                .textRole(.body)
                .foregroundStyle(Color(.ink))
                .focused($isFocused)
                .submitLabel(.search)
                .autocorrectionDisabled()
                if !store.query.isEmpty {
                    Button {
                        store.query = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color(.ink3))
                            .frame(minWidth: Size.target, minHeight: Size.target)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("Borrar búsqueda", comment: "VoiceOver: clear the search text"))
                }
            }
            .padding(.horizontal, Spacing.s3)
            .frame(minHeight: Size.target)
            .background(Color(.fill), in: .capsule)

            if store.mode == .searching {
                Button {
                    isFocused = false
                    store.endSearch()
                } label: {
                    Text("Cancelar", comment: "Leave search")
                        .textRole(.body)
                        .fixedSize()
                        .frame(minHeight: Size.target)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.tint)
            }
        }
        .onChange(of: isFocused) { _, focused in
            if focused && store.mode != .searching { store.beginSearch() }
        }
        .onChange(of: store.mode) { _, mode in
            if mode != .searching { isFocused = false }
        }
        // "Vigilar otro lugar" opens the search ready to type.
        .onChange(of: store.searchPurpose) { _, purpose in
            if purpose == .watch { isFocused = true }
        }
    }
}
