//
//  ConflictResolutionViewTests.swift
//  checkpointTests
//
//  Tests for ConflictResolutionView and SyncConflict
//

import XCTest
import SwiftUI
@testable import checkpoint

final class ConflictResolutionViewTests: XCTestCase {

    // MARK: - SyncConflict Tests

    func testSyncConflictHasUniqueId() {
        // Given two conflicts with same data
        let conflict1 = SyncConflict(
            entityType: .vehicle,
            entityName: "Test Car",
            localValue: "50,000",
            remoteValue: "51,000",
            localModifiedAt: Date(),
            remoteModifiedAt: Date(),
            fieldName: "Mileage"
        )

        let conflict2 = SyncConflict(
            entityType: .vehicle,
            entityName: "Test Car",
            localValue: "50,000",
            remoteValue: "51,000",
            localModifiedAt: Date(),
            remoteModifiedAt: Date(),
            fieldName: "Mileage"
        )

        // Then they should have different IDs (for Identifiable)
        XCTAssertNotEqual(conflict1.id, conflict2.id)
    }

    func testSyncConflictEntityTypeRawValues() {
        // Verify all entity types have correct raw values
        XCTAssertEqual(SyncConflict.EntityType.vehicle.rawValue, "Vehicle")
        XCTAssertEqual(SyncConflict.EntityType.service.rawValue, "Service")
        XCTAssertEqual(SyncConflict.EntityType.serviceLog.rawValue, "Service Log")
        XCTAssertEqual(SyncConflict.EntityType.mileageSnapshot.rawValue, "Mileage")
    }

    func testSyncConflictStoresAllProperties() {
        // Given specific values
        let localDate = Date()
        let remoteDate = Date().addingTimeInterval(-3600)

        // When creating a conflict
        let conflict = SyncConflict(
            entityType: .service,
            entityName: "Oil Change",
            localValue: "55,000 miles",
            remoteValue: "54,500 miles",
            localModifiedAt: localDate,
            remoteModifiedAt: remoteDate,
            fieldName: "Due Mileage"
        )

        // Then all properties should be stored correctly
        XCTAssertEqual(conflict.entityType, .service)
        XCTAssertEqual(conflict.entityName, "Oil Change")
        XCTAssertEqual(conflict.localValue, "55,000 miles")
        XCTAssertEqual(conflict.remoteValue, "54,500 miles")
        XCTAssertEqual(conflict.localModifiedAt, localDate)
        XCTAssertEqual(conflict.remoteModifiedAt, remoteDate)
        XCTAssertEqual(conflict.fieldName, "Due Mileage")
    }

    // MARK: - ConflictResolution Tests

    func testConflictResolutionCases() {
        // Verify all resolution options exist
        let keepLocal = ConflictResolutionView.ConflictResolution.keepLocal
        let keepRemote = ConflictResolutionView.ConflictResolution.keepRemote
        let keepBoth = ConflictResolutionView.ConflictResolution.keepBoth

        // These should be distinct cases
        XCTAssertNotEqual(
            String(describing: keepLocal),
            String(describing: keepRemote)
        )
        XCTAssertNotEqual(
            String(describing: keepRemote),
            String(describing: keepBoth)
        )
    }

    // MARK: - View Instantiation Tests

    func testConflictResolutionViewCanBeCreated() {
        // Given a conflict and handler
        let conflict = SyncConflict(
            entityType: .vehicle,
            entityName: "Test Car",
            localValue: "50,000",
            remoteValue: "51,000",
            localModifiedAt: Date(),
            remoteModifiedAt: Date(),
            fieldName: "Mileage"
        )

        var resolvedWith: ConflictResolutionView.ConflictResolution?

        // When creating the view
        let view = ConflictResolutionView(conflict: conflict) { resolution in
            resolvedWith = resolution
        }

        // Then the view should be created without crashing
        XCTAssertNotNil(view)
        XCTAssertNil(resolvedWith) // Not resolved yet
    }

    func testConflictListViewCanBeCreated() {
        // Given conflicts and handler
        let conflicts = [
            SyncConflict(
                entityType: .vehicle,
                entityName: "Car 1",
                localValue: "Value 1",
                remoteValue: "Value 2",
                localModifiedAt: Date(),
                remoteModifiedAt: Date(),
                fieldName: "Field"
            ),
            SyncConflict(
                entityType: .service,
                entityName: "Service 1",
                localValue: "Value A",
                remoteValue: "Value B",
                localModifiedAt: Date(),
                remoteModifiedAt: Date(),
                fieldName: "Field"
            )
        ]

        // When creating the view
        let view = ConflictListView(conflicts: conflicts) { _, _ in }

        // Then the view should be created without crashing
        XCTAssertNotNil(view)
    }

    func testConflictListViewWithEmptyConflicts() {
        // Given empty conflicts
        let conflicts: [SyncConflict] = []

        // When creating the view
        let view = ConflictListView(conflicts: conflicts) { _, _ in }

        // Then the view should be created without crashing
        XCTAssertNotNil(view)
    }

    // MARK: - Entity Type Coverage Tests

    func testAllEntityTypesCanCreateConflicts() {
        // Test that conflicts can be created for all entity types
        let entityTypes: [SyncConflict.EntityType] = [
            .vehicle,
            .service,
            .serviceLog,
            .mileageSnapshot
        ]

        for entityType in entityTypes {
            let conflict = SyncConflict(
                entityType: entityType,
                entityName: "Test \(entityType.rawValue)",
                localValue: "Local",
                remoteValue: "Remote",
                localModifiedAt: Date(),
                remoteModifiedAt: Date(),
                fieldName: "Test Field"
            )

            XCTAssertEqual(conflict.entityType, entityType)
            XCTAssertEqual(conflict.entityName, "Test \(entityType.rawValue)")
        }
    }
}
