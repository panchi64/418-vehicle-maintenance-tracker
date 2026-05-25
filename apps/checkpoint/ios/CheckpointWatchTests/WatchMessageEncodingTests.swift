//
//  WatchMessageEncodingTests.swift
//  CheckpointWatchTests
//
//  Tests for encoding/decoding of Watch ↔ iPhone messages
//

import Foundation
import Testing
@testable import CheckpointWatch_Watch_App

struct WatchMessageEncodingTests {

    // MARK: - WatchMarkServiceDone

    @Test func markServiceDone_encodesWithServiceID() throws {
        // Given
        let original = WatchMarkServiceDone(
            vehicleID: "vehicle-abc",
            serviceID: "service-123",
            serviceName: "Oil Change",
            mileageAtService: 45000,
            performedDate: Date(timeIntervalSince1970: 1700000000)
        )

        // When: round-trip encode/decode
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WatchMarkServiceDone.self, from: data)

        // Then
        #expect(decoded.vehicleID == "vehicle-abc")
        #expect(decoded.serviceID == "service-123")
        #expect(decoded.serviceName == "Oil Change")
        #expect(decoded.mileageAtService == 45000)
        #expect(decoded.performedDate == Date(timeIntervalSince1970: 1700000000))
    }

    @Test func markServiceDone_decodesWithoutServiceID() throws {
        // Given: JSON from older format that has no serviceID field
        let json = """
        {"vehicleID":"v1","serviceName":"Tire Rotation","mileageAtService":32000,"performedDate":0}
        """
        let data = json.data(using: .utf8)!

        // When
        let decoded = try JSONDecoder().decode(WatchMarkServiceDone.self, from: data)

        // Then: serviceID should be nil for backward compatibility
        #expect(decoded.vehicleID == "v1")
        #expect(decoded.serviceID == nil)
        #expect(decoded.serviceName == "Tire Rotation")
        #expect(decoded.mileageAtService == 32000)
    }

    // MARK: - WatchService Identifiable

    @Test func watchService_usesServiceIDForIdentifiable() {
        // Given: Service with a serviceID
        let service = WatchService(
            vehicleID: "v1",
            serviceID: "uuid-456",
            name: "Brake Inspection",
            status: .dueSoon,
            dueDescription: "Due in 7 days",
            dueMileage: 55000,
            daysRemaining: 7
        )

        // Then: id should use serviceID
        #expect(service.id == "uuid-456")
    }

    @Test func watchService_fallsBackToCompositeID_whenServiceIDNil() {
        // Given: Service without a serviceID
        let service = WatchService(
            vehicleID: "v1",
            serviceID: nil,
            name: "Brake Inspection",
            status: .dueSoon,
            dueDescription: "Due in 7 days",
            dueMileage: 55000,
            daysRemaining: 7
        )

        // Then: id should fall back to composite
        #expect(service.id == "v1_Brake Inspection")
    }

    // MARK: - WatchMileageUpdate

    @Test func mileageUpdate_roundTrip() throws {
        // Given
        let original = WatchMileageUpdate(
            vehicleID: "vehicle-xyz",
            newMileage: 67890,
            timestamp: Date(timeIntervalSince1970: 1700000000)
        )

        // When: round-trip encode/decode
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WatchMileageUpdate.self, from: data)

        // Then
        #expect(decoded.vehicleID == "vehicle-xyz")
        #expect(decoded.newMileage == 67890)
        #expect(decoded.timestamp == Date(timeIntervalSince1970: 1700000000))
    }

    @Test func mileageUpdate_messageKeyIsCorrect() {
        #expect(WatchMileageUpdate.messageKey == "updateMileage")
    }

    @Test func markServiceDone_messageKeyIsCorrect() {
        #expect(WatchMarkServiceDone.messageKey == "markServiceDone")
    }
}
