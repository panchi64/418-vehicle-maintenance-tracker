//
//  AnalyticsEventTests.swift
//  checkpointTests
//
//  Tests for analytics event taxonomy: names, properties, and no PII
//

import XCTest
@testable import checkpoint

final class AnalyticsEventTests: XCTestCase {

    // MARK: - Event Names

    func test_appLifecycleEventNames() {
        XCTAssertEqual(AnalyticsEvent.appOpened.name, "app_opened")
        XCTAssertEqual(AnalyticsEvent.appBackgrounded.name, "app_backgrounded")
        XCTAssertEqual(AnalyticsEvent.appSessionStart(vehicleCount: 0, serviceCount: 0).name, "app_session_start")
    }

    func test_navigationEventNames() {
        XCTAssertEqual(AnalyticsEvent.tabSwitched(tab: .home).name, "tab_switched")
        XCTAssertEqual(AnalyticsEvent.vehicleSwitched.name, "vehicle_switched")
        XCTAssertEqual(AnalyticsEvent.settingsOpened.name, "settings_opened")
    }

    func test_screenViewEventName() {
        XCTAssertEqual(AnalyticsEvent.screenViewed(screen: .home).name, "$screen")
        XCTAssertEqual(AnalyticsEvent.screenViewed(screen: .costs).name, "$screen")
    }

    func test_vehicleEventNames() {
        XCTAssertEqual(AnalyticsEvent.vehicleAdded(usedOCR: false, usedVINLookup: false, hasNickname: false).name, "vehicle_added")
        XCTAssertEqual(AnalyticsEvent.vehicleEdited.name, "vehicle_edited")
        XCTAssertEqual(AnalyticsEvent.vehicleDeleted.name, "vehicle_deleted")
    }

    func test_serviceEventNames() {
        XCTAssertEqual(AnalyticsEvent.serviceScheduled(isPreset: true, category: nil, hasInterval: true).name, "service_scheduled")
        XCTAssertEqual(AnalyticsEvent.serviceLogged(isPreset: false, category: nil, hasInterval: false).name, "service_logged")
        XCTAssertEqual(AnalyticsEvent.serviceMarkedDone(hasCost: true, hasNotes: false, hasAttachments: false, attachmentCount: 0).name, "service_marked_done")
        XCTAssertEqual(AnalyticsEvent.serviceEdited.name, "service_edited")
        XCTAssertEqual(AnalyticsEvent.serviceDeleted.name, "service_deleted")
    }

    func test_mileageEventNames() {
        XCTAssertEqual(AnalyticsEvent.mileageUpdated(source: .manual).name, "mileage_updated")
        XCTAssertEqual(AnalyticsEvent.mileagePromptShown.name, "mileage_prompt_shown")
    }

    func test_ocrEventNames() {
        XCTAssertEqual(AnalyticsEvent.ocrAttempted(ocrType: .odometer).name, "ocr_attempted")
        XCTAssertEqual(AnalyticsEvent.ocrSucceeded(ocrType: .vin).name, "ocr_succeeded")
        XCTAssertEqual(AnalyticsEvent.ocrFailed(ocrType: .odometer).name, "ocr_failed")
    }

    // MARK: - Event Properties

    func test_appSessionStartProperties() {
        let event = AnalyticsEvent.appSessionStart(vehicleCount: 3, serviceCount: 12)
        let props = event.properties
        XCTAssertEqual(props["vehicle_count"] as? Int, 3)
        XCTAssertEqual(props["service_count"] as? Int, 12)
    }

    func test_tabSwitchedProperties() {
        let event = AnalyticsEvent.tabSwitched(tab: .services)
        XCTAssertEqual(event.properties["tab"] as? String, "services")
    }

    func test_screenViewedProperties() {
        let event = AnalyticsEvent.screenViewed(screen: .addService)
        XCTAssertEqual(event.properties["$screen_name"] as? String, "add_service")
    }

    func test_vehicleAddedProperties() {
        let event = AnalyticsEvent.vehicleAdded(usedOCR: true, usedVINLookup: false, hasNickname: true)
        let props = event.properties
        XCTAssertEqual(props["used_ocr"] as? Bool, true)
        XCTAssertEqual(props["used_vin_lookup"] as? Bool, false)
        XCTAssertEqual(props["has_nickname"] as? Bool, true)
    }

    func test_serviceScheduledProperties_withCategory() {
        let event = AnalyticsEvent.serviceScheduled(isPreset: true, category: "maintenance", hasInterval: true)
        let props = event.properties
        XCTAssertEqual(props["is_preset"] as? Bool, true)
        XCTAssertEqual(props["category"] as? String, "maintenance")
        XCTAssertEqual(props["has_interval"] as? Bool, true)
    }

