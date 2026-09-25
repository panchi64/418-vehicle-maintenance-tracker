//
//  L10n+NHTSA.swift
//  checkpoint
//
//  VIN-decode and recall lookup errors. Keys are prefixed `nhtsa.`.
//  `nonisolated` because the errors surface from the `NHTSAService` actor.
//

import Foundation

extension L10n {
    nonisolated private static func nhtsa(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    nonisolated static var nhtsaInvalidVIN: String { nhtsa("nhtsa.error.invalidVIN") }
    nonisolated static var nhtsaOffline: String { nhtsa("nhtsa.error.offline") }
    nonisolated static var nhtsaServerError: String { nhtsa("nhtsa.error.server") }
    nonisolated static var nhtsaDecodingFailed: String { nhtsa("nhtsa.error.decoding") }
    nonisolated static var nhtsaNoResults: String { nhtsa("nhtsa.error.noResults") }
    nonisolated static var nhtsaTimeout: String { nhtsa("nhtsa.error.timeout") }
}
