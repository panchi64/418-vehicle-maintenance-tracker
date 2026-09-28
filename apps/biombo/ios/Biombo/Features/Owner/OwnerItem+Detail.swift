import Foundation

extension PlaceMoreMenu.OwnerItem {
    /// A business's owner entry for this device (§5, §6.8): post as its
    /// verified owner, wait for a claim in review, or claim it when nobody
    /// holds it. Other places have none.
    static func `for`(_ detail: PlaceDetail, contributions: ContributionStore, open: @escaping (HomeModal) -> Void) -> Self {
        guard let place = detail.place, place.kind == .business else { return .none }
        if contributions.isOwner(of: place.id, now: detail.now) {
            return .post { open(.ownerPost(place.id)) }
        }
        if contributions.claimsInReview.contains(place.id) { return .inReview }
        return place.hasVerifiedOwner ? .none : .claim { open(.claim(place.id)) }
    }
}
