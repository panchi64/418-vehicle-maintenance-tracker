//
//  MarkServiceDoneIntent.swift
//  CheckpointWidget
//
//  AppIntent for the interactive widget "Done" button
//  Writes a pending completion to App Group UserDefaults for the main app to process
//

import AppIntents
import WidgetKit
import Foundation

struct MarkServiceDoneIntent: AppIntent {
    static var title: LocalizedStringResource = "Mark Service Done"
    static var description = IntentDescription("Mark a vehicle service as completed from the widget")

    @Parameter(title: "Service ID")
    var serviceID: String

    @Parameter(title: "Vehicle ID")
    var vehicleID: String

    @Parameter(title: "Mileage")
    var mileage: Int

    init() {
        self.serviceID = ""
        self.vehicleID = ""
        self.mileage = 0
    }

    init(serviceID: String, vehicleID: String, mileage: Int) {
        self.serviceID = serviceID
        self.vehicleID = vehicleID
        self.mileage = mileage
    }

    func perform() async throws -> some IntentResult {
        // Read fresh mileage from App Group at execution time instead of using
        // the stale cached value from the timeline entry
        let freshMileage = Self.readFreshMileage(vehicleID: vehicleID) ?? mileage

        let completion = PendingWidgetCompletion(
            serviceID: serviceID,
            vehicleID: vehicleID,
            performedDate: Date(),
            mileageAtService: freshMileage
        )

        PendingWidgetCompletion.save(completion)

        WidgetCenter.shared.reloadAllTimelines()

        return .result()
    }

    /// Read current mileage from shared UserDefaults at intent execution time
    private static func readFreshMileage(vehicleID: String) -> Int? {
        let appGroupID = "group.com.418-studio.checkpoint.shared"
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return nil }

        // Try vehicle-specific key first, then generic key
        let keys = ["widgetData_\(vehicleID)", "widgetData"]
        for key in keys {
            if let data = defaults.data(forKey: key),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let mileage = json["currentMileage"] as? Int {
                return mileage
            }
        }
        return nil
    }
}
