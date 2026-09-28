import SwiftUI

/// Everything under a detail's answer (V2-Station, Flows-StaleState). Summary:
/// a boil-water card directly under the answer, the flood or downed-line
/// safety line, the verbs and the one confirm question, then other official
/// cards. Full adds the layer's one comparison and the row into depth. With
/// nothing current, the empty state says what to do and older reports wait
/// behind one row.
struct PlaceDetailContent: View {
    let detail: PlaceDetail
    let tier: DisclosureTier
    let confirmStep: ConfirmStep
    let isWatching: Bool
    /// You made the report behind the answer, so you can't vote on it (§4.3).
    let isOwnAnswer: Bool
    /// You are this business's verified owner: Publicar replaces Reportar.
    let isOwner: Bool
    let onReply: (ConfirmReply) -> Void
    let onUndo: () -> Void
    let onRevise: () -> Void
    let onWatch: () -> Void
    let onReport: () -> Void
    /// "Otro precio" opens the price form for this station.
    let onOtherPrice: () -> Void
    let onOwnerPost: () -> Void

    @State private var isStaleRevealed = false
    @State private var isOpeningMaps = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s5) {
            if detail.lacksRoadNotice {
                // Neighbours only: said right under the answer, before any card (Crisis-RoadPassability).
                Label {
                    Text("Todavía no hay aviso oficial para este tramo.", comment: "Road detail: no official notice covers this segment")
                } icon: {
                    Image(systemName: "building.columns").accessibilityHidden(true)
                }
                .textRole(.footnote)
                .foregroundStyle(Color(.ink2))
                .fixedSize(horizontal: false, vertical: true)
            }
            ForEach(detail.boilNotices) { notice in
                OfficialCard(group: AgencyNotices(agency: notice.agency, notices: [notice]), now: detail.now)
            }
            if detail.isFlood {
                SafetyLine(kind: .flood)
            }
            if detail.isLineDown {
                SafetyLine(kind: .hazard)
            }
            if detail.isEmpty {
                emptyState
            } else {
                VerbBar(verbs: verbs)
                if isOwnAnswer {
                    Label {
                        Text("Tú lo reportaste. Solo tus vecinos pueden confirmarlo.", comment: "Detail: the answer is your own report; only others can confirm it")
                    } icon: {
                        Image(systemName: "person.crop.circle.badge.checkmark").accessibilityHidden(true)
                    }
                    .textRole(.footnote)
                    .foregroundStyle(Color(.ink2))
                    .fixedSize(horizontal: false, vertical: true)
                } else if let question = detail.question, !isOwner {
                    // An owner speaks through Publicar, never by voting on their own place.
                    ConfirmRow(question: question, step: confirmStep, canConfirm: detail.canConfirm, onReply: reply, onUndo: onUndo, onRevise: onRevise)
                }
            }
            // Right under the verbs (Flows-VisitorEN), before the comparison it explains.
            VisitorGuideCard(detail: detail, tier: tier)
            if !detail.otherNotices.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.s2) {
                    SectionHeader(title: LocalizedStringResource("Avisos oficiales", comment: "Section title: official notices"))
                    ForEach(detail.otherNotices) { group in
                        OfficialCard(group: group, now: detail.now)
                    }
                }
            }
            if tier == .full, !detail.isEmpty {
                if detail.hasFullSections {
                    PlaceFullSections(detail: detail)
                }
                NavigationLink(value: SheetRoute.depth) {
                    DisclosureLabel(title: detail.depthTitle, symbol: "info.circle")
                        .insetGroup()
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .openInMaps(isPresented: $isOpeningMaps, destination: detail.anchor, name: detail.name)
    }

    /// "Nada reportado aquí": one sentence, one verb, DACO's reference for a
    /// station, then older reports on request.
    private var emptyState: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            Text(detail.emptyPrompt)
                .textRole(.body)
                .foregroundStyle(Color(.ink2))
                .fixedSize(horizontal: false, vertical: true)
            VerbBar(verbs: [Verb(id: "report", title: detail.emptyVerb, symbol: "exclamationmark.bubble", action: onReport)])
            if !detail.stale.isEmpty {
                StaleReportsGroup(stale: detail.stale, now: detail.now, isRevealed: $isStaleRevealed)
            }
            if let reference = detail.reference {
                DacoReferenceGroup(reference: reference)
            }
        }
    }

    /// Abrir en… where there is somewhere to drive to, then Vigilar and Reportar.
    private var verbs: [Verb] {
        var verbs: [Verb] = []
        if detail.offersDirections {
            verbs.append(Verb(id: "open", title: LocalizedStringResource("Abrir en…", comment: "Verb: open directions in a maps app"), symbol: "arrow.triangle.turn.up.right.diamond") {
                isOpeningMaps = true
            })
        }
        verbs.append(Verb(
            id: "watch",
            title: isWatching
                ? LocalizedStringResource("Vigilando", comment: "Verb, on: this place is being watched")
                : LocalizedStringResource("Vigilar", comment: "Verb: watch this place for changes"),
            symbol: isWatching ? "eye.fill" : "eye",
            isOn: isWatching,
            action: onWatch
        ))
        if isOwner {
            verbs.append(Verb(id: "post", title: LocalizedStringResource("Publicar", comment: "Verb: the verified owner posts today's status"), symbol: "checkmark.seal", action: onOwnerPost))
        } else {
            verbs.append(Verb(id: "report", title: LocalizedStringResource("Reportar", comment: "Verb: report something here"), symbol: "exclamationmark.bubble", action: onReport))
        }
        return verbs
    }

    /// "Otro precio" leads straight into typing the new one.
    private func reply(_ reply: ConfirmReply) {
        onReply(reply)
        if reply == .otherPrice { onOtherPrice() }
    }
}
