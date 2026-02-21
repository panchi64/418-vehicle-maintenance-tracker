//
//  Vehicle+SampleData.swift
//  checkpoint
//
//  Sample data for previews and testing
//

import Foundation

extension Vehicle {
    static var sampleVehicle: Vehicle {
        let vehicle = Vehicle(
            name: "Daily Driver",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentMileage: 32500,
            vin: "4T1BF1FK5CU123456",
            licensePlate: "ABC-1234",
            tireSize: "215/55R17",
            oilType: "0W-20 Synthetic",
            notes: "Purchased certified pre-owned. Runs great!",
            mileageUpdatedAt: Calendar.current.date(byAdding: .day, value: -3, to: .now),
            marbeteExpirationMonth: 3,
            marbeteExpirationYear: 2026
        )
        return vehicle
    }

    static var sampleVehicles: [Vehicle] {
        [
            Vehicle(
                name: "Daily Driver",
                make: "Toyota",
                model: "Camry",
                year: 2022,
                currentMileage: 32500,
                vin: "4T1BF1FK5CU123456",
                tireSize: "215/55R17",
                oilType: "0W-20 Synthetic",
                notes: "Purchased certified pre-owned. Runs great!",
                mileageUpdatedAt: Calendar.current.date(byAdding: .day, value: -3, to: .now),
                marbeteExpirationMonth: 3,
                marbeteExpirationYear: 2026
            ),
            Vehicle(
                name: "Weekend Car",
                make: "Mazda",
                model: "MX-5",
                year: 2020,
                currentMileage: 18200,
                vin: "JM1NDAD75L0123789",
                tireSize: "205/45R17",
                oilType: "0W-20 Synthetic",
                notes: "Garage kept. Summer tires only.",
                mileageUpdatedAt: Calendar.current.date(byAdding: .day, value: -14, to: .now)
            )
        ]
    }
}
