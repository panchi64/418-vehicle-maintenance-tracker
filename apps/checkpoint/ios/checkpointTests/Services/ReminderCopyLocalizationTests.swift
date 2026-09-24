//
//  ReminderCopyLocalizationTests.swift
//  checkpointTests
//
//  Mileage, marbete, and yearly roundup notifications were English-only
//  literals. Every key they now read must resolve in both English and Spanish
//  — a missing entry would put the raw key on the lock screen.
//

import XCTest
@testable import checkpoint

final class ReminderCopyLocalizationTests: XCTestCase {

    private let keys = [
        "notification.mileage.title",
        "notification.mileage.body",
        "notification.marbete.title.days",
        "notification.marbete.title.urgent",
        "notification.marbete.title.final",
        "notification.marbete.body.60",
        "notification.marbete.body.30",
        "notification.marbete.body.7",
        "notification.marbete.body.1",
        "notification.marbete.body.final",
        "notification.marbete.body.generic",
        "notification.roundup.title",
        "notification.roundup.body",
        "notification.action.markDone",
        "notification.action.remindTomorrow",
        "notification.action.updateNow",
        "notification.action.viewCosts"
    ]

    private func bundle(for language: String) throws -> Bundle {
        let path = try XCTUnwrap(
            Bundle(for: NotificationService.self).path(forResource: language, ofType: "lproj"),
            "\(language).lproj missing from the app bundle"
        )
        return try XCTUnwrap(Bundle(path: path))
    }

    func testEveryReminderKeyResolvesInEnglishAndSpanish() throws {
        let english = try bundle(for: "en")
        let spanish = try bundle(for: "es")

        for key in keys {
            let en = english.localizedString(forKey: key, value: nil, table: nil)
            let es = spanish.localizedString(forKey: key, value: nil, table: nil)
            XCTAssertNotEqual(en, key, "\(key) has no English value")
            XCTAssertNotEqual(es, key, "\(key) has no Spanish value")
            XCTAssertNotEqual(en, es, "\(key) looks untranslated in Spanish")
        }
    }

    @MainActor
    func testEnglishCopyIsUnchanged() {
        let mileage = MileageReminderScheduler.buildMileageReminderRequest(
            vehicleName: "My Car", vehicleID: UUID(), reminderDate: .now
        )
        XCTAssertEqual(mileage.content.title, "Odometer Sync Requested")
        XCTAssertEqual(mileage.content.body, "My Car here. It's been 14 days. How far have we gone?")

        let marbete = MarbeteNotificationScheduler.buildMarbeteNotificationRequest(
            vehicleName: "My Car", vehicleID: UUID(), notificationDate: .now, daysBeforeDue: 30
        )
        XCTAssertEqual(marbete.content.title, "Marbete Status: 30 Days")
        XCTAssertEqual(marbete.content.body, "My Car would prefer not to be impounded.")
    }
}
