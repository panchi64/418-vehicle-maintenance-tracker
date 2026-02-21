//
//  SiriState.swift
//  checkpoint
//
//  Siri intent mileage update state
//

import Foundation

struct SiriState {
    var pendingMileageUpdate: MileageUpdate?

    struct MileageUpdate {
        let vehicleID: String
        let mileage: Int
    }
}
