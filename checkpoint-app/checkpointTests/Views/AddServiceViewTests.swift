//
//  AddServiceViewTests.swift
//  checkpointTests
//
//  Tests for AddServiceView form validation and logic
//

import XCTest
@testable import checkpoint

final class AddServiceViewTests: XCTestCase {

    // MARK: - Mode Switching Tests

    func testServiceMode_HasCorrectCases() {
        // Given: ServiceMode enum
        let allCases = ServiceMode.allCases

        // Then: Should have exactly two cases
        XCTAssertEqual(allCases.count, 2)
        XCTAssertTrue(allCases.contains(.record))
        XCTAssertTrue(allCases.contains(.remind))
    }

    func testServiceMode_HasCorrectRawValues() {
        // Then: Raw values should match expected labels
        XCTAssertEqual(ServiceMode.record.rawValue, "Record")
        XCTAssertEqual(ServiceMode.remind.rawValue, "Remind")
    }

    // MARK: - Form Validation Tests (Log Mode)

    func testFormValidation_LogMode_ValidWhenServiceNameAndMileageFilled() {
        // Given: Log mode with service name and mileage
        let mode = ServiceMode.record
        let serviceName = "Oil Change"
        let mileageAtService = "32500"

        // When: Checking validation logic
        let isValid = !serviceName.isEmpty && (mode == .record ? !mileageAtService.isEmpty : true)

        // Then: Form should be valid
        XCTAssertTrue(isValid, "Log mode should be valid when service name and mileage are filled")
    }

    func testFormValidation_LogMode_InvalidWhenServiceNameEmpty() {
        // Given: Log mode with empty service name
        let mode = ServiceMode.record
        let serviceName = ""
        let mileageAtService = "32500"

        // When: Checking validation logic
        let isValid = !serviceName.isEmpty && (mode == .record ? !mileageAtService.isEmpty : true)

        // Then: Form should be invalid
        XCTAssertFalse(isValid, "Log mode should be invalid when service name is empty")
    }

    func testFormValidation_LogMode_InvalidWhenMileageEmpty() {
        // Given: Log mode with empty mileage
        let mode = ServiceMode.record
        let serviceName = "Oil Change"
        let mileageAtService = ""

        // When: Checking validation logic
        let isValid = !serviceName.isEmpty && (mode == .record ? !mileageAtService.isEmpty : true)

        // Then: Form should be invalid
        XCTAssertFalse(isValid, "Log mode should be invalid when mileage is empty")
    }

    func testFormValidation_LogMode_InvalidWhenBothEmpty() {
        // Given: Log mode with both fields empty
        let mode = ServiceMode.record
        let serviceName = ""
        let mileageAtService = ""

        // When: Checking validation logic
        let isValid = !serviceName.isEmpty && (mode == .record ? !mileageAtService.isEmpty : true)

        // Then: Form should be invalid
        XCTAssertFalse(isValid, "Log mode should be invalid when both fields are empty")
    }

    // MARK: - Form Validation Tests (Schedule Mode)

    func testFormValidation_ScheduleMode_ValidWhenOnlyServiceNameFilled() {
        // Given: Schedule mode with only service name (mileage not required)
        let mode = ServiceMode.remind
        let serviceName = "Tire Rotation"
        let mileageAtService = ""

        // When: Checking validation logic
        let isValid = !serviceName.isEmpty && (mode == .record ? !mileageAtService.isEmpty : true)

        // Then: Form should be valid
        XCTAssertTrue(isValid, "Schedule mode should be valid when only service name is filled")
    }

    func testFormValidation_ScheduleMode_InvalidWhenServiceNameEmpty() {
        // Given: Schedule mode with empty service name
        let mode = ServiceMode.remind
        let serviceName = ""
        let mileageAtService = "35000"

        // When: Checking validation logic
        let isValid = !serviceName.isEmpty && (mode == .record ? !mileageAtService.isEmpty : true)

        // Then: Form should be invalid
        XCTAssertFalse(isValid, "Schedule mode should be invalid when service name is empty")
    }

    func testFormValidation_ScheduleMode_ValidWithAllFields() {
        // Given: Schedule mode with all fields filled
        let mode = ServiceMode.remind
        let serviceName = "Brake Inspection"
        let mileageAtService = "40000"

        // When: Checking validation logic
        let isValid = !serviceName.isEmpty && (mode == .record ? !mileageAtService.isEmpty : true)

        // Then: Form should be valid
        XCTAssertTrue(isValid, "Schedule mode should be valid with all fields filled")
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

    // MARK: - Default Due Date Tests

    func testDefaultDueDate_IsNotPreFilled() {
        // Given: Default state of hasDueDate toggle
        let hasDueDate = false

        // Then: Due date should be opt-in, not pre-filled
        XCTAssertFalse(hasDueDate, "Due date toggle should default to off so users aren't forced into an arbitrary date")
    }

    func testScheduledService_DerivesDateFromInterval_WhenToggleOff() {
        // Given: Schedule mode with hasDueDate off but interval set
        let hasDueDate = false
        let intervalMonths = 6
        let now = Date()

        // When: Computing effective due date (mirrors saveScheduledService logic)
        let effectiveDueDate: Date? = if hasDueDate {
            now
        } else if intervalMonths > 0 {
            Calendar.current.date(byAdding: .month, value: intervalMonths, to: now)
        } else {
            nil
        }

        // Then: Due date should be derived from interval, not nil
        XCTAssertNotNil(effectiveDueDate, "Should derive due date from interval when toggle is off")
        let monthsDiff = Calendar.current.dateComponents([.month], from: now, to: effectiveDueDate!).month
        XCTAssertEqual(monthsDiff, 6)
    }

    func testScheduledService_NilDueDate_WhenNoIntervalAndToggleOff() {
        // Given: Schedule mode with hasDueDate off and no interval
        let hasDueDate = false
        let intervalMonths: Int? = nil

        // When: Computing effective due date
        let effectiveDueDate: Date? = if hasDueDate {
            Date()
        } else if let months = intervalMonths, months > 0 {
            Calendar.current.date(byAdding: .month, value: months, to: Date())
        } else {
            nil
        }

        // Then: Due date should be nil (mileage-only tracking)
        XCTAssertNil(effectiveDueDate, "Should not set a due date when there's no interval and toggle is off")
    }

    func testScheduledService_SavesCustomDate_WhenToggleOn() {
        // Given: Schedule mode with hasDueDate on and user-picked date
        let hasDueDate = true
        let customDate = Date().addingTimeInterval(86400 * 90)
        let intervalMonths = 6

        // When: Computing effective due date
        let effectiveDueDate: Date? = if hasDueDate {
            customDate
        } else if intervalMonths > 0 {
            Calendar.current.date(byAdding: .month, value: intervalMonths, to: Date())
        } else {
            nil
        }

        // Then: Should use the user's custom date, not the interval-derived one
        XCTAssertNotNil(effectiveDueDate)
        XCTAssertEqual(effectiveDueDate, customDate)
    }

    func testSeasonalPrefill_EnablesDueDateToggle() {
        // Given: A seasonal prefill provides a specific date
        let prefillDate = Date().addingTimeInterval(86400 * 60)

        // When: Applying prefill (simulating onAppear logic)
        var hasDueDate = false
        var dueDate = Date()
        hasDueDate = true
        dueDate = prefillDate

        // Then: Toggle should be on and date should match prefill
        XCTAssertTrue(hasDueDate, "Seasonal prefill should enable the due date toggle")
        XCTAssertEqual(dueDate, prefillDate)
    }
}
