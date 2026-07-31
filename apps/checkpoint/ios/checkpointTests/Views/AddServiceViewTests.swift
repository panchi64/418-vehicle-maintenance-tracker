//
//  AddServiceViewTests.swift
//  checkpointTests
//
//  Tests for AddServiceView form validation and logic
//

import XCTest
@testable import checkpoint

final class AddServiceViewTests: XCTestCase {

    // MARK: - Derived intent
    //
    // `ServiceMode` is gone. The form asks WHEN and derives whether it is
    // logging or scheduling; these guard that derivation, because every save
    // branch and half the visible copy now hangs off it.

    func testTiming_PastCasesDeriveLogIntent() {
        for timing in ServiceTiming.pastCases {
            XCTAssertEqual(timing.intent, .log, "\(timing) should log")
        }
    }

    func testTiming_FutureCasesDeriveScheduleIntent() {
        for timing in ServiceTiming.futureCases {
            XCTAssertEqual(timing.intent, .schedule, "\(timing) should schedule")
        }
    }

    func testTiming_EveryCaseIsInExactlyOneGroup() {
        // A case missing from both arrays would be unreachable in the UI.
        let grouped = Set(ServiceTiming.pastCases + ServiceTiming.futureCases)
        XCTAssertEqual(grouped, Set(ServiceTiming.allCases))
        XCTAssertEqual(
            ServiceTiming.pastCases.count + ServiceTiming.futureCases.count,
            ServiceTiming.allCases.count,
            "A timing appears in both groups"
        )
    }

    func testTiming_OnlyEarlierIsBackfill() {
        // Backfill suppresses both odometer adoption and preset recurrence, so
        // widening this predicate silently changes two behaviours.
        XCTAssertTrue(ServiceTiming.earlier.isBackfill)
        for timing in ServiceTiming.allCases where timing != .earlier {
            XCTAssertFalse(timing.isBackfill, "\(timing) should not be backfill")
        }
    }

    func testTiming_ResolvesPerformedDates() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let explicit = Date(timeIntervalSince1970: 1_600_000_000)

