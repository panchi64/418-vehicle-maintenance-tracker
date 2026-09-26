//
//  IntelligenceAvailability.swift
//  checkpoint
//
//  The one question every on-device-model feature asks first: can Checkpoint
//  use Apple's on-device language model right now, and can it look at images?
//
//  On-device only. Private Cloud Compute is never used (user decision,
//  Sep 2026), so a device without Apple Intelligence gets the rule-based
//  readers instead — the same features, less clever, never a dead end.
//  Free: no Pro gate.
//
//  Tiers (docs/APP_INTENTS.md, "Device tiers"):
//    - text in (`@Generable`, tools)   iOS 26 + Apple Intelligence
//    - image in (`Attachment`, OCRTool) iOS 27 + Apple Intelligence
//

import Foundation
import FoundationModels

nonisolated enum IntelligenceAvailability: Equatable, Sendable {
    /// The on-device model is ready.
    case available
    /// Not on this device, or not yet: the rule-based path runs instead.
    case unavailable(Reason)

    nonisolated enum Reason: Equatable, Sendable {
        /// Hardware without Apple Intelligence.
        case deviceNotEligible
        /// Eligible, but switched off in Settings.
        case appleIntelligenceNotEnabled
        /// Enabled, still downloading or preparing.
        case modelNotReady
        /// A reason a later SDK adds.
        case other
    }

    /// The system model's state, read fresh on every call — it changes while
    /// the app runs (the model finishes downloading, the user turns Apple
    /// Intelligence off).
    static var current: IntelligenceAvailability {
        switch SystemLanguageModel.default.availability {
        case .available:
            return .available
        case .unavailable(let reason):
            switch reason {
            case .deviceNotEligible: return .unavailable(.deviceNotEligible)
            case .appleIntelligenceNotEnabled: return .unavailable(.appleIntelligenceNotEnabled)
            case .modelNotReady: return .unavailable(.modelNotReady)
            @unknown default: return .unavailable(.other)
            }
        }
    }

    var isAvailable: Bool { self == .available }

    /// Whether the model can take the receipt photo itself (`Attachment`,
    /// `OCRTool`), not just its transcript. iOS 27 and later.
    var canReadImages: Bool {
        guard isAvailable else { return false }
        if #available(iOS 27, *) { return true }
        return false
    }
}
