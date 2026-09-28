import SwiftUI

/// Everything under a selection's answer, with this device's side of it:
/// whether it watches the place, owns it, made the answer's report, or
/// already voted (PRODUCT.md §4.3). A vote is recorded when the question is
/// answered; Deshacer puts back the vote that stood before it.
struct SelectionContent: View {
    let store: HomeStore
    let detail: PlaceDetail
    let snapshot: PlacesSnapshot
    let onReport: () -> Void
    /// "Otro precio": straight to "¿A cuánto está?" at this station.
    let onReportPrice: (Place.ID) -> Void

    @Environment(WatchStore.self) private var watches
    @Environment(ContributionStore.self) private var contributions
    /// The vote this visit's reply replaced, for Deshacer; nil when no reply counted yet.
    @State private var replaced: ReplacedVote?

    private struct ReplacedVote {
        let target: MyVote.Target
        let previous: MyVote?
    }

    var body: some View {
        let target = detail.watchTarget(in: snapshot.places)
        let watch = target.flatMap { watches.watch(for: $0.id) }
        let standing = detail.voteTarget.flatMap { contributions.votes.vote(on: $0) }
        PlaceDetailContent(
            detail: detail,
            tier: store.tier,
            confirmStep: ConfirmStep.shown(store.confirmStep, standing: standing, isRevising: store.isRevisingVote),
            isWatching: watch != nil,
            isOwnAnswer: detail.answer.map { contributions.ownReportIDs.contains($0.lead.id) } ?? false,
            isOwner: detail.place.map { contributions.isOwner(of: $0.id, now: detail.now) } ?? false,
            onReply: reply,
            onUndo: undo,
            onRevise: store.reviseVote,
            onWatch: {
                if let draft = watch ?? detail.watchDraft(in: snapshot.places) { store.beginWatch(draft) }
            },
            onReport: onReport,
            onOtherPrice: {
                if let id = detail.place?.id { onReportPrice(id) }
            },
            onOwnerPost: {
                if let id = detail.place?.id { store.open(.ownerPost(id)) }
            }
        )
    }

    /// The reply moves the question on; a final one is also a vote. A price's
    /// "Ya no" waits for what changed before it counts. A vote the rules
    /// refuse takes the reply back, so no thanks shows for it.
    private func reply(_ reply: ConfirmReply) {
        guard let question = detail.question else { return }
        store.reply(reply, to: question)
        let isFollowUpPending = reply == .changed && question.asksWhatChanged && store.confirmStep == .askingWhatChanged
        guard !isFollowUpPending, let target = detail.voteTarget else { return }
        do {
            let previous = try contributions.vote(reply.agrees, on: target, at: detail.now)
            replaced = ReplacedVote(target: target, previous: previous)
        } catch {
            store.undoReply()
        }
    }

    private func undo() {
        store.undoReply()
        if let replaced { contributions.restoreVote(replaced.previous, on: replaced.target) }
        replaced = nil
    }
}

extension PlaceDetail {
    /// What a Sigue igual / Ya no here counts on: the answer's report, or the area.
    nonisolated var voteTarget: MyVote.Target? {
        if let area { return .area(area.id) }
        return answer.map { .report($0.lead.id) }
    }
}
