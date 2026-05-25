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
                make: "Honda",
                model: "NSX Type R",
                year: 1992,
                currentMileage: 18200,
                vin: "NA1-1200034",
                tireSize: "205/50R15 F, 225/50R16 R",
                oilType: "10W-30",
                notes: "JDM-spec NSX-R. Hand-balanced C30A V6. Garage kept.",
                mileageUpdatedAt: Calendar.current.date(byAdding: .day, value: -14, to: .now)
            )
        ]
    }
}
