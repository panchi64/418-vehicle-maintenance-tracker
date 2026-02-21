//
//  Service+SampleData.swift
//  checkpoint
//
//  Sample data for previews and testing
//

import Foundation

extension Service {
    /// Full set of 8 services for a daily driver (Camry) — covers all statuses
    static func sampleServices(for vehicle: Vehicle) -> [Service] {
        let calendar = Calendar.current

        // dueSoon (by date + mileage)
        let oilChange = Service(
            name: "Oil change",
            dueDate: calendar.date(byAdding: .day, value: 12, to: .now),
            dueMileage: vehicle.currentMileage + 500,
            lastPerformed: calendar.date(byAdding: .month, value: -5, to: .now),
            lastMileage: vehicle.currentMileage - 4500,
            intervalMonths: 6,
            intervalMiles: 5000
        )
        oilChange.vehicle = vehicle

        // good
        let tireRotation = Service(
            name: "Tire rotation",
            dueDate: calendar.date(byAdding: .day, value: 45, to: .now),
            dueMileage: vehicle.currentMileage + 2500,
            lastPerformed: calendar.date(byAdding: .month, value: -3, to: .now),
            lastMileage: vehicle.currentMileage - 2500,
            intervalMonths: 6,
            intervalMiles: 5000
        )
        tireRotation.vehicle = vehicle

        // overdue (by date + mileage)
        let brakeInspection = Service(
            name: "Brake inspection",
            dueDate: calendar.date(byAdding: .day, value: -5, to: .now),
            dueMileage: vehicle.currentMileage - 200,
            lastPerformed: calendar.date(byAdding: .year, value: -1, to: .now),
            lastMileage: vehicle.currentMileage - 12000,
            intervalMonths: 12,
            intervalMiles: 12000
        )
        brakeInspection.vehicle = vehicle

        // good
        let airFilter = Service(
            name: "Air filter replacement",
            dueDate: calendar.date(byAdding: .month, value: 4, to: .now),
            dueMileage: vehicle.currentMileage + 8000,
            lastPerformed: calendar.date(byAdding: .year, value: -1, to: .now),
            lastMileage: vehicle.currentMileage - 12000,
            intervalMonths: 12,
            intervalMiles: 15000
        )
        airFilter.vehicle = vehicle

        // good
        let cabinAirFilter = Service(
            name: "Cabin air filter",
            dueDate: calendar.date(byAdding: .month, value: 3, to: .now),
            dueMileage: vehicle.currentMileage + 7000,
            lastPerformed: calendar.date(byAdding: .month, value: -9, to: .now),
            lastMileage: vehicle.currentMileage - 5000,
            intervalMonths: 12,
            intervalMiles: 12000
        )
        cabinAirFilter.vehicle = vehicle

        // good (long interval)
        let transmissionFluid = Service(
            name: "Transmission fluid",
            dueDate: calendar.date(byAdding: .month, value: 12, to: .now),
            dueMileage: vehicle.currentMileage + 20000,
            lastPerformed: calendar.date(byAdding: .month, value: -2, to: .now),
            lastMileage: vehicle.currentMileage - 1500,
            intervalMonths: 24,
            intervalMiles: 30000
        )
        transmissionFluid.vehicle = vehicle

        // dueSoon (date-only, no mileage)
        let batteryCheck = Service(
            name: "Battery check",
            dueDate: calendar.date(byAdding: .day, value: 18, to: .now),
            lastPerformed: calendar.date(byAdding: .month, value: -6, to: .now),
            intervalMonths: 6
        )
        batteryCheck.vehicle = vehicle

        // neutral (no due date or mileage)
        let wiperBlades = Service(
            name: "Wiper blades",
            lastPerformed: calendar.date(byAdding: .month, value: -14, to: .now)
        )
        wiperBlades.vehicle = vehicle

        return [oilChange, tireRotation, brakeInspection, airFilter,
                cabinAirFilter, transmissionFluid, batteryCheck, wiperBlades]
    }

    /// Compact set of 3 services for a secondary vehicle (MX-5)
    static func sampleServicesCompact(for vehicle: Vehicle) -> [Service] {
        let calendar = Calendar.current

        // good
        let oilChange = Service(
            name: "Oil change",
            dueDate: calendar.date(byAdding: .day, value: 60, to: .now),
            dueMileage: vehicle.currentMileage + 2000,
            lastPerformed: calendar.date(byAdding: .month, value: -4, to: .now),
            lastMileage: vehicle.currentMileage - 2200,
            intervalMonths: 6,
            intervalMiles: 5000
        )
        oilChange.vehicle = vehicle

        // dueSoon
        let tireRotation = Service(
            name: "Tire rotation",
            dueDate: calendar.date(byAdding: .day, value: 15, to: .now),
            dueMileage: vehicle.currentMileage + 500,
            lastPerformed: calendar.date(byAdding: .month, value: -5, to: .now),
            lastMileage: vehicle.currentMileage - 2500,
            intervalMonths: 6,
            intervalMiles: 5000
        )
        tireRotation.vehicle = vehicle

        // good (long interval)
        let brakeInspection = Service(
            name: "Brake inspection",
            dueDate: calendar.date(byAdding: .month, value: 8, to: .now),
            dueMileage: vehicle.currentMileage + 6000,
            lastPerformed: calendar.date(byAdding: .month, value: -4, to: .now),
            lastMileage: vehicle.currentMileage - 3000,
            intervalMonths: 12,
            intervalMiles: 12000
        )
        brakeInspection.vehicle = vehicle

        return [oilChange, tireRotation, brakeInspection]
    }
}
