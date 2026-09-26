//
//  VehicleIntentTests.swift
//  checkpointTests
//
//  Add Vehicle (spoken fields, VIN lookup through a stubbed NHTSA client,
//  the free limit, the starter schedule), Switch Vehicle, Get Vehicle
//  Details, and the marbete renewal. Recalls are in RecallIntentTests.
//

import AppIntents
import XCTest
import SwiftData
@testable import checkpoint

/// NHTSA without the network. Each answer is fixed per test.
struct StubNHTSA: NHTSAClient {
    var decoded: Result<VINDecodeResult, NHTSAError> = .failure(.networkUnavailable)
    var recalls: Result<[RecallInfo], NHTSAError> = .success([])

    func decodeVIN(_ vin: String) async throws -> VINDecodeResult { try decoded.get() }
    func fetchRecalls(make: String, model: String, year: Int) async throws -> [RecallInfo] { try recalls.get() }

    static func decoding(make: String, model: String, year: Int?) -> StubNHTSA {
        StubNHTSA(decoded: .success(VINDecodeResult(
            make: make, model: model, modelYear: year,
            engineDescription: "", driveType: "", bodyClass: "", fuelType: "", errorCode: "0"
        )))
    }
}

extension GetVehicleDetailsIntent: StoreBackedIntent {}
extension RenewMarbeteIntent: StoreBackedIntent {}
extension SwitchVehicleIntent: StoreBackedIntent {}

final class VehicleIntentTests: IntentTestCase {

    private let vin = "1HGCM82633A004352"

    // MARK: - VehicleService.fillingFromVIN

    func test_fillingFromVIN_fillsOnlyWhatWasLeftEmpty() async throws {
        var fields = VehicleFields()
        fields.vin = " \(vin.lowercased()) "
        fields.make = "Honda"

        let filled = try await VehicleService.fillingFromVIN(fields, using: StubNHTSA.decoding(make: "HONDA", model: "Accord", year: 2003))

        XCTAssertEqual(filled.make, "Honda", "What was said wins")
        XCTAssertEqual(filled.model, "Accord")
        XCTAssertEqual(filled.year, 2003)
        XCTAssertEqual(filled.vin, vin, "Stored trimmed and uppercased")
    }

    func test_fillingFromVIN_withoutVINOrGaps_looksNothingUp() async throws {
        // A failing client proves no lookup happened.
        let noVIN = try await VehicleService.fillingFromVIN(VehicleFields(), using: StubNHTSA())
        XCTAssertEqual(noVIN, VehicleFields())

        var complete = VehicleFields()
        complete.vin = vin
        complete.make = "Honda"
        complete.model = "Accord"
        complete.year = 2003
        let unchanged = try await VehicleService.fillingFromVIN(complete, using: StubNHTSA())
        XCTAssertEqual(unchanged, complete)
    }

    func test_fillingFromVIN_propagatesLookupFailure() async {
        var fields = VehicleFields()
        fields.vin = vin
        do {
            _ = try await VehicleService.fillingFromVIN(fields, using: StubNHTSA())
            XCTFail("Expected the lookup's error")
        } catch {
            XCTAssertEqual(error as? NHTSAError, .networkUnavailable)
        }
    }

    // MARK: - Add Vehicle

    func test_identify_decodesTheVIN() async {
        let spoken = AddVehicleIntent.spokenFields(make: nil, model: nil, year: nil, vin: "1HGCM 82633A004352", name: " Weekend ")
        let result = await AddVehicleIntent.identify(spoken, using: StubNHTSA.decoding(make: "HONDA", model: "Accord", year: 2003))

        XCTAssertFalse(result.vinFailed)
        XCTAssertEqual(result.fields.make, "HONDA")
        XCTAssertEqual(result.fields.model, "Accord")
        XCTAssertEqual(result.fields.year, 2003)
        XCTAssertEqual(result.fields.vin, vin, "Spaces from dictation are dropped")
        XCTAssertEqual(result.fields.name, "Weekend")
    }

    func test_identify_invalidVIN_isDroppedAndReported() async {
        let spoken = AddVehicleIntent.spokenFields(make: "Honda", model: nil, year: nil, vin: "NOT-A-VIN", name: nil)
        let result = await AddVehicleIntent.identify(spoken, using: StubNHTSA.decoding(make: "X", model: "Y", year: 2000))

        XCTAssertTrue(result.vinFailed)
        XCTAssertEqual(result.fields.vin, "")
        XCTAssertEqual(result.fields.make, "Honda")
        XCTAssertEqual(result.fields.model, "", "Left for Siri to ask")
    }

    func test_identify_failedLookup_keepsTheValidVIN() async {
        let spoken = AddVehicleIntent.spokenFields(make: nil, model: nil, year: nil, vin: vin, name: nil)
        let result = await AddVehicleIntent.identify(spoken, using: StubNHTSA())

        XCTAssertTrue(result.vinFailed)
        XCTAssertEqual(result.fields.vin, vin)
        XCTAssertEqual(result.fields.make, "")
    }

    func test_spokenFields_dropsAnImplausibleYear() {
        XCTAssertNil(AddVehicleIntent.spokenFields(make: nil, model: nil, year: 1492, vin: nil, name: nil).year)
        XCTAssertEqual(AddVehicleIntent.spokenFields(make: nil, model: nil, year: 2021, vin: nil, name: nil).year, 2021)
    }

