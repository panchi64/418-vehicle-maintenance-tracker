//
//  IntentDonationsTests.swift
//  checkpointTests
//
//  Donations run on the app's own save paths, so building one must never
//  fail a save — including the mileage donation, which leaves its reading
//  unset on purpose.
//

import XCTest
@testable import checkpoint

final class IntentDonationsTests: IntentTestCase {

    func test_donations_buildFromModelsWithoutFailing() {
        let oil = addService()
        IntentDonations.updatedMileage(on: vehicle)
        IntentDonations.markedDone(successor: oil)
        IntentDonations.markedDone(successor: nil)
        IntentDonations.loggedServices(["Oil Change"], on: vehicle)
        IntentDonations.loggedServices([], on: vehicle)
        IntentDonations.addedService(oil)
    }
}