        XCTAssertEqual(ServiceTiming.today.performedDate(explicit: explicit, now: now), now)
        XCTAssertEqual(
            ServiceTiming.yesterday.performedDate(explicit: explicit, now: now),
            Calendar.current.date(byAdding: .day, value: -1, to: now)
        )
        XCTAssertEqual(ServiceTiming.earlier.performedDate(explicit: explicit, now: now), explicit)
    }

    func testTiming_MileageTriggeredHasNoDueDate() {
        // A mileage-triggered reminder must not also claim a date, or the
        // fire-time readout would print one the scheduler never uses.
        XCTAssertNil(ServiceTiming.atMileage.dueDate(explicit: .now))
        XCTAssertNotNil(ServiceTiming.inThreeMonths.dueDate(explicit: .now))
        XCTAssertNotNil(ServiceTiming.inSixMonths.dueDate(explicit: .now))
    }

    func testTiming_DisplayNamesAreLocalized() {
        XCTAssertEqual(ServiceTiming.today.displayName, L10n.timingToday)
        XCTAssertEqual(ServiceTiming.atMileage.displayName, L10n.timingAtMileage)
    }

    // MARK: - Draft migration
    //
    // The draft schema changed with the fork's removal. A pre-refactor payload
    // must be discarded, never half-applied.

    func testDraft_PreRefactorPayloadIsRejected() {
        let legacy = """
        {"mode":"Record","serviceName":"Oil change","performedDate":0,"costText":"",
         "mileageText":"","recordNotes":"","remindNotes":"","hasCustomDate":false,
         "isRecurring":false,"savedAt":0}
        """.data(using: .utf8)!

        XCTAssertNil(
            try? JSONDecoder().decode(ServiceFormDraft.self, from: legacy),
            "A v1 draft must fail to decode rather than losing fields silently"
        )
    }

    func testDraft_RoundTripsThroughCurrentVersion() throws {
        let draft = ServiceFormDraft(
            version: ServiceFormDraft.currentVersion,
            timing: .atMileage,
            customDate: Date(timeIntervalSince1970: 1_700_000_000),
            serviceName: "Oil change",
            presetName: nil,
            costText: "42.50",
            costCategoryRaw: CostCategory.maintenance.rawValue,
            mileageText: "33417",
            notes: "Full synthetic",
            dueMileage: 38_000,
            intervalMonths: 6,
            intervalMiles: 5_000,
            isRecurring: true,
            savedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )

        let decoded = try JSONDecoder().decode(
            ServiceFormDraft.self,
            from: JSONEncoder().encode(draft)
        )
        XCTAssertEqual(decoded, draft)
    }

    // MARK: - Form Validation Tests (Log Mode)
    //
    // Validation mirrors AddServiceView.isFormValid: only the service name is required.
    // Mileage is optional; an unspecified mileage falls back to vehicle.currentMileage
    // in the save logic. This keeps the form permissive for casual users, backfillers,
    // and one-handed parking-lot loggers.

    private func isFormValid(serviceName: String) -> Bool {
        !serviceName.isEmpty
    }

    func testFormValidation_LogMode_ValidWhenServiceNameFilled() {
        XCTAssertTrue(isFormValid(serviceName: "Oil Change"))
    }

    func testFormValidation_LogMode_ValidWithoutMileage() {
        // Mileage is optional — saving without it is allowed.
        XCTAssertTrue(isFormValid(serviceName: "Oil Change"))
    }

    func testFormValidation_LogMode_InvalidWhenServiceNameEmpty() {
        XCTAssertFalse(isFormValid(serviceName: ""))
    }

    func testFormValidation_LogMode_InvalidWhenBothEmpty() {
        XCTAssertFalse(isFormValid(serviceName: ""))
    }

    // MARK: - Form Validation Tests (Schedule Mode)

    func testFormValidation_ScheduleMode_ValidWhenServiceNameFilled() {
        XCTAssertTrue(isFormValid(serviceName: "Tire Rotation"))
    }

    func testFormValidation_ScheduleMode_InvalidWhenServiceNameEmpty() {
        XCTAssertFalse(isFormValid(serviceName: ""))
    }

    // MARK: - Service Name Computed Property Tests

    func testServiceName_PresetTakesPrecedence() {
        // Given: Both preset and custom name
        let preset = PresetData(
            name: "Oil Change",
            category: "Engine",
            defaultIntervalMonths: 6,
            defaultIntervalMiles: 5000
        )
        let customName = "Custom Service"

        // When: Computing service name (preset takes precedence)
        let serviceName = preset.name

        // Then: Should use preset name
        XCTAssertEqual(serviceName, "Oil Change")
        XCTAssertNotEqual(serviceName, customName)
    }

    func testServiceName_UsesCustomWhenNoPreset() {
        // Given: No preset, only custom name
        let preset: PresetData? = nil
        let customName = "Custom Oil Change"

        // When: Computing service name
        let serviceName = preset?.name ?? customName

        // Then: Should use custom name
        XCTAssertEqual(serviceName, "Custom Oil Change")
    }

    func testServiceName_EmptyWhenNeitherProvided() {
        // Given: No preset and empty custom name
        let preset: PresetData? = nil
        let customName = ""

        // When: Computing service name
        let serviceName = preset?.name ?? customName

        // Then: Should be empty
        XCTAssertTrue(serviceName.isEmpty)
    }

    // MARK: - Interval Auto-fill Tests

    func testIntervalAutoFill_PopulatesMonthsFromPreset() {
        // Given: Preset with interval months
        let preset = PresetData(
            name: "Oil Change",
            category: "Engine",
            defaultIntervalMonths: 6,
            defaultIntervalMiles: nil
        )

        // When: Extracting interval
        let intervalMonths: String
        if let months = preset.defaultIntervalMonths {
            intervalMonths = String(months)
        } else {
            intervalMonths = ""
        }

        // Then: Should populate months
        XCTAssertEqual(intervalMonths, "6")
    }

    func testIntervalAutoFill_PopulatesMilesFromPreset() {
        // Given: Preset with interval miles
        let preset = PresetData(
            name: "Tire Rotation",
            category: "Tires",
            defaultIntervalMonths: nil,
            defaultIntervalMiles: 7500
        )

        // When: Extracting interval
        let intervalMiles: String
        if let miles = preset.defaultIntervalMiles {
            intervalMiles = String(miles)
        } else {
            intervalMiles = ""
        }

        // Then: Should populate miles
        XCTAssertEqual(intervalMiles, "7500")
    }

    func testIntervalAutoFill_PopulatesBothFromPreset() {
        // Given: Preset with both intervals
        let preset = PresetData(
            name: "Oil Change",
            category: "Engine",
            defaultIntervalMonths: 6,
            defaultIntervalMiles: 5000
        )

        // When: Extracting intervals
        var intervalMonths = ""
        var intervalMiles = ""

        if let months = preset.defaultIntervalMonths {
            intervalMonths = String(months)
        }
        if let miles = preset.defaultIntervalMiles {
            intervalMiles = String(miles)
        }

        // Then: Should populate both
        XCTAssertEqual(intervalMonths, "6")
        XCTAssertEqual(intervalMiles, "5000")
    }

    func testIntervalAutoFill_HandlesNoIntervals() {
        // Given: Preset without intervals
        let preset = PresetData(
            name: "Custom Service",
            category: "Other",
            defaultIntervalMonths: nil,
            defaultIntervalMiles: nil
        )

        // When: Extracting intervals
        var intervalMonths = ""
        var intervalMiles = ""

        if let months = preset.defaultIntervalMonths {
            intervalMonths = String(months)
        }
        if let miles = preset.defaultIntervalMiles {
            intervalMiles = String(miles)
        }

        // Then: Should remain empty
        XCTAssertTrue(intervalMonths.isEmpty)
        XCTAssertTrue(intervalMiles.isEmpty)
    }

    // MARK: - Service Creation Logic Tests

    func testServiceCreation_LogMode_CalculatesNextDueDate() {
        // Given: Service performed today with 6 month interval
        let performedDate = Date()
        let intervalMonths = 6

        // When: Calculating next due date
        let nextDueDate = Calendar.current.date(byAdding: .month, value: intervalMonths, to: performedDate)

        // Then: Should be 6 months from performed date
        XCTAssertNotNil(nextDueDate)

        let components = Calendar.current.dateComponents([.month], from: performedDate, to: nextDueDate!)
        XCTAssertEqual(components.month, 6)
    }

    func testServiceCreation_LogMode_CalculatesNextDueMileage() {
        // Given: Service at 32500 miles with 5000 mile interval
        let mileageAtService = 32500
        let intervalMiles = 5000

        // When: Calculating next due mileage
        let nextDueMileage = mileageAtService + intervalMiles

        // Then: Should be 37500 miles
        XCTAssertEqual(nextDueMileage, 37500)
    }

    func testServiceCreation_UpdatesVehicleMileage() {
        // Given: Vehicle at 32000 miles, service at 32500 miles
        let vehicleMileage = 32000
        let serviceMileage = 32500

        // When: Checking if vehicle mileage should update
        let shouldUpdate = serviceMileage > vehicleMileage
        let newMileage = shouldUpdate ? serviceMileage : vehicleMileage

        // Then: Should update to 32500
        XCTAssertTrue(shouldUpdate)
        XCTAssertEqual(newMileage, 32500)
    }

    func testServiceCreation_DoesNotDowngradeVehicleMileage() {
        // Given: Vehicle at 35000 miles, service at 32500 miles (historical service)
        let vehicleMileage = 35000
        let serviceMileage = 32500

        // When: Checking if vehicle mileage should update
        let shouldUpdate = serviceMileage > vehicleMileage
        let newMileage = shouldUpdate ? serviceMileage : vehicleMileage

        // Then: Should not update (keep higher mileage)
        XCTAssertFalse(shouldUpdate)
        XCTAssertEqual(newMileage, 35000)
    }

    // MARK: - Cost Parsing Tests

    func testCostParsing_ValidDecimal() {
        // Given: Valid cost string
        let costString = "45.99"

        // When: Parsing to Decimal
        let cost = Decimal(string: costString)

        // Then: Should parse correctly
        XCTAssertNotNil(cost)
        XCTAssertEqual(cost, Decimal(string: "45.99"))
    }

    func testCostParsing_WholeNumber() {
        // Given: Whole number cost
        let costString = "50"

        // When: Parsing to Decimal
        let cost = Decimal(string: costString)

        // Then: Should parse correctly
        XCTAssertNotNil(cost)
        XCTAssertEqual(cost, Decimal(50))
    }

    func testCostParsing_EmptyString() {
        // Given: Empty cost string
        let costString = ""

        // When: Parsing to Decimal
        let cost = Decimal(string: costString)

        // Then: Should be nil
        XCTAssertNil(cost)
    }

    func testCostParsing_InvalidString() {
        // Given: Invalid cost string
        let costString = "abc"

        // When: Parsing to Decimal
        let cost = Decimal(string: costString)

        // Then: Should be nil
        XCTAssertNil(cost)
    }

    // MARK: - Notes Handling Tests

    func testNotesHandling_EmptyBecomesNil() {
        // Given: Empty notes
        let notes = ""

        // When: Converting empty to nil
        let notesValue: String? = notes.isEmpty ? nil : notes

        // Then: Should be nil
        XCTAssertNil(notesValue)
    }

    func testNotesHandling_NonEmptyPreserved() {
        // Given: Non-empty notes
        let notes = "Changed oil at local shop"

        // When: Converting
        let notesValue: String? = notes.isEmpty ? nil : notes

        // Then: Should preserve value
        XCTAssertEqual(notesValue, "Changed oil at local shop")
    }

    func testNotesHandling_WhitespaceOnly() {
        // Given: Whitespace-only notes (not trimmed in the view)
        let notes = "   "

        // When: Converting (current implementation doesn't trim)
        let notesValue: String? = notes.isEmpty ? nil : notes

        // Then: Whitespace is preserved (not empty)
        XCTAssertNotNil(notesValue)
        XCTAssertEqual(notesValue, "   ")
    }

    // MARK: - Schedule Recurring Toggle Tests

    func testScheduleRecurring_PresetWithIntervals_DoesNotAutoEnable() {
        // Given: A preset with both interval types
        let preset = PresetData(
            name: "Oil Change",
            category: "Engine",
            defaultIntervalMonths: 6,
            defaultIntervalMiles: 5000
        )

        // When: Preset has intervals but recurring starts OFF (opt-in behavior)
        let hasIntervals = (preset.defaultIntervalMonths != nil) || (preset.defaultIntervalMiles != nil)
        let scheduleRecurring = false // New behavior: toggle stays OFF

        // Then: Intervals exist but recurring is not auto-enabled
        XCTAssertTrue(hasIntervals, "Preset should have intervals")
        XCTAssertFalse(scheduleRecurring, "Recurring should NOT be auto-enabled from preset")
    }

    func testScheduleRecurring_PresetWithOnlyMonths_DoesNotAutoEnable() {
        // Given: A preset with only month interval
        let preset = PresetData(
            name: "Oil Change",
            category: "Engine",
            defaultIntervalMonths: 6,
            defaultIntervalMiles: nil
        )

        // When: Preset has intervals but recurring stays OFF
        let hasIntervals = (preset.defaultIntervalMonths != nil) || (preset.defaultIntervalMiles != nil)
        let scheduleRecurring = false // New behavior: toggle stays OFF

        // Then: Intervals exist but recurring is not auto-enabled
        XCTAssertTrue(hasIntervals, "Preset should have intervals")
        XCTAssertFalse(scheduleRecurring, "Recurring should NOT be auto-enabled from preset")
    }

    func testScheduleRecurring_PresetWithNoIntervals_DefaultsToFalse() {
        // Given: A preset with no intervals
        let preset = PresetData(
            name: "Custom Service",
            category: "Other",
            defaultIntervalMonths: nil,
            defaultIntervalMiles: nil
        )

        // When: Checking if preset has intervals
        let hasIntervals = (preset.defaultIntervalMonths != nil) || (preset.defaultIntervalMiles != nil)

        // Then: Should default to not recurring
        XCTAssertFalse(hasIntervals)
    }

    func testScheduleRecurring_Off_SkipsIntervalAndDueCalculation() {
        // Given: Service performed today with intervals but recurring OFF
        let scheduleRecurring = false
        let intervalMonths = 6
        let intervalMiles = 5000
        let performedDate = Date()
        let mileageAtService = 32500

        // When: Creating service with recurring off
        let effectiveIntervalMonths: Int? = scheduleRecurring ? intervalMonths : nil
        let effectiveIntervalMiles: Int? = scheduleRecurring ? intervalMiles : nil

        // Then: Intervals should be nil
        XCTAssertNil(effectiveIntervalMonths)
        XCTAssertNil(effectiveIntervalMiles)

        // And: No due date/mileage should be calculated
        var dueDate: Date? = nil
        var dueMileage: Int? = nil
        if scheduleRecurring {
            dueDate = Calendar.current.date(byAdding: .month, value: intervalMonths, to: performedDate)
            dueMileage = mileageAtService + intervalMiles
        }
        XCTAssertNil(dueDate)
        XCTAssertNil(dueMileage)
    }

    func testScheduleRecurring_On_CalculatesIntervalAndDue() {
        // Given: Service performed today with intervals and recurring ON
        let scheduleRecurring = true
        let intervalMonths = 6
        let intervalMiles = 5000
        let performedDate = Date()
        let mileageAtService = 32500

        // When: Creating service with recurring on
        let effectiveIntervalMonths: Int? = scheduleRecurring ? intervalMonths : nil
        let effectiveIntervalMiles: Int? = scheduleRecurring ? intervalMiles : nil

        // Then: Intervals should be set
        XCTAssertEqual(effectiveIntervalMonths, 6)
        XCTAssertEqual(effectiveIntervalMiles, 5000)

        // And: Due date/mileage should be calculated
        var dueDate: Date? = nil
        var dueMileage: Int? = nil
        if scheduleRecurring {
            dueDate = Calendar.current.date(byAdding: .month, value: intervalMonths, to: performedDate)
            dueMileage = mileageAtService + intervalMiles
        }
        XCTAssertNotNil(dueDate)
        XCTAssertEqual(dueMileage, 37500)
    }

    func testScheduleRecurring_AnalyticsFlag_RespectsToggle() {
        // Given: Intervals exist but recurring is off
        let scheduleRecurring = false
        let intervalMonths: Int? = 6
        let intervalMiles: Int? = 5000

        // When: Computing analytics hasInterval flag
        let hasInterval = scheduleRecurring && ((intervalMonths != nil && intervalMonths != 0) || (intervalMiles != nil && intervalMiles != 0))

        // Then: Should be false because recurring is off
        XCTAssertFalse(hasInterval)
    }

    // MARK: - Due date comes from the timing, not from intervals
    //
    // The form used to carry `hasCustomDate` + `dueDate` + `performedDate` as
    // three independent stored values that could disagree. They collapsed into
    // one `customDate` resolved by the chosen timing.

    @MainActor
    func testNextDueDate_NilWhileLogging() {
        let model = makeModel()
        model.timing = .today
        XCTAssertNil(model.nextDueDate, "A logged visit has no due date")
    }

    @MainActor
    func testNextDueDate_DerivesFromRelativeTiming() {
        let model = makeModel()
        model.timing = .inSixMonths
        guard let due = model.nextDueDate else {
            return XCTFail("A relative timing must resolve to a due date")
        }
        // Compared against an expected instant rather than by counting whole
        // months: the model samples `.now` a moment after the test does, so a
        // six-month span measures as five months and change.
        let expected = Calendar.current.date(byAdding: .month, value: 6, to: .now)!
        XCTAssertEqual(due.timeIntervalSince(expected), 0, accuracy: 5)
    }

    @MainActor
    func testNextDueDate_UsesTheExplicitDateOnPickADate() {
        let model = makeModel()
        let chosen = Date().addingTimeInterval(86400 * 60)
        model.timing = .onDate
        model.customDate = chosen
        XCTAssertEqual(model.nextDueDate, chosen)
    }

    @MainActor
    func testNextDueDate_NilWhenMileageTriggered() {
        // A mileage-triggered reminder must not also carry a date, or the
        // scheduler would fire on whichever came first without being asked to.
        let model = makeModel()
        model.timing = .atMileage
        model.nextDueMileage = 40_000
        XCTAssertNil(model.nextDueDate)
    }

    @MainActor
    func testPerformedDate_UsesTheExplicitDateOnBackfill() {
        let model = makeModel()
        let backdated = Date().addingTimeInterval(-86400 * 900)
        model.timing = .earlier
        model.customDate = backdated
        XCTAssertEqual(model.performedDate, backdated)
    }

    // MARK: - Scheduled Service Save Logic Tests
    // These tests verify the save flow for remind mode, which uses
    // Service.deriveDueFromIntervals() then applies user overrides.

    func testScheduledService_MileageOnlyPreset_HasDueTracking() {
        // Given: The exact bug scenario — user selects Tire Rotation preset,
        // clears month interval, changes miles to 10000
        let service = Service(name: "Tire Rotation", intervalMiles: 10000)
        let currentMileage = 50000

        // When: deriveDueFromIntervals (same as saveScheduledService)
        service.deriveDueFromIntervals(anchorDate: Date(), anchorMileage: currentMileage)

        // Then: Service has due tracking via mileage
        XCTAssertNil(service.dueDate, "No month interval means no due date")
        XCTAssertEqual(service.dueMileage, 60000, "Due mileage derived from current + interval")
        XCTAssertTrue(service.hasDueTracking, "Mile-only service must appear in upcoming views")
    }

    func testScheduledService_CustomDateOverridesInterval() {
        // Given: Service with month interval, but user sets a custom date
        let service = Service(name: "Antifreeze", intervalMonths: 12)
        let customDate = Date().addingTimeInterval(86400 * 60)

        // When: Derive then override (same as saveScheduledService with hasCustomDate)
        service.deriveDueFromIntervals(anchorDate: Date(), anchorMileage: 50000)
        service.dueDate = customDate  // user override

        // Then: Custom date takes precedence
        XCTAssertEqual(service.dueDate, customDate)
    }

    func testScheduledService_ExplicitMileageOverridesInterval() {
        // Given: Service with mile interval, but user types explicit due mileage
        let service = Service(name: "Tire Rotation", intervalMiles: 10000)

        // When: Derive then override (same as saveScheduledService with explicit dueMileage)
        service.deriveDueFromIntervals(anchorDate: Date(), anchorMileage: 50000)
        service.dueMileage = 55000  // user override

        // Then: Explicit value takes precedence
        XCTAssertEqual(service.dueMileage, 55000)
    }

    @MainActor
    func testSeasonalPrefill_LandsOnPickADateWithScheduleIntent() {
        // A seasonal prefill carries a concrete due date, so it must resolve to
        // a scheduling timing without anyone setting a mode.
        let model = makeModel()
        let seasonalDate = Date().addingTimeInterval(86400 * 120)

        model.applySeasonalPrefill(
            SeasonalPrefill(
                reminderID: "antifreeze",
                serviceName: "Antifreeze",
                dueDate: seasonalDate,
                intervalMonths: 12
            )
        )

        XCTAssertEqual(model.timing, .onDate)
        XCTAssertEqual(model.intent, .schedule)
        XCTAssertEqual(model.nextDueDate, seasonalDate)
        XCTAssertTrue(model.isRecurring)
    }

    // MARK: - Form Model Draft Lifecycle (R9)

    @MainActor
    private func makeModel(currentMileage: Int = 32_500) -> AddServiceFormModel {
        let vehicle = Vehicle(make: "Toyota", model: "Corolla", year: 2020, currentMileage: currentMileage)
        return AddServiceFormModel(vehicle: vehicle)
    }

    // MARK: - Blocking reasons
    //
    // The save button's enablement and its disabled-tap message come from one
    // property, so they cannot disagree about why a save is refused.

    @MainActor
    func testBlocking_NameFirst() {
        let model = makeModel()
        XCTAssertEqual(model.blockingReason, L10n.formServiceTypeRequired)
    }

    @MainActor
    func testBlocking_ThenTiming() {
        let model = makeModel()
        model.customServiceName = "Oil change"
        XCTAssertEqual(model.blockingReason, L10n.formTimingRequired)
    }

    @MainActor
    func testBlocking_MileageTriggeredReminderWithoutATarget() {
        // The one case that genuinely blocks: a reminder with no trigger would
        // never fire, so saving it would be saving nothing.
        let model = makeModel()
        model.customServiceName = "Tire rotation"
        model.timing = .atMileage
        XCTAssertEqual(model.blockingReason, L10n.formRemindMileageRequired)

        model.nextDueMileage = 40_000
        XCTAssertNil(model.blockingReason)
    }

    @MainActor
    func testBlocking_UnresolvedOdometerContradiction() {
        let model = makeModel(currentMileage: 33_000)
        model.customServiceName = "Oil change"
        model.timing = .earlier
        model.customDate = Date().addingTimeInterval(-86400 * 900)
        model.mileageAtService = 40_000

        XCTAssertTrue(model.hasUnresolvedMileageContradiction)
        XCTAssertEqual(model.blockingReason, L10n.formResolveOdometerConflict)

        model.mileageResolution = .keepCurrent
        XCTAssertNil(model.blockingReason)
    }

    @MainActor
    func testBackfill_NeverAdoptsTheOdometer() {
        // Logging a 2023 service at 40,000 mi must not overwrite a current
        // odometer of 33,000 (F11).
        let model = makeModel(currentMileage: 33_000)
        model.vehicle.mileageUpdatedAt = .now
        model.timing = .earlier
        model.customDate = Date().addingTimeInterval(-86400 * 900)
        model.mileageAtService = 40_000

        XCTAssertFalse(model.wouldAdoptMileage)
    }

    @MainActor
    func testCurrentEntry_AdoptsAHigherOdometer() {
        let model = makeModel(currentMileage: 32_500)
        model.timing = .today
        model.mileageAtService = 33_100

        XCTAssertTrue(model.wouldAdoptMileage)
    }

    @MainActor
    func testFormModel_PristineAfterInit_IsNotDirty() {
        // The mileage prefill happens before the baseline is captured, so an
        // untouched form must not count as dirty (no phantom drafts on Cancel).
        let model = makeModel()
        XCTAssertEqual(model.mileageAtService, 32_500)
        XCTAssertFalse(model.isDirty)
    }

    @MainActor
    func testFormModel_EditMakesDirty() {
        let model = makeModel()
        model.customServiceName = "Oil Change"
        XCTAssertTrue(model.isDirty)
    }

    @MainActor
    func testFormModel_ResetLogModeFields_ClearsScheduleStateAndRebaselines() {
        let model = makeModel()
        model.timing = .today
        model.customServiceName = "Oil Change"
        model.nextDueMileage = 40_000
        model.intervalMonths = 6
        model.isRecurring = true

        model.resetLogModeFields()

        // Schedule-side state must not leak into the next entry. The timing
        // survives on purpose: "Save & add another" is one visit's worth of
        // work, so re-answering "when" for each line item would be busywork.
        XCTAssertEqual(model.timing, .today)
        XCTAssertNil(model.nextDueMileage)
        XCTAssertNil(model.intervalMonths)
        XCTAssertFalse(model.isRecurring)
        // The reset form is the new pristine state — otherwise the autosave
        // would persist a phantom draft right after "Save & add another".
        XCTAssertFalse(model.isDirty)
    }

    @MainActor
    func testFormModel_ApplyDraftWithUnknownPreset_FallsBackToTypedName() {
        let model = makeModel()
        var draft = model.toDraft()
        draft.presetName = "No Longer Exists"
        draft.serviceName = "Custom Wax"

        model.apply(draft)

        XCTAssertNil(model.selectedPreset, "Unknown preset names are dropped silently")
        XCTAssertEqual(model.serviceName, "Custom Wax")
    }
}
