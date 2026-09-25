//
//  L10n+Cards.swift
//  checkpoint
//
//  Visible labels for the vehicle specs panel and recall cards. Keys are
//  prefixed `specs.` and `recall.card.`. (VoiceOver strings for cards live in
//  L10n+Readouts.swift.)
//

import Foundation

extension L10n {
    private static func cards(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    // MARK: - Quick specs

    static var specsPlate: String { cards("specs.plate") }
    static var specsVIN: String { cards("specs.vin") }
    static var specsTires: String { cards("specs.tires") }
    static var specsOil: String { cards("specs.oil") }
    static var specsNotes: String { cards("specs.notes") }
    static var specsReadMore: String { cards("specs.readMore") }
    static var specsEmpty: String { cards("specs.empty") }
    static var specsEdit: String { cards("specs.edit") }
    static var specsAdd: String { cards("specs.add") }
    static var specsMarbete: String { cards("specs.marbete") }

    // MARK: - Recalls

    static var recallCardParkIt: String { cards("recall.card.parkIt") }
    static var recallCardSummary: String { cards("recall.card.summary") }
    static var recallCardRisk: String { cards("recall.card.risk") }
    static var recallCardRemedy: String { cards("recall.card.remedy") }
    static var recallCardUpdateStatus: String { cards("recall.card.updateStatus") }
    /// "NHTSA #24V123000" — the campaign number is the only argument.
    static func recallCardCampaign(_ number: String) -> String {
        String(format: cards("recall.card.campaign"), number)
    }
}
