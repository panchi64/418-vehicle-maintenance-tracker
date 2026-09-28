import SwiftUI

/// "Publicar como dueño" (PRODUCT.md §6.8, Contribute-OwnerPost): today's
/// status first, then what's in stock and an event, and a preview of how
/// neighbours will see it. The status shows until midnight. Owner text that
/// names an agency or reads like an alert can't be published (§5).
struct OwnerPostView: View {
    let place: Place
    let now: Date

    @State private var draft: OwnerPostDraft
    @Environment(ContributionStore.self) private var contributions
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(place: Place, now: Date) {
        self.place = place
        self.now = now
        _draft = State(initialValue: OwnerPostDraft(now: now))
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.s6) {
                        VStack(alignment: .leading, spacing: Spacing.s2) {
                            OwnerPlaceHeader(place: place)
                            VerificationBadge(label: .verifiedOwner)
                        }
                        statusSection
                        if draft.status != .closedToday {
                            productSection
                                .id(BlockedTermLine.Field.product)
                        }
                        OwnerEventSection(draft: $draft)
                        OwnerPostPreview(place: place, draft: draft)
                    }
                    .padding(.horizontal, Spacing.gutter)
                    .padding(.vertical, Spacing.s4)
                }
                // A blocked word's line appears under its field; bring it above the keyboard.
                .onChange(of: draft.productBlockedTerm) { _, term in
                    if term != nil { reveal(.product, with: proxy) }
                }
                .onChange(of: draft.eventBlockedTerm) { _, term in
                    if term != nil { reveal(.event, with: proxy) }
                }
            }
            .background(Color(.paperSheet))
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(Text("Publicar como dueño", comment: "More menu: post as this business's verified owner"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Text("Cancelar", comment: "Cancel") }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: publish) { Text("Publicar", comment: "Verb: the verified owner posts today's status") }
                        .disabled(!draft.canPublish)
                }
            }
        }
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            SectionHeader(title: LocalizedStringResource("¿Cómo estás hoy?", comment: "Owner post: today's status"))
            VStack(alignment: .leading, spacing: 0) {
                RowList(elements: OwnerPostDraft.Status.allCases, isInset: true) { status in
                    PinChoiceRow(
                        layer: .businesses, glyph: status.symbol,
                        title: Text(status.kind.verbForOwner),
                        accessory: draft.status == status ? .selected : .none
                    ) { draft.status = status }
                }
            }
            .insetGroup()
            Text("Se muestra hasta las \(OwnerPostDraft.endOfDay(for: now).islandClock(locale: locale)) de hoy. Mañana te preguntamos otra vez.", comment: "Owner post: the status shows until the end of today")
                .textRole(.footnote)
                .foregroundStyle(Color(.ink2))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var productSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            SectionHeader(title: LocalizedStringResource("¿Qué tienes?", comment: "Owner post: what's in stock"), aside: LocalizedStringResource("Opcional", comment: "An optional field"))
            TextField(text: $draft.product, prompt: Text("Hielo, agua, pan…", comment: "Owner post: example products in stock")) {
                Text("¿Qué tienes?", comment: "Owner post: what's in stock")
            }
            .textRole(.body)
            .padding(.horizontal, Spacing.s4)
            .frame(minHeight: Size.target)
            .background(Color(.paperRaised), in: .rect(cornerRadius: Radius.medium))
            .contrastEdge()
            // Right under the field, so it shows above the keyboard while typing.
            if let term = draft.productBlockedTerm {
                BlockedTermLine(term: term)
            }
        }
    }

    private func reveal(_ field: BlockedTermLine.Field, with proxy: ScrollViewProxy) {
        if reduceMotion {
            proxy.scrollTo(field, anchor: .bottom)
        } else {
            withAnimation { proxy.scrollTo(field, anchor: .bottom) }
        }
    }

    private func publish() {
        contributions.published(draft.reports(for: place.id, now: now))
        dismiss()
    }
}

extension OwnerPostDraft.Status {
    var symbol: String {
        switch self {
        case .open: "storefront.fill"
        case .onGenerator: "powerplug.fill"
        case .closedToday: "xmark"
        }
    }
}

extension ReportKind {
    /// An owner's status choice, said by the owner ("Cerrado hoy").
    var verbForOwner: LocalizedStringResource {
        switch self {
        case .businessOnGenerator: LocalizedStringResource("Abierto con planta", comment: "Quick Report verb: open on a generator")
        case .businessClosed: LocalizedStringResource("Cerrado hoy", comment: "Owner post status: closed today")
        default: LocalizedStringResource("Abierto", comment: "Answer word: the business is open")
        }
    }
}
