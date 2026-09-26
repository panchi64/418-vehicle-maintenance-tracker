//
//  L10n+SiriDocuments.swift
//  checkpoint
//
//  Siri sentences for the documents and export intents. Same rules as
//  `L10n+Siri`: whole sentences, `siri.` keys, values formatted by the caller.
//

import Foundation

extension L10n {
    /// "Saved it to Daily Driver's documents as Insurance." — type, vehicle.
    nonisolated static func siriDocumentSaved(type: String, vehicle: String) -> String {
        siri("siri.document.saved", type, vehicle)
    }
    /// "Here's the Insurance document for Daily Driver." — type, vehicle.
    nonisolated static func siriDocumentFound(type: String, vehicle: String) -> String {
        siri("siri.document.found", type, vehicle)
    }
    /// "Insurance · Daily Driver" — type, vehicle.
    nonisolated static func siriSnippetDocumentCaption(type: String, vehicle: String) -> String {
        siri("siri.snippet.documentCaption", type, vehicle)
    }
    /// "Here's Daily Driver's service history: 12 entries." — count, vehicle.
    nonisolated static func siriHistoryExported(count: Int, vehicle: String) -> String {
        count == 1
            ? siri("siri.history.exportedOne", vehicle)
            : siri("siri.history.exportedMany", vehicle, count)
    }
}