    func test_add_withSchedule_savesTheVehicleAndTheStarterServices() throws {
        var fields = VehicleFields()
        fields.make = "Toyota"
        fields.model = "Corolla"
        fields.currentMileage = 30_000

        let added = try AddVehicleIntent.add(fields, withSchedule: true, in: context, isPro: false)

        XCTAssertEqual(added.make, "Toyota")
        XCTAssertEqual(added.currentMileage, 30_000)
        let names = Set((added.services ?? []).map(\.name))
        XCTAssertTrue(names.contains("Oil Change"))
        XCTAssertEqual(names.count, StarterScheduleWriter.offeredItems(for: Vehicle(name: "", make: "", model: "", year: 0)).count)
        XCTAssertTrue((added.services ?? []).allSatisfy { $0.isRecurring && $0.hasDueTracking })
        XCTAssertFalse(context.hasChanges, "Committed")
    }

    func test_add_withoutSchedule_addsNoServices() throws {
        var fields = VehicleFields()
        fields.make = "Toyota"
        fields.model = "Corolla"

        let added = try AddVehicleIntent.add(fields, withSchedule: false, in: context, isPro: false)

        XCTAssertEqual(added.services ?? [], [])
    }

    func test_add_pastTheFreeLimit_needsPro() throws {
        for index in 1..<VehicleService.freeVehicleLimit {
            context.insert(Vehicle(name: "Car \(index)", make: "", model: "", year: 0))
        }
        try context.save()
        var fields = VehicleFields()
        fields.make = "Mazda"
        fields.model = "3"

        XCTAssertThrowsError(try AddVehicleIntent.add(fields, withSchedule: false, in: context, isPro: false)) {
            XCTAssertEqual($0 as? IntentError, .vehicleLimitReached)
        }
        XCTAssertNoThrow(try AddVehicleIntent.add(fields, withSchedule: false, in: context, isPro: true))
    }

    func test_label_isTheNicknameElseTheIdentity() {
        var fields = VehicleFields()
        fields.make = "Honda"
        fields.model = "Civic"
        fields.year = 2020
        XCTAssertEqual(AddVehicleIntent.label(for: fields), "2020 Honda Civic")
        fields.name = "Daily"
        XCTAssertEqual(AddVehicleIntent.label(for: fields), "Daily")
    }

    // MARK: - Switch Vehicle

    func test_switchVehicle_routesToItsHome() async throws {
        _ = PendingRouteStore.shared.take()
        let intent = wired(SwitchVehicleIntent(vehicle: VehicleEntity(model: vehicle)))

        _ = try await intent.perform()

        XCTAssertEqual(PendingRouteStore.shared.take(), .vehicle(vehicleID: vehicle.id))
    }

    // MARK: - Get Vehicle Details

    func test_details_answerWhatIsOnFile_andSayWhatIsNot() async throws {
        vehicle.oilType = "0W-20"
        vehicle.licensePlate = "ABC-123"
        try context.save()

        let oil = try await wired(GetVehicleDetailsIntent(detail: .oilType)).perform()
        XCTAssertEqual(oil.value, "0W-20")

        let tires = GetVehicleDetailsIntent.answer(.tireSize, for: vehicle)
        XCTAssertEqual(tires.value, "")
        XCTAssertEqual(tires.sentence, L10n.siriDetailMissing(.tireSize, vehicle: vehicle.displayName))

        let everything = GetVehicleDetailsIntent.answer(nil, for: vehicle)
        XCTAssertTrue(everything.value.contains("0W-20"))
        XCTAssertTrue(everything.value.contains("ABC-123"))
    }

    func test_details_marbete_saysWhenItExpired() {
        vehicle.marbeteExpirationMonth = 1
        vehicle.marbeteExpirationYear = 2020

        let answer = GetVehicleDetailsIntent.answer(.marbete, for: vehicle)

        XCTAssertEqual(answer.sentence, L10n.siriMarbeteExpired(vehicle: vehicle.displayName, month: answer.value))
    }

    // MARK: - Renew Marbete

    func test_renewal_movesToTheSameMonthNextYear() throws {
        let now = Calendar.current.date(from: DateComponents(year: 2026, month: 9, day: 1))!
        vehicle.marbeteExpirationMonth = 10
        vehicle.marbeteExpirationYear = 2026

        let renewed = try RenewMarbeteIntent.renewal(for: vehicle, now: now)
        try RenewMarbeteIntent.renew(vehicle, to: renewed, in: context)

        XCTAssertEqual(vehicle.marbeteExpirationMonth, 10)
        XCTAssertEqual(vehicle.marbeteExpirationYear, 2027)
        XCTAssertFalse(context.hasChanges)
    }

    func test_renewal_withoutAMarbete_throws() {
        XCTAssertThrowsError(try RenewMarbeteIntent.renewal(for: vehicle)) {
            XCTAssertEqual($0 as? IntentError, .noMarbete)
        }
    }

    func test_renewMarbete_asksBeforeWriting() async {
        vehicle.marbeteExpirationMonth = 10
        vehicle.marbeteExpirationYear = 2026
        let intent = wired(RenewMarbeteIntent())

        await runUnanswered { _ = try await intent.perform() }

        XCTAssertEqual(vehicle.marbeteExpirationYear, 2026, "Nothing written before a yes")
    }
}
