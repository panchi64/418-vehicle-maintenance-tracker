//
//  WatchDistanceUnitTests.swift
//  CheckpointWatch Watch AppTests
//
//  Tests that the Watch resolves the synced distance unit and converts
//  dial values between the user's unit and miles (the phone's storage unit)
//

import Foundation
import Testing
@testable import CheckpointWatch_Watch_App

struct WatchDistanceUnitTests {

    private func vehicle(mileage: Int, unit: String) -> WatchVehicleData {
        WatchVehicleData(
            vehicleID: "v1",
            vehicleName: "Car",
            currentMileage: mileage,
            estimatedMileage: nil,
            isEstimated: false,
            services: [],
            updatedAt: Date(),
            distanceUnit: unit
        )
    }

    @Test func resolvesKilometers() {
        #expect(vehicle(mileage: 0, unit: "kilometers").resolvedDistanceUnit == .kilometers)
    }

    @Test func unknownUnitFallsBackToMiles() {
        #expect(vehicle(mileage: 0, unit: "furlongs").resolvedDistanceUnit == .miles)
    }

    @Test func kilometersDialShowsConvertedValueAndLabel() {
        let data = vehicle(mileage: 10_000, unit: "kilometers")
        let unit = data.resolvedDistanceUnit
        #expect(unit.fromMiles(data.currentMileage) == 16_093)
        #expect(unit.uppercaseAbbreviation == "KM")
    }

    @Test func kilometersDialValueIsSentAsMiles() {
        let unit = vehicle(mileage: 10_000, unit: "kilometers").resolvedDistanceUnit
        // User dials up 100 km from the displayed 16,093 km
        #expect(unit.toMiles(16_193) == 10_062)
    }

    @Test func unchangedKilometersDialRoundTripsToSameMiles() {
        let data = vehicle(mileage: 45_000, unit: "kilometers")
        let unit = data.resolvedDistanceUnit
        #expect(unit.toMiles(unit.fromMiles(data.currentMileage)) == data.currentMileage)
    }

    @Test func milesDialIsUnchanged() {
        let data = vehicle(mileage: 45_000, unit: "miles")
        let unit = data.resolvedDistanceUnit
        #expect(unit.fromMiles(data.currentMileage) == 45_000)
        #expect(unit.toMiles(45_010) == 45_010)
        #expect(unit.uppercaseAbbreviation == "MI")
    }
}