    func test_serviceScheduledProperties_noCategory() {
        let event = AnalyticsEvent.serviceScheduled(isPreset: false, category: nil, hasInterval: false)
        let props = event.properties
        XCTAssertNil(props["category"], "Category should be nil when not provided")
    }

    func test_serviceMarkedDoneProperties() {
        let event = AnalyticsEvent.serviceMarkedDone(hasCost: true, hasNotes: true, hasAttachments: true, attachmentCount: 3)
        let props = event.properties
        XCTAssertEqual(props["has_cost"] as? Bool, true)
        XCTAssertEqual(props["has_notes"] as? Bool, true)
        XCTAssertEqual(props["has_attachments"] as? Bool, true)
        XCTAssertEqual(props["attachment_count"] as? Int, 3)
    }

    func test_mileageUpdatedProperties() {
        XCTAssertEqual(AnalyticsEvent.mileageUpdated(source: .manual).properties["source"] as? String, "manual")
        XCTAssertEqual(AnalyticsEvent.mileageUpdated(source: .ocr).properties["source"] as? String, "ocr")
        XCTAssertEqual(AnalyticsEvent.mileageUpdated(source: .quickUpdate).properties["source"] as? String, "quick_update")
    }

    func test_ocrProperties() {
        XCTAssertEqual(AnalyticsEvent.ocrAttempted(ocrType: .odometer).properties["ocr_type"] as? String, "odometer")
        XCTAssertEqual(AnalyticsEvent.ocrSucceeded(ocrType: .vin).properties["ocr_type"] as? String, "vin")
    }

    // MARK: - No PII

    func test_vehicleSwitchedHasNoProperties() {
        let props = AnalyticsEvent.vehicleSwitched.properties
        XCTAssertTrue(props.isEmpty, "vehicle_switched should have no properties to avoid PII leakage")
    }

    func test_vehicleEditedHasNoProperties() {
        let props = AnalyticsEvent.vehicleEdited.properties
        XCTAssertTrue(props.isEmpty, "vehicle_edited should have no properties to avoid PII leakage")
    }

    func test_vehicleDeletedHasNoProperties() {
        let props = AnalyticsEvent.vehicleDeleted.properties
        XCTAssertTrue(props.isEmpty, "vehicle_deleted should have no properties to avoid PII leakage")
    }

    func test_noPropertyContainsPII() {
        // Verify that vehicle-related events don't leak PII (actual names, VINs, make/model values)
        let vehicleAddedProps = AnalyticsEvent.vehicleAdded(usedOCR: true, usedVINLookup: true, hasNickname: true).properties
        let piiKeys = ["vehicle_name", "vin_number", "vin_value", "make", "model", "nickname"]
        for (key, _) in vehicleAddedProps {
            XCTAssertFalse(piiKeys.contains(key), "Property key '\(key)' looks like PII")
            // Values should be booleans, not strings that could be PII
            XCTAssertTrue(vehicleAddedProps[key] is Bool, "Property '\(key)' should be boolean, not a string that could contain PII")
        }
    }

    // MARK: - Screen Names

    func test_allScreenNamesAreSnakeCase() {
        let screens: [AnalyticsEvent.ScreenName] = [
            .home, .services, .costs, .settings,
            .addVehicleBasics, .addVehicleDetails, .addService,
            .serviceDetail, .editService, .markServiceDone,
            .editVehicle, .vehiclePicker, .mileageUpdate, .serviceLogDetail
        ]

        for screen in screens {
            XCTAssertFalse(screen.rawValue.contains(" "), "Screen name '\(screen.rawValue)' should not contain spaces")
            XCTAssertEqual(screen.rawValue, screen.rawValue.lowercased(), "Screen name '\(screen.rawValue)' should be lowercase")
        }
    }

    // MARK: - Events with Empty Properties

    func test_eventsWithNoProperties_returnEmptyDict() {
        let noPropertyEvents: [AnalyticsEvent] = [
            .appOpened,
            .appBackgrounded,
            .vehicleSwitched,
            .settingsOpened,
            .vehicleEdited,
            .vehicleDeleted,
            .serviceEdited,
            .serviceDeleted,
            .mileagePromptShown,
            .servicesSearchUsed,
            .serviceHistoryExported,
            .analyticsOptedOut,
            .analyticsOptedIn,
            .serviceClusterTapped,
            .serviceClusterMarkAllDone,
            .notificationPermissionGranted,
            .notificationPermissionDenied,
        ]

        for event in noPropertyEvents {
            XCTAssertTrue(event.properties.isEmpty,
                          "Event '\(event.name)' should have no properties but has: \(event.properties)")
        }
    }
}
