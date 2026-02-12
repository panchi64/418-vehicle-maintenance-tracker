//
//  WatchServiceDataTests.swift
//  CheckpointWatch Watch AppTests
//
//  Tests for Watch Codable data types — encode/decode round-trip verification
//

import Foundation
import Testing
@testable import CheckpointWatch_Watch_App

struct WatchServiceDataTests {

    // MARK: - WatchVehicleData

    @Test func vehicleDataEncodesAndDecodes() throws {
        let original = WatchVehicleData(
            vehicleID: "test-123",
            vehicleName: "My Car",
            currentMileage: 45000,
            estimatedMileage: 45200,
            isEstimated: true,
            services: [
                WatchService(
                    vehicleID: "test-123",
                    serviceID: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890",
                    name: "Oil Change",
                    status: .dueSoon,
                    dueDescription: "Due in 5 days",
                    dueMileage: 50000,
                    daysRemaining: 5
                )
            ],
            updatedAt: Date()
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WatchVehicleData.self, from: data)

        #expect(decoded.vehicleID == "test-123")
        #expect(decoded.vehicleName == "My Car")
        #expect(decoded.currentMileage == 45000)
        #expect(decoded.estimatedMileage == 45200)
        #expect(decoded.isEstimated == true)
        #expect(decoded.services.count == 1)
        #expect(decoded.services.first?.serviceID == "A1B2C3D4-E5F6-7890-ABCD-EF1234567890")
        #expect(decoded.services.first?.name == "Oil Change")
        #expect(decoded.services.first?.status == .dueSoon)
    }

    @Test func vehicleDataWithNilOptionals() throws {
        let original = WatchVehicleData(
            vehicleID: "test-456",
            vehicleName: "Truck",
            currentMileage: 80000,
            estimatedMileage: nil,
            isEstimated: false,
            services: [],
            updatedAt: Date()
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WatchVehicleData.self, from: data)

        #expect(decoded.estimatedMileage == nil)
        #expect(decoded.isEstimated == false)
        #expect(decoded.services.isEmpty)
    }

    @Test func vehicleDataStaleDetection() {
        let fresh = WatchVehicleData(
            vehicleID: "v1",
            vehicleName: "Car",
            currentMileage: 1000,
            estimatedMileage: nil,
            isEstimated: false,
            services: [],
            updatedAt: Date()
        )
        #expect(fresh.isStale == false)

        let stale = WatchVehicleData(
            vehicleID: "v1",
            vehicleName: "Car",
            currentMileage: 1000,
            estimatedMileage: nil,
            isEstimated: false,
            services: [],
            updatedAt: Date().addingTimeInterval(-7200) // 2 hours ago
        )
        #expect(stale.isStale == true)
    }

    // MARK: - WatchService

    @Test func serviceIDUsesUUIDWhenAvailable() {
        let service = WatchService(
            vehicleID: "v1",
            serviceID: "uuid-123",
            name: "Tire Rotation",
            status: .good,
            dueDescription: "Due in 30 days",
            dueMileage: 60000,
            daysRemaining: 30
        )

        #expect(service.id == "uuid-123")
    }

    @Test func serviceIDFallsBackToCompositeWhenNil() {
        let service = WatchService(
            vehicleID: "v1",
            serviceID: nil,
            name: "Tire Rotation",
            status: .good,
            dueDescription: "Due in 30 days",
            dueMileage: 60000,
            daysRemaining: 30
        )

        #expect(service.id == "v1_Tire Rotation")
    }

    @Test func serviceDecodesWithoutServiceID() throws {
        // Simulate old format without serviceID field
        let json = """
        {"vehicleID":"v1","name":"Oil Change","status":"good","dueDescription":"30 days","dueMileage":50000,"daysRemaining":30}
        """
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(WatchService.self, from: data)

        #expect(decoded.serviceID == nil)
        #expect(decoded.name == "Oil Change")
        #expect(decoded.id == "v1_Oil Change")
    }

    @Test func serviceStatusEncodesAllCases() throws {
        let statuses: [WatchServiceStatus] = [.overdue, .dueSoon, .good, .neutral]
        for status in statuses {
            let service = WatchService(
                vehicleID: "v1",
                serviceID: "sid-1",
                name: "Test",
                status: status,
                dueDescription: "test",
                dueMileage: nil,
                daysRemaining: nil
            )
            let data = try JSONEncoder().encode(service)
            let decoded = try JSONDecoder().decode(WatchService.self, from: data)
            #expect(decoded.status == status)
        }
    }

    // MARK: - WatchMileageUpdate

    @Test func mileageUpdateEncodesAndDecodes() throws {
        let original = WatchMileageUpdate(
            vehicleID: "v1",
            newMileage: 50000,
            timestamp: Date()
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WatchMileageUpdate.self, from: data)

        #expect(decoded.vehicleID == "v1")
        #expect(decoded.newMileage == 50000)
    }

    // MARK: - WatchMarkServiceDone

    @Test func markServiceDoneEncodesAndDecodes() throws {
        let original = WatchMarkServiceDone(
            vehicleID: "v1",
            serviceID: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890",
            serviceName: "Oil Change",
            mileageAtService: 45000,
            performedDate: Date()
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WatchMarkServiceDone.self, from: data)

        #expect(decoded.vehicleID == "v1")
        #expect(decoded.serviceID == "A1B2C3D4-E5F6-7890-ABCD-EF1234567890")
        #expect(decoded.serviceName == "Oil Change")
        #expect(decoded.mileageAtService == 45000)
    }

    @Test func markServiceDoneDecodesWithoutServiceID() throws {
        // Simulate old message format without serviceID
        let json = """
        {"vehicleID":"v1","serviceName":"Oil Change","mileageAtService":45000,"performedDate":0}
        """
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(WatchMarkServiceDone.self, from: data)

        #expect(decoded.vehicleID == "v1")
        #expect(decoded.serviceID == nil)
        #expect(decoded.serviceName == "Oil Change")
        #expect(decoded.mileageAtService == 45000)
    }

    // MARK: - WatchApplicationContext

    @Test func applicationContextRoundTrip() {
        let vehicleData = WatchVehicleData(
            vehicleID: "v1",
            vehicleName: "Test",
            currentMileage: 10000,
            estimatedMileage: nil,
            isEstimated: false,
            services: [],
            updatedAt: Date()
        )

        let context = WatchApplicationContext(
            vehicleData: vehicleData,
            lastUpdated: Date()
        )

        let dict = context.toDictionary()
        #expect(dict["watchContext"] != nil)

        let decoded = WatchApplicationContext.from(dictionary: dict)
        #expect(decoded != nil)
        #expect(decoded?.vehicleData?.vehicleName == "Test")
        #expect(decoded?.vehicleData?.currentMileage == 10000)
    }

    @Test func applicationContextFromEmptyDictionary() {
        let decoded = WatchApplicationContext.from(dictionary: [:])
        #expect(decoded == nil)
    }
}
