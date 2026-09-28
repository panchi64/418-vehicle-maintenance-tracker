import SwiftUI

/// "Vigilar un lugar" (PRODUCT.md §9, V2-Watch, Crisis-WatchPlaceSetup). The
/// glance question is "What will I be told about, and for where?": the
/// postcard with the person's name for the place, the promise in one
/// sentence, the three switches, the name, and a preview of the notification
/// that can be sent for real. Nothing leaves the device.
struct WatchSetupView: View {
    @State var draft: WatchedPlace
    let motif: PlateMotif?
    let isExisting: Bool
    /// False when a new watch would pass the per-device limit.
    let canAdd: Bool
    let onSave: (WatchedPlace) -> Void
    let onRemove: (WatchedPlace.ID) -> Void

    @State private var isPreviewShown = false
    @State private var previewOutcome: WatchNotifier.Outcome?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @Environment(\.theme) private var theme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s6) {
                    VStack(alignment: .leading, spacing: Spacing.s3) {
                        PostcardStrip(title: Text(verbatim: draft.name), subtitle: draft.whereLine, motif: motif)
                        Text(draft.promise(locale: locale))
                            .textRole(.answer)
                            .foregroundStyle(Color(.ink))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    SectionGroup(title: LocalizedStringResource("¿De qué te avisamos?", comment: "Watch setup section: which changes notify")) {
                        RowList(elements: Layer.watchable, isInset: true) { layer in
                            Toggle(isOn: binding(for: layer)) {
                                HStack(spacing: Spacing.s3) {
                                    LayerPin(layer: layer)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(layer.watchTitle).textRole(.body).foregroundStyle(Color(.ink))
                                        Text(layer.watchScope).textRole(.footnote).foregroundStyle(Color(.ink2))
                                    }
                                    .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .tint(theme.accentFill)
                            .frame(minHeight: Size.target)
                            .padding(.vertical, Spacing.s1)
                        }
                    }
                    SectionGroup(title: LocalizedStringResource("Nombre", comment: "Watch setup section: the name for the place")) {
                        TextField(text: $draft.name) {
                            Text("Casa de Mamá", comment: "Watch setup: example name placeholder")
                        }
                        .textRole(.body)
                        .submitLabel(.done)
                        .frame(minHeight: Size.target)
                    }
                    WatchPreview(place: draft, isShown: $isPreviewShown, outcome: previewOutcome) {
                        Task { previewOutcome = await WatchNotifier.sendPreview(for: draft, locale: locale) }
                    }
                    Text("Solo cambios en este lugar. Nunca precios ni promociones.", comment: "Watch setup footer: scope promise")
                        .textRole(.footnote)
                        .foregroundStyle(Color(.ink3))
                    if isExisting {
                        Button(role: .destructive) {
                            onRemove(draft.id)
                            dismiss()
                        } label: {
                            Text("Dejar de vigilar", comment: "Watch setup: stop watching this place")
                                .frame(maxWidth: .infinity, minHeight: Size.target)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.horizontal, Spacing.gutter)
                .padding(.vertical, Spacing.s4)
            }
            .safeAreaInset(edge: .bottom) { primaryButton }
            .navigationTitle(Text("Vigilar un lugar", comment: "Watch setup screen title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Text("Cancelar", comment: "Cancel") }
                }
            }
        }
    }

    private var isValid: Bool {
        !draft.layers.isEmpty && !draft.name.trimmingCharacters(in: .whitespaces).isEmpty && (isExisting || canAdd)
    }

    private var primaryButton: some View {
        VStack(spacing: Spacing.s1) {
            if !isExisting && !canAdd {
                Text("Ya vigilas \(WatchedPlace.limit) lugares. Deja de vigilar uno para añadir otro.", comment: "Watch setup: the per-device limit is reached")
                    .textRole(.footnote)
                    .foregroundStyle(Color(.ink2))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button {
                draft.name = draft.name.trimmingCharacters(in: .whitespaces)
                onSave(draft)
                dismiss()
            } label: {
                Text(isExisting
                     ? LocalizedStringResource("Guardar", comment: "Watch setup: save changes")
                     : LocalizedStringResource("Empezar a vigilar", comment: "Watch setup: start watching"))
                    .textRole(.headline)
                    .frame(maxWidth: .infinity, minHeight: Size.reportTarget)
                    .foregroundStyle(theme.onAccentFill)
                    .background(theme.accentFill.opacity(isValid ? 1 : 0.4), in: .rect(cornerRadius: Radius.medium))
            }
            .buttonStyle(.plain)
            .disabled(!isValid)
        }
        .padding(.horizontal, Spacing.gutter)
        .padding(.vertical, Spacing.s3)
        .background(.bar)
    }

    private func binding(for layer: Layer) -> Binding<Bool> {
        Binding(
            get: { draft.layers.contains(layer) },
            set: { isOn in
                if isOn { draft.layers.insert(layer) } else { draft.layers.remove(layer) }
            }
        )
    }
}
