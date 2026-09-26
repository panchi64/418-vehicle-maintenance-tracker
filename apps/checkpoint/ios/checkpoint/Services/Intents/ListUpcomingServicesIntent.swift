//
//  ListUpcomingServicesIntent.swift
//  checkpoint
//
//  Siri intent for listing upcoming services on a vehicle
//  "Hey Siri, what maintenance is coming up in Checkpoint?"
//

import AppIntents

/// Intent to list upcoming services on a vehicle
struct ListUpcomingServicesIntent: AppIntent {
    static var title: LocalizedStringResource = "List Upcoming Services"
    static var description = IntentDescription("List the next few maintenance services due on your vehicle")

    @Parameter(
        title: "Vehicle",
        description: "The vehicle to check",
        requestValueDialog: "Which vehicle would you like to check?"
    )
    var vehicle: VehicleEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("List upcoming services on \(\.$vehicle)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let data = SiriDataProvider.loadServiceData(for: vehicle?.id)

        guard let serviceData = data else {
            return .result(dialog: "I couldn't find any vehicle data. Please open Checkpoint to set up your vehicles.")
        }

        guard !serviceData.services.isEmpty else {
            return .result(dialog: "No services are scheduled for \(serviceData.vehicleName).")
        }

        let dialog = formatServicesDialog(
            services: serviceData.services,
            vehicleName: serviceData.vehicleName
        )

        return .result(dialog: IntentDialog(stringLiteral: dialog))
    }

    private func formatServicesDialog(services: [SiriService], vehicleName: String) -> String {
        // Take up to 3 services
        let topServices = Array(services.prefix(3))

        if topServices.count == 1 {
            return formatSingleService(topServices[0], vehicleName: vehicleName)
        }

        // Build a natural-sounding list
        var parts: [String] = []
        for service in topServices {
            parts.append(formatServiceItem(service))
        }

        return L10n.siriListIntro(vehicle: vehicleName, list: parts.joined(separator: ". "))
    }

    private func formatSingleService(_ service: SiriService, vehicleName: String) -> String {
        L10n.siriSingle(
            service.status,
            vehicle: vehicleName,
            service: service.name,
            due: service.dueDescription
        )
    }

    private func formatServiceItem(_ service: SiriService) -> String {
        // dueDescription already reads as an abstracted period ("Due mid May")
        // for date-based items, or miles remaining for mileage-tracked services.
        if service.status == .overdue {
            return L10n.siriListItemOverdue(service.name)
        }
        return L10n.siriListItem(service.name, due: service.dueDescription.lowercased())
    }
}
