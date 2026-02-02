//
//  CheckNextDueIntent.swift
//  checkpoint
//
//  Siri intent for checking the next due service on a vehicle
//  "Hey Siri, what's due on my car in Checkpoint?"
//

import AppIntents

/// Intent to check the next due service on a vehicle
struct CheckNextDueIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Next Due Service"
    static var description = IntentDescription("Check what maintenance is due next on your vehicle")

    @Parameter(
        title: "Vehicle",
        description: "The vehicle to check",
        requestValueDialog: "Which vehicle would you like to check?"
    )
    var vehicle: VehicleEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Check next due service on \(\.$vehicle)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let data = SiriDataProvider.loadServiceData(for: vehicle?.id)

        guard let serviceData = data else {
            return .result(dialog: "I couldn't find any vehicle data. Please open Checkpoint to set up your vehicles.")
        }

        guard let nextService = serviceData.services.first else {
            return .result(dialog: "No services are scheduled for \(serviceData.vehicleName).")
        }

        let dialog = formatServiceDialog(
            service: nextService,
            vehicleName: serviceData.vehicleName
        )

        return .result(dialog: IntentDialog(stringLiteral: dialog))
    }

    private func formatServiceDialog(service: SiriService, vehicleName: String) -> String {
        let statusText: String
        let detailText: String

        switch service.status {
        case .overdue:
            statusText = "is overdue"
            detailText = service.dueDescription
        case .dueSoon:
            if let days = service.daysRemaining, days > 0 {
                if days == 1 {
                    detailText = "due tomorrow"
                } else {
                    detailText = "due in \(days) days"
                }
            } else {
                detailText = service.dueDescription.lowercased()
            }
            statusText = "is due soon"
        case .good:
            if let days = service.daysRemaining, days > 0 {
                detailText = "\(days) days remaining"
            } else {
                detailText = service.dueDescription.lowercased()
            }
            statusText = "is coming up"
        case .neutral:
            statusText = "is scheduled"
            detailText = service.dueDescription.lowercased()
        }

        // Format: "Oil change on Daily Driver is due soon. 5 days remaining."
        return "\(service.name) on \(vehicleName) \(statusText). \(detailText.capitalized)."
    }
}
