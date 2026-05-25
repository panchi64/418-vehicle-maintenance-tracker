//
//  OnboardingPrefillState.swift
//  checkpoint
//
//  Onboarding pre-fill and VIN lookup passthrough state
//

import Foundation

struct OnboardingPrefillState {
    var marbeteMonth: Int?
    var marbeteYear: Int?
    var vinLookupResult: VINLookupPassthrough?

    struct VINLookupPassthrough {
        let make: String
        let model: String
        let year: Int?
        let vin: String
    }
}
