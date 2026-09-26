//
//  SpotlightIndexerTests.swift
//  checkpointTests
//
//  The indexer replaces each entity type wholesale — delete, then index what
//  the store holds — so records deleted in the app leave Spotlight too.
//  Runs against a recording index, never the real one.
//

import XCTest
import SwiftData
import AppIntents
@testable import checkpoint

@MainActor
final class SpotlightIndexerTests: XCTestCase {

    /// Records what the indexer asked for, in order.
    private final class RecordingIndex: AppEntityIndexing {
        enum Call: Equatable {
            case delete(String)
            case index(String, ids: Set<String>)
        }

        var calls: [Call] = []
        var failDeletes = false

        func indexAppEntities<Entity: IndexedEntity>(_ entities: [Entity], priority: Int) async throws {
            calls.append(.index(String(describing: Entity.self), ids: Set(entities.map { "\($0.id)" })))
        }

        func deleteAppEntities<Entity: IndexedEntity>(ofType entityType: Entity.Type) async throws {
            if failDeletes { throw CocoaError(.featureUnsupported) }
            calls.append(.delete(String(describing: entityType)))
        }
    }

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUp() {
        super.setUp()
        modelContainer = .inMemoryForTesting()
        modelContext = modelContainer.mainContext
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        super.tearDown()
    }

    func test_reindex_replacesEveryEntityType() async throws {
        let vehicle = Vehicle(name: "Civic", make: "Honda", model: "Civic", year: 2020, currentMileage: 45_000)
        modelContext.insert(vehicle)
        let service = Service(name: "Oil Change", dueMileage: 50_000)
        service.vehicle = vehicle
        modelContext.insert(service)
        let log = ServiceLog(service: service, vehicle: vehicle, performedDate: .now, mileageAtService: 44_000, cost: 60)
        modelContext.insert(log)
        try modelContext.save()

        let index = RecordingIndex()
        await SpotlightIndexer(index: index).reindex(from: modelContext)

        XCTAssertEqual(index.calls, [
            .delete("VehicleEntity"), .index("VehicleEntity", ids: [vehicle.id.uuidString]),
            .delete("ServiceEntity"), .index("ServiceEntity", ids: [service.id.uuidString]),
            .delete("ServiceLogEntity"), .index("ServiceLogEntity", ids: [log.id.uuidString]),
            // Nothing stored: the type is cleared and nothing is indexed.
            .delete("VisitEntity"),
            .delete("DocumentEntity"),
            .delete("AppointmentEntity"),
            .delete("VehicleNoteEntity"),
        ])
    }

    func test_reindex_afterDelete_dropsTheRecord() async throws {
        let vehicle = Vehicle(name: "Old", make: "Ford", model: "Focus", year: 2010)
        modelContext.insert(vehicle)
        try modelContext.save()
        modelContext.delete(vehicle)
        try modelContext.save()

        let index = RecordingIndex()
        await SpotlightIndexer(index: index).reindex(from: modelContext)

        XCTAssertTrue(index.calls.contains(.delete("VehicleEntity")))
        XCTAssertFalse(index.calls.contains { if case .index("VehicleEntity", _) = $0 { true } else { false } })
    }

    func test_reindex_indexFailure_stopsWithoutCrashing() async {
        let index = RecordingIndex()
        index.failDeletes = true

        await SpotlightIndexer(index: index).reindex(from: modelContext)

        XCTAssertTrue(index.calls.isEmpty)
    }

    func test_scheduleReindex_coalescesBursts() async throws {
        modelContext.insert(Vehicle(name: "Civic", make: "Honda", model: "Civic", year: 2020))
        try modelContext.save()

        let index = RecordingIndex()
        let indexer = SpotlightIndexer(index: index, debounce: .milliseconds(50))
        indexer.scheduleReindex(from: modelContainer)
        indexer.scheduleReindex(from: modelContainer)
        indexer.scheduleReindex(from: modelContainer)
        try await Task.sleep(for: .milliseconds(400))

        XCTAssertEqual(index.calls.filter { $0 == .delete("VehicleEntity") }.count, 1, "Three requests, one pass")
    }
}
