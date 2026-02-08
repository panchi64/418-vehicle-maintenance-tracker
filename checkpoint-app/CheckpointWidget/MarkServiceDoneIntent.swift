//
//  MarkServiceDoneIntent.swift
//  CheckpointWidget
//
//  AppIntent for the interactive widget "Done" button
//  Writes a pending completion to App Group UserDefaults for the main app to process
//

import AppIntents
import WidgetKit

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
        let completion = PendingWidgetCompletion(
            serviceID: serviceID,
            vehicleID: vehicleID,
            performedDate: Date(),
            mileageAtService: mileage
        )

        PendingWidgetCompletion.save(completion)

        WidgetCenter.shared.reloadAllTimelines()

        return .result()
    }
}
