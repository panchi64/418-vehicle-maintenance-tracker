//
//  CheckpointMigrationTests.swift
//  checkpointTests
//
//  V1 → V2 on disk. `Fixtures/CheckpointV1.store` is a real store written by
//  the shipped V1 app on a Simulator (two sample vehicles with notes, one
//  without; 24 services, 32 logs), so opening it proves the frozen
//  `CheckpointSchemaV1` still matches what users have on disk — not just
//  that V1 and V2 agree with each other.
//

import XCTest
import SwiftData
@testable import checkpoint

@MainActor
final class CheckpointMigrationTests: XCTestCase {

    private var directory: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("CheckpointMigrationTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
        directory = nil
        try super.tearDownWithError()
    }

    /// Open `url` the way the app does (versioned schema + plan), CloudKit off.
    private func openCurrent(at url: URL) throws -> ModelContainer {
        let schema = Schema(versionedSchema: CheckpointSchemaCurrent.self)
        return try ModelContainer(
            for: schema,
            migrationPlan: CheckpointMigrationPlan.self,
            configurations: ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
        )
    }

    private func fixtureCopy() throws -> URL {
        let fixture = try XCTUnwrap(
            Bundle(for: Self.self).url(forResource: "CheckpointV1", withExtension: "store"),
            "The V1 fixture store is missing from the test bundle"
        )
        let url = directory.appendingPathComponent("checkpoint.store")
        try FileManager.default.copyItem(at: fixture, to: url)
        return url
    }

    // MARK: - The shipped V1 store

    func test_shippedV1Store_opensAndKeepsEverything() throws {
        let container = try openCurrent(at: fixtureCopy())
        let context = container.mainContext

        let vehicles = try context.fetch(FetchDescriptor<Vehicle>())
        XCTAssertEqual(vehicles.count, 3)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Service>()), 24)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<ServiceLog>()), 32)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Appointment>()), 0)
    }

    func test_shippedV1Store_eachNotesFieldBecomesOnePinnedNote() throws {
        let container = try openCurrent(at: fixtureCopy())
        let context = container.mainContext
        let vehicles = try context.fetch(FetchDescriptor<Vehicle>())

        let camry = try XCTUnwrap(vehicles.first { $0.name == "Daily Driver" })
        let notes = camry.vehicleNotes ?? []
        XCTAssertEqual(notes.count, 1)
        let note = try XCTUnwrap(notes.first)
        XCTAssertTrue(note.isPinned)
        XCTAssertEqual(note.body, "Purchased certified pre-owned. Runs great!")
        XCTAssertEqual(note.id, VehicleNoteMigration.legacyNoteID(for: camry.id))
        XCTAssertEqual(camry.notes, "Purchased certified pre-owned. Runs great!", "The field stays for older app versions")

        let civic = try XCTUnwrap(vehicles.first { $0.model == "Civic" })
        XCTAssertTrue((civic.vehicleNotes ?? []).isEmpty, "No notes, no note")

        XCTAssertEqual(try context.fetchCount(FetchDescriptor<VehicleNote>()), 2)
    }

    func test_shippedV1Store_reopening_doesNotMigrateTwice() throws {
        let url = try fixtureCopy()
        _ = try openCurrent(at: url)
        let container = try openCurrent(at: url)
        try VehicleNoteMigration.reconcile(in: container.mainContext)
        XCTAssertEqual(try container.mainContext.fetchCount(FetchDescriptor<VehicleNote>()), 2)
    }

    // MARK: - A V1 store written by the frozen schema

    func test_frozenV1Store_migratesToV2() throws {
        let url = directory.appendingPathComponent("frozen.store")
        let v1Schema = Schema(versionedSchema: CheckpointSchemaV1.self)
        let vehicleID: UUID
        do {
            let v1 = try ModelContainer(
                for: v1Schema,
                configurations: ModelConfiguration(schema: v1Schema, url: url, cloudKitDatabase: .none)
            )
            let vehicle = CheckpointSchemaV1.Vehicle(name: "Old", make: "Ford", model: "Ranger", year: 2004, notes: "Line one\nLine two")
            v1.mainContext.insert(vehicle)
            try v1.mainContext.save()
            vehicleID = vehicle.id
        }

        let container = try openCurrent(at: url)
        let vehicle = try XCTUnwrap(try container.mainContext.fetch(FetchDescriptor<Vehicle>()).first)
        XCTAssertEqual(vehicle.id, vehicleID)
        let note = try XCTUnwrap(vehicle.vehicleNotes?.first)
        XCTAssertEqual(note.displayTitle, "Line one")
        XCTAssertEqual(note.previewLine, "Line two")
        XCTAssertTrue((vehicle.appointments ?? []).isEmpty)
    }

    // MARK: - The V2 plan

    func test_plan_listsBothVersionsAndOneStage() {
        XCTAssertEqual(CheckpointMigrationPlan.schemas.count, 2)
        XCTAssertEqual(CheckpointMigrationPlan.stages.count, 1)
        XCTAssertEqual(CheckpointSchemaV2.versionIdentifier, Schema.Version(2, 0, 0))
        let names = Set(CheckpointSchemaV2.models.map { String(describing: $0) })
        XCTAssertTrue(names.isSuperset(of: ["Appointment", "VehicleNote"]))
    }
}
